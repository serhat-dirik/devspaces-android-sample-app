#!/usr/bin/env bash
# Quickstart cache — CLUSTER ADMIN runs this once (see "Quick test" in README.md).
#
# Imports the pre-baked Android device disk from quay.io into the `openshift`
# namespace so every developer's device CSI-clones it in seconds instead of
# downloading + building everything (first `device start`: ~2 min instead of
# ~10+). Also applies the two plumbing bindings the device screen and the clone
# need. Grants NO user permissions — see the README warning about VM rights.
#
# Idempotent. Requires cluster-admin. Needs only `oc`.
set -euo pipefail
CACHE_NS="${CACHE_NS:-openshift}"
GOLDEN_IMG="${GOLDEN_IMG:-quay.io/serhat_dirik/devspaces-android-golden:latest}"
ok(){   printf '  \033[32m✓\033[0m %s\n' "$*"; }
info(){ printf '  → %s\n' "$*"; }
fail(){ printf '  \033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

command -v oc >/dev/null || fail "oc not found"
oc auth can-i '*' '*' --all-namespaces >/dev/null 2>&1 || fail "needs cluster-admin"
oc get crd datavolumes.cdi.kubevirt.io >/dev/null 2>&1 || fail "OpenShift Virtualization (CDI) not installed"

info "plumbing (clone consent in ${CACHE_NS} + screen auth delegation)"
oc apply -f - <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: android-golden-image-cloner
  labels: { app: devspaces-android }
rules:
  - apiGroups: ["cdi.kubevirt.io"]
    resources: ["datavolumes/source"]
    verbs: ["create"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get"]
  - apiGroups: ["image.openshift.io"]
    resources: ["imagestreamtags"]
    verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: android-golden-image-cloner
  namespace: ${CACHE_NS}
  labels: { app: devspaces-android }
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: android-golden-image-cloner
subjects:
  - kind: Group
    apiGroup: rbac.authorization.k8s.io
    name: system:authenticated
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: android-screen-auth-delegator
  labels: { app: devspaces-android }
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
  - kind: Group
    apiGroup: rbac.authorization.k8s.io
    name: system:authenticated
YAML

if oc get pvc golden-android-disk -n "$CACHE_NS" >/dev/null 2>&1; then
  ok "device image already cached (${CACHE_NS}/golden-android-disk) — nothing to do"
  exit 0
fi

info "importing the pre-baked device disk from quay (one-time, a few minutes)"
oc apply -n "$CACHE_NS" -f - <<YAML
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  name: golden-android-disk
  labels: { app: devspaces-android, role: golden-image }
  annotations:
    cdi.kubevirt.io/storage.deleteAfterCompletion: "false"
spec:
  source:
    registry:
      url: "docker://${GOLDEN_IMG}"
      pullMethod: node
  storage: { resources: { requests: { storage: 40Gi } } }
YAML

echo -n "  waiting for the import"
for _ in $(seq 1 60); do
  phase="$(oc get datavolume golden-android-disk -n "$CACHE_NS" -o jsonpath='{.status.phase}' 2>/dev/null)"
  [ "$phase" = "Succeeded" ] && { echo; ok "device image cached: ${CACHE_NS}/golden-android-disk"; exit 0; }
  echo -n "."; sleep 10
done
echo
fail "import not finished after 10 min — check: oc get datavolume golden-android-disk -n ${CACHE_NS}"
