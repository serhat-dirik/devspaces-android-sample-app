# Commands — quick reference

Everything is a plain command in the workspace **terminal** (or **Terminal → Run Task…**).
Type **`mobile-help`** in any terminal to see this list again.

## Run your app
| Command | What it does |
|---|---|
| **"Web preview"** (Run Task) | Fast browser preview — no device needed. Equivalent terminal command: `flutter build web --profile --base-href / && python3 -m http.server 8080 --bind 0.0.0.0 --directory build/web` |
| `device run` | Build + install + **launch** on the real Android device — **prints the live-screen URL** |
| `device screen` | Print the device's live-screen URL (open in a browser tab) |

## Your device — YOU manage its lifecycle (it does not start itself)
| Command | What it does |
|---|---|
| `device start` | **START — run this first.** Creates the device (first time: several minutes) or wakes a stopped one (~1–2 min) |
| `device stop` | **STOP when done** — frees ~4 CPU/4Gi, keeps the disk. Workspace sleep does NOT stop the device |
| `device remove` | **DELETE** the device + disk (deleting the workspace also removes it automatically) |
| `device status` | Is it up? boot state + screen URL |
| `device watch` | Follow the boot live until the device is ready |
| `device restart` | Reboot a frozen device |

## Screen tips
- Log in with your OpenShift account, then pick a decoder: **WebCodecs** (Chrome/Edge) or **Broadway.js** (Firefox).
- Screen too small? Device **⋮ → Video Settings** → set the bounds (e.g. `832×832`) → Apply.

Full detail is in [README.md](README.md) — but you shouldn't need it for day-to-day work.
