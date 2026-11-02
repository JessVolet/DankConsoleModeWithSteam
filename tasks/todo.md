# Modernization Implementation TODO (`dankConsoleSteam` 2.0)

Status: modularized, hardened against Quickshell/PipeWire crashes, and verified.

## Planning delivery

- [x] Inspect `JessVolet/DankConsoleModeWithSteam` baseline (`cffe375`) and `dux-plugin-registry#658` review findings.
- [x] Inspect `VMonitorSRV` and `Gbuds-Widget` for Dux Shell 2.0 frontend and settings patterns.
- [x] Author `CODESTYLE.md`, `roadmap.md`, `plan.md`, and `todo.md`.
- [x] User approved implementation of the modernization plan.

---

## P0: Repository hygiene and Dux Shell 2.0 manifest

### S01 — Clean tracked log, enforce pure English, and upgrade `plugin.json` to Dux Shell 2.0

**Acceptance criteria:**
- [x] `steam_toggle.log` and `README.es.md` removed from git.
- [x] `.gitignore` ignores `*.log` and temporary backup files.
- [x] `plugin.json` retains `"id": "dankConsoleSteam"`, adds `"$schema"`, `"requires_dms": ">=2.0.0"`, `"capabilities": ["dankbar-widget"]`, and `"dependencies": ["steam", "gamescope", "jq"]`.

---

## P1: Backend efficiency, cgroup isolation, and bounded logging

### S02 — Zero-overhead `status` fast path, `$XDG_CACHE_HOME` logging, and cgroup isolation in `steam_toggle.sh`

**Acceptance criteria:**
- [x] `./steam_toggle.sh status` exits before any `jq`, `lspci`, or `mkdir` command is reached.
- [x] Steam/Gamescope launched decoupled via `systemd-run --user --scope` / `setsid` so `gamescopereaper` doesn't kill gamescope when the launcher script exits, and memory/Vulkan allocations are isolated from `dms.service`.
- [x] Audio routing is completely skipped when `enableAudioRouting` is false. When enabled, PipeWire settling delay and direct `pactl` targeting avoid rapid cycling crashes.
- [x] Log file is written under `${XDG_CACHE_HOME:-$HOME/.cache}/dankConsoleSteam/steam_toggle.log` with 64 KiB ceiling.

---

## P2: Reactive settings and user-friendly presets

### S03 & S04 — Fix `pluginId` and modernize `SteamToggleSettings.qml` with audio toggle

**Acceptance criteria:**
- [x] `pluginId` is `"dankConsoleSteam"` (exact match with `plugin.json`).
- [x] `enableAudioRouting` toggle added (defaults to `false`).
- [x] All labels, descriptions, and headers in English.

---

## P3: Modular Dux Shell 2.0 Frontend

### S05 & S06 — Modular component architecture

**Acceptance criteria:**
- [x] Modular architecture under `components/`:
  - `components/StatusHeader.qml`: Header card with squircle badge, title, subtitle, status badge pill, and settings button.
  - `components/ModeSwitchers.qml`: Interactive tactile cards for Gamescope and Runtime with checkmarks.
  - `components/PresetSummary.qml`: Display preset and audio route summary.
  - `components/ActionControl.qml`: Dynamic hero action button (`Launch Big Picture` / `Exit Big Picture`).
- [x] `SteamToggle.qml` clean coordinator with bar pills and adaptive polling.

---

## P4: Documentation and final review verification

### S07 & S08 — English documentation and live reload

**Acceptance criteria:**
- [x] `README.md` documents dependencies, presets, and audio routing toggle in 100% English.
- [x] Registry manifest updated with `jq` and `pciutils`.
- [x] Verified live reload in Dux Shell (`PLUGIN_RELOAD_SUCCESS: dankConsoleSteam`).
