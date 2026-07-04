# Flutter Mobile App — sample for the OpenShift Dev Spaces Android platform

This is a **sample Flutter app** for the
[`devspaces-android`](https://github.com/serhat-dirik/devspaces-android) platform.
Once your admin get your DevSpaces ready for you, the below is the happy path,
start to finish. Each step is expanded below.

1. **Open your workspace:** Dev Spaces dashboard → **"Mobile Dev (Flutter+Android
   VM)"** → wait ~1–2 min.
2. **Run the Web preview:** **Terminal → Run Task… → "Web preview"** (there's no
   "Run" button), wait for the first build (~25–30s), then open **flutter-web** from
   the **Endpoints** panel.
3. **(When you want real Android):** in the workspace terminal:
   `device start` (first boot takes a few minutes) → `device watch`
   until ready → `device run` → `device screen`. Run `device stop`
   when you're done.

---

## Step 1 — Open your workspace

Go to the **Dev Spaces dashboard** (OpenShift console top-right grid
menu → **Dev Spaces**, or the URL your admin gives you), choose **"Mobile Dev
(Flutter+Android VM),"** and wait **~1–2 min** for the browser IDE to load.
This repo is cloned for you and a workspace opens.

> **What the wait is:** the workspace image loads and `pub get` runs. Your device
> does **not** start here — you start it yourself when you want it (see 2b).

<strong>Alternative way to get into the workspace</strong>

- **Directly:** create a Dev Spaces workspace from this repository's URL — it
  has a `devfile.yaml`, so Dev Spaces knows how to set everything up.

---

## Step 2 — Run it: two ways, both available anytime (in the workspace)

You've got two run modes, and you can switch between them whenever you like. Start
with the **Web preview** — it's the fast default and needs no device.


### 2a. Web preview — your fast develop / test loop (no device needed)

This is the **fast default** and where you'll spend most of your time — no device
needed. There's **no single "Run" button** in Dev Spaces; start it either way (both
do exactly the same thing):

- **From the menu:** **Terminal → Run Task…** (or Command Palette **F1** → "Tasks:
  Run Task") → choose **"Web preview"**.
- **From a terminal** — run it in your project folder (where `pubspec.yaml` lives).
  It's **one line** on purpose (so nothing breaks when you paste it), and there's no
  `cd` — `--directory` points the server straight at the build output:
  ```bash
  flutter build web --profile --base-href / && python3 -m http.server 8080 --bind 0.0.0.0 --directory build/web
  ```
  *(Just don't run this **and** the Web preview task at the same time — they'd both want port 8080.)*

Either way it builds a **profile** bundle and serves it over plain HTTP, so it
renders reliably through the gateway (**no hot reload** — re-run after edits).

**You'll see:** on **Day 1**, the **first** compile takes **~25–30s** (the bar at
the top shows progress).

> **First build ~25–30s with no output for a while — that's normal, not a hang.**

**Then open your app** from the EXPLORER **Endpoints** panel. The globe in the far-left
icon strip **is** the Endpoints icon. Click the globe → the **Endpoints** view
lists every URL your workspace exposes → click **flutter-web** to open your app.

> **If it snags — no globe?** Command Palette **F1** → 'Endpoints'. Ignore the
> `devtools` entry.

Endpoints is a **Dev Spaces panel**, not stock VS Code, and is the durable way to
find your app — a pop-up notification also offers *Open in New Tab* when the server
starts, but it's easy to miss. Subsequent runs are incremental and faster; after
you edit `lib/main.dart`, run the **Web preview** task again.

<details>
<summary><strong>Want hot reload + breakpoints? Use the IDE debug launch (and why it differs)</strong></summary>

> **This path needs the Dart + Flutter extensions installed.** They're *recommended*
> for this repo, so the IDE may prompt you on first open — or install them yourself
> from the **Extensions** view (search "Flutter"). If they're missing from the
> marketplace, your admin needs to point Dev Spaces at Open VSX
> (`CheCluster … pluginRegistry.openVSXURL: https://open-vsx.org`). **The Web preview
> above needs no extension** — use it if you'd rather not install anything.

Use **Run → Start Debugging** with the **Flutter: Web hot reload (IDE debug)**
launch config — *not* the **Web preview** task. The two are different on purpose:

- The **Web preview** *task* serves a **profile** build over HTTP. It is the
  reliable default and never needs a debug socket — but it can't hot-reload.
- The **IDE debug** *launch* runs a **debug** build. A debug build needs a dwds
  WebSocket, and that's exactly why we **don't** shell out raw
  `flutter run -d web-server` from the task: run by hand, dwds is pinned to
  `127.0.0.1` and can't connect through the HTTPS gateway, so **the tab stays
  blank**. Launched from the IDE, the Dart & Flutter extension owns and
  *forwards* the dwds connection itself, so the debug session can connect where
  the raw command can't.

> **If it snags — IDE debug tab comes up blank** in your particular gateway setup?
> That's the dwds-through-proxy edge case — **fall back to the Web preview task**
> (profile build, no hot reload, always works). No path here is one the platform
> tells you will fail.

> **Known limitation — the DevTools *panels*** (Flutter Inspector, Property Editor,
> Widget Preview) may show *"can't connect to localhost:&lt;port&gt;"*. They reach the
> Dart VM service over a **dynamic localhost port** that can't be forwarded through the
> browser gateway — a limitation of Flutter DevTools in **any** browser-based IDE
> (Dev Spaces, Codespaces, Gitpod alike), not this platform specifically. **Hot reload,
> breakpoints, and the debug console all work** (that connection is handled inside the
> workspace); only the visual DevTools panels are affected.

</details>

### 2b. On the real on-cluster Android device — verify on Android

> **Heads-up — YOUR device, YOU start it.** The device does **not** start by
> itself: run `device start` first (also under **Terminal → Run Task →
> "Device: provision"**). First-ever provision takes several minutes (it imports
> the VM image); later starts are ~1–2 min. When you're done for the day, run
> `device stop` to free its CPU/RAM — the workspace going to sleep does **not**
> stop your device.

**You'll need:** a terminal **inside the opened workspace** (open one with
**Terminal → New Terminal** — the editor is VS Code-based). These scripts are on
your `PATH` in any Dev Spaces terminal, not in this repo on your laptop.

**Do this — it's a conditional flow, not four steps you always run top-to-bottom:**

- **Start your device:** `device start` — creates it the first time, wakes
  it any other time; safe to re-run.
- **Wait until booted:** `device watch` — follows the boot live and ends with the
  full status once the device is ready (or `device status` to poll by hand).
- **Build + launch:** `device run` — build + install + launch the app on your
  device.
- **Open the screen:** `device screen` — open your device's live, interactive
  screen in a tab. Log in with your OpenShift account, then on the device row pick a
  decoder: **WebCodecs** (Chrome/Edge, sharpest) or **Broadway.js** (Firefox / anywhere).
  Screen too small? Use the device's **⋮ → Video Settings** to set the bounds (e.g. 832×832).

```bash
device start    # 1) start (or wake) YOUR device — run this first
device status       # 2) wait until it reports booted
device run       # 3) build + install + launch the app on your device
device screen         # 4) open your device's live, interactive screen in a tab
device stop         # 5) when you're done — free the device's CPU/RAM (keeps disk)
```

<details>
<summary><strong>Debugging on the device from the IDE</strong></summary>

The **Flutter: On-cluster Android device** launch config runs the **device-status**
task first (via its `preLaunchTask`) so adb is connected before the device picker
opens. If you launch the device manually, run the **device-status** task yourself
first.

</details>

---

## Day-2 reference

### IDE features

The editor ships the **Dart & Flutter** extensions (autocomplete, inline errors,
the hot-reload button, the **Widget Inspector**, and breakpoint **debugging** via
`Run → Start Debugging` / the `.vscode/launch.json` configs). **Flutter DevTools**
(inspector, performance, network, memory) opens from the debug session. Quality
tasks are one click under **Run Task…** (or in a terminal):

```bash
flutter analyze     # static analysis        (or the 'analyze' task)
dart format .       # format; format-on-save  (or the 'format' task)
flutter test        # run the widget tests    (or the 'test' task)
```


---

## Troubleshooting

On a correctly deployed platform the defaults just work — reach for this section
only when something misbehaves.

**First move — run the readiness check *inside the workspace terminal*:**

```bash
./check-prereqs.sh         # ✅ Ready  /  ❌ Not ready: <what to fix>
```

It verifies the cluster can host your device (KubeVirt), your namespace quota, and
that you're allowed to create VMs (RBAC). No laptop setup needed — the workspace
terminal already has `oc`, logged in as you.

- **Preflight is red?** Common on a brand-new account — **not** something you did
  wrong. Copy the `✗` lines and send them to your platform admin.
- **"You cannot create VMs"?** Dev Spaces should grant you the built-in `edit` role
  in your own namespace automatically (the platform sets CheCluster
  `devEnvironments.user.clusterRoles: ["edit"]`). Ask your admin to confirm that
  setting, then restart your workspace and re-run `./check-prereqs.sh`.
- **Device provisioning failed midway?** Just re-run `device start` — it is
  idempotent and cleans up after itself. `device status` shows where it stands.

<details>
<summary><strong>Workspace won't even open? Run the same check from your laptop</strong></summary>

The one case where you need anything locally (`git` + `oc` — still no Flutter):

1. Sign in to your team's OpenShift console; download `oc` via **?** → **Command
   Line Tools**.
2. **Copy login command** (top-right, your name) and run the `oc login …` line it
   gives you. (Tokens are short-lived — if you see "Not logged in" later, grab a
   fresh one the same way.)
3. `git clone https://github.com/serhat-dirik/devspaces-android-sample-app && cd
   devspaces-android-sample-app && ./check-prereqs.sh`

</details>

---

## Quick test with pre-built images (no platform build)

Want to try this without deploying the full platform? Pre-built images are
published at `quay.io/serhat_dirik/devspaces-*`. Ask a **cluster admin** to run
[`./quickstart-cache.sh`](quickstart-cache.sh) once — the images are **large**,
and without the cache your first `device start` downloads and assembles
everything (**10+ minutes instead of ~2**). The cluster still needs OpenShift
Virtualization and Dev Spaces installed.

Then create your workspace: Dev Spaces dashboard → **Create Workspace** → paste

```
https://raw.githubusercontent.com/serhat-dirik/devspaces-android-sample-app/main/devfile-quay.yaml
```

> ⚠️ **Your OpenShift user must be able to create VMs in your workspace
> namespace** — the built-in `edit` role covers it (ask your admin, e.g.
> `oc adm policy add-role-to-user edit <you> -n <you>-devspaces`). You run the
> device yourself from the workspace terminal (`device start` / `device stop`)
> — that's plain Kubernetes, so plain Kubernetes permissions.
