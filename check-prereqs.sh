#!/usr/bin/env bash
# check-prereqs.sh — run this with `oc` logged in AS YOURSELF, BEFORE you create a
# "Mobile Dev" workspace. It verifies your cluster + namespace can host your own
# on-cluster Android device, so you don't discover problems only after the
# workspace (and its device) fail to come up.
#
#   oc login <api-url>            # log in as you (e.g. user1)
#   ./check-prereqs.sh            # checks <you>-devspaces
#   ./check-prereqs.sh my-ns      # or a specific namespace
set -uo pipefail

PASS=0; FAIL=0; WARN=0
ok(){   printf '  \033[32m✓\033[0m %s\n' "$*"; PASS=$((PASS+1)); }
no(){   printf '  \033[31m✗\033[0m %s\n' "$*"; FAIL=$((FAIL+1)); }
warn(){ printf '  \033[33m!\033[0m %s\n' "$*"; WARN=$((WARN+1)); }

command -v oc >/dev/null 2>&1 || { echo "✗ 'oc' not found — install the OpenShift CLI first."; exit 1; }
oc whoami >/dev/null 2>&1 || { echo "✗ Not logged in. Run:  oc login <api-url>"; exit 1; }
ME=$(oc whoami)
NS="${1:-${ME}-devspaces}"
PLAT="${PLATFORM_NS:-devspace-android-demo}"
printf 'Checking readiness as \033[1m%s\033[0m for namespace \033[1m%s\033[0m\n\n' "$ME" "$NS"

# --- the cluster has the bits the device needs ---
oc get crd virtualmachines.kubevirt.io >/dev/null 2>&1 \
  && ok "OpenShift Virtualization (KubeVirt) installed" \
  || no "OpenShift Virtualization NOT installed — the Android device is a KubeVirt VM (ask your cluster admin)"
oc get crd datavolumes.cdi.kubevirt.io >/dev/null 2>&1 \
  && ok "CDI (DataVolumes) installed" \
  || no "CDI NOT installed — needed to import the device disk"
if oc get storageclass -o jsonpath='{range .items[*]}{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}{"\n"}{end}' 2>/dev/null | grep -q true; then
  ok "a default StorageClass exists (device disk can bind)"
else warn "no default StorageClass — the device disk may stay Pending"; fi

# --- YOU can create the resources your workspace will provision (the RBAC check) ---
can(){ [ "$(oc auth can-i "$1" "$2" -n "$NS" 2>/dev/null)" = yes ]; }
GAP=0
for spec in \
  "create:virtualmachines.kubevirt.io:create VMs (your device)" \
  "create:datavolumes.cdi.kubevirt.io:create DataVolumes (device disk)" \
  "create:services:create Services (adb)" \
  "create:deployments.apps:create Deployments (the screen)" \
  "create:routes.route.openshift.io:create Routes (the screen URL)"; do
  IFS=: read -r verb res label <<<"$spec"
  if can "$verb" "$res"; then ok "you can $label"; else no "you CANNOT $label"; GAP=1; fi
done
[ "$GAP" = 1 ] && warn "→ fix: Dev Spaces should grant you the built-in 'edit' role in your namespace automatically. Ask your admin to check the CheCluster has devEnvironments.user.clusterRoles: [\"edit\"] (set by the platform repo's preflight.sh prepare), then restart your workspace."

# --- the platform images exist (your workspace + screen pull from here) ---
oc get istag mobile-allinone:latest -n "$PLAT" >/dev/null 2>&1 \
  && ok "workspace image present ($PLAT/mobile-allinone)" \
  || warn "workspace image not found in $PLAT — admin must build it (openshift/build-and-deploy.sh)"
oc get istag ws-scrcpy:latest -n "$PLAT" >/dev/null 2>&1 \
  && ok "device-screen image present ($PLAT/ws-scrcpy)" \
  || warn "ws-scrcpy image not found in $PLAT — admin must build it"

# --- resource headroom: can your namespace actually FIT these heavy components? ---
# Rough asks: workspace ~12Gi/6cpu + device VM ~7Gi/4cpu + screen ~1Gi/1cpu ≈ 20Gi / 11 cpu.
REQ_MEM_GI=20
to_gi(){ local v="${1:-0}"; case "$v" in
  *Gi) echo "${v%Gi}";; *Mi) echo $(( ${v%Mi} / 1024 ));;
  *Ti) echo $(( ${v%Ti} * 1024 ));; *G) echo "${v%G}";;
  *M)  echo $(( ${v%M} / 1000 ));; *) echo 0;; esac; }

RQ=$(oc get resourcequota -n "$NS" -o name 2>/dev/null | head -1)
if [ -n "$RQ" ]; then
  hmem=$(oc get "$RQ" -n "$NS" -o jsonpath='{.status.hard.limits\.memory}' 2>/dev/null)
  hmem=${hmem:-$(oc get "$RQ" -n "$NS" -o jsonpath='{.status.hard.requests\.memory}' 2>/dev/null)}
  umem=$(oc get "$RQ" -n "$NS" -o jsonpath='{.status.used.limits\.memory}' 2>/dev/null)
  umem=${umem:-$(oc get "$RQ" -n "$NS" -o jsonpath='{.status.used.requests\.memory}' 2>/dev/null)}
  if [ -n "$hmem" ]; then
    rem=$(( $(to_gi "$hmem") - $(to_gi "$umem") ))
    if [ "$rem" -ge "$REQ_MEM_GI" ]; then ok "namespace memory quota: ~${rem}Gi free (workspace+device+screen need ~${REQ_MEM_GI}Gi)"
    else no "namespace memory quota too small: ~${rem}Gi free, need ~${REQ_MEM_GI}Gi — ask your admin to raise the ResourceQuota"; fi
  else ok "ResourceQuota present but no memory cap"; fi
else
  ok "no ResourceQuota on your namespace (watch overall cluster capacity instead)"
fi

# per-pod cap: the workspace container alone requests 12Gi
LRMAX=$(oc get limitrange -n "$NS" -o jsonpath='{.items[0].spec.limits[?(@.type=="Container")].max.memory}' 2>/dev/null)
if [ -n "$LRMAX" ]; then
  if [ "$(to_gi "$LRMAX")" -ge 12 ]; then ok "per-container LimitRange allows the 12Gi workspace (max ${LRMAX})"
  else no "a LimitRange caps containers at ${LRMAX} — below the 12Gi the workspace needs (ask your admin)"; fi
fi

echo
if [ "$FAIL" -eq 0 ]; then
  printf '\033[32m✅ Ready\033[0m — %s checks passed, %s warning(s). Go ahead and create your Mobile Dev workspace.\n' "$PASS" "$WARN"
else
  printf '\033[31m❌ Not ready\033[0m — %s blocking issue(s), %s warning(s). Fix the ✗ items above, then re-run.\n' "$FAIL" "$WARN"
  exit 1
fi
# Note: this verifies the platform + your permissions. It can't check redroid's
# in-VM boot (binder/Android), which happens after provisioning — use
# `device status` from inside the workspace for that.
