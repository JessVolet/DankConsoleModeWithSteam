# Implementation Plan: Steam Big Picture (`dankConsoleSteam`) 2.0

Status: proposed plan awaiting user approval before code modification. Baseline: `1.0.0`, commit `cffe375`.

Read in order:

1. [Roadmap and capability map](roadmap.md)
2. [Code style and Dux Shell 2.0 contract](CODESTYLE.md)
3. [Ordered tasks and verification checklist](todo.md)

## Overview

Upgrade `dankConsoleSteam` to Dux Shell `>=2.0.0`, addressing all five review findings from `duxlabs-dev/dux-plugin-registry#658` (unbounded 3s `jq`/`lspci` process spawning, mismatched `pluginId` casing, unbounded committed log file, missing dependencies, and hardcoded QML dimensions) while modernizing the frontend and settings UX using selected patterns from `VMonitorSRV` and `Gbuds-Widget`.

## Assumptions

1. **Target runtime:** Dux Shell `>=2.0.0` (`qs.Common`, `qs.Services`, `qs.Widgets`, `qs.DCommon.Widgets`, `qs.Modules.Plugins`).
2. **Scope of UI adoption:** Borrow only the necessary frontend patterns from `VMonitorSRV` (status header card with state indicator bar, sectioned settings with `SelectionSetting` / dividers, adaptive refresh cadence via `interactionActive`) and `Gbuds-Widget` (direct Settings navigation via `PopoutService.openSettingsWithTab`, clean state feedback, content-driven popout height)—without adding multi-page drawers or heavy daemon layers unnecessary for a Steam launcher.
3. **Backward compatibility:** Existing user settings (`useFlatpak`, `useGamescope`, `gamescopeArgs`, `reopenNormalCmd`, `extraStartCmd`, `extraStopCmd`, `targetAudio`, `targetVolume`, `maxAudioIntentos`) remain intact.
4. **Canonical Plugin ID:** `"dankConsoleSteam"` is used everywhere so settings match `plugin.json` and the `dux-plugin-registry` entry (`dms plugins install dankConsoleSteam`).

## Architecture decisions

### 1. Fast-path `status` and single-pass configuration (`steam_toggle.sh`)
- **Decision:** Handle `status` as the very first statement in `steam_toggle.sh` (`if [ "$1" = "status" ]; then ... exit; fi`), calling only `pgrep -x "steam" >/dev/null || pgrep -x "steamwebhelper" >/dev/null`.
- **Rationale:** Eliminates all 9 `jq` invocations and `lspci | grep` calls from the periodic status check, reducing per-tick process overhead by ~90%.
- **Single-pass `jq`:** For `start`, `stop`, and `monitor`, load all settings in a single `jq` call reading from `${XDG_CONFIG_HOME:-$HOME/.config}/dms/plugin_settings.json` (with fallback to `DankMaterialShell/plugin_settings.json` and fallback from `.dankConsoleSteam` to `.DankConsoleSteam` for smooth migration).

### 2. Bounded logging in `$XDG_CACHE_HOME`
- **Decision:** Move `steam_toggle.log` to `${XDG_CACHE_HOME:-$HOME/.cache}/dankConsoleSteam/steam_toggle.log`, delete the tracked `steam_toggle.log` from git, add `*.log` to `.gitignore`, and enforce a 64 KiB / 500-line ceiling before appending in `stop` and `monitor`.
- **Rationale:** Keeps the plugin directory read-only clean and prevents unbounded disk growth during long Gamescope sessions.

### 3. Adaptive polling and transition state (`SteamToggle.qml`)
- **Decision:** Bind `statusTimer.interval` dynamically:
  - `2000 ms` while `transitionState !== ""` (`"starting"` or `"stopping"`, auto-clearing on state match or after a 25s timeout)
  - `3000 ms` while `interactionActive` (popout open)
  - `15000 ms` while popout is closed and idle
- **Rationale:** Gives snappy UI feedback when the user interacts with the widget while keeping background CPU wakeups negligible during normal desktop use.

### 4. Redesigned Popout & Settings UX (`VMonitorSRV` + `Gbuds-Widget` style)

| Region | Design & Components (`qs.DCommon.Widgets` & `Theme`) | User benefit |
|---|---|---|
| **Popout Header Card** | `StyledRect` with left status accent bar (`Theme.primary` / `Theme.warning` / `Theme.surfaceVariantText`), `DIcon` (`sports_esports`), title, subtitle (`Native` or `Flatpak`), status label (`ACTIVE` / `STARTING` / `STOPPED`), and `DIconButton` (`settings`) | Instant visual state recognition + 1-click jump to plugin settings |
| **Quick Mode Chips** | Two interactive `DButton` / pill toggles in the popout for **Gamescope** (`ON/OFF`) and **Runtime** (`Native/Flatpak`) + active preset summary badge (e.g., `1080p · 60Hz` or `Audio: HDMI`) | Toggle Gamescope or Flatpak on the fly without digging into the Settings window |
| **Primary Action Row** | Full-width `DButton` controls for **Launch Big Picture** / **Stop Steam** (plus optional quick **Desktop Steam** button when `reopenNormalCmd` is set) | Clear primary call-to-action with proper disabled/busy states and no hardcoded pixel heights |
| **Sectioned Settings (`SteamToggleSettings.qml`)** | Grouped sections with `SelectionSetting` presets for Gamescope Resolution (`1080p`, `1440p`, `4K`, `Native/Custom`) and Refresh Rate (`60 Hz`, `120 Hz`, `144 Hz`, `Default`), `ToggleSetting` for Fullscreen & NVIDIA Offload, plus existing Audio and Hook settings | New users can configure Gamescope with dropdowns instead of memorizing CLI flags, while power users keep full `gamescopeArgs` control |

## Task summary

- **Phase P0 — Hygiene & Manifest:**
  - [ ] `S01`: Remove committed `steam_toggle.log`, create `.gitignore`, and update `plugin.json` to Dux Shell 2.0 schema.
- **Phase P1 — Backend & Process Efficiency:**
  - [ ] `S02`: Refactor `steam_toggle.sh` with top-of-script `status` fast path, single-pass `jq` config loader, Dux/DMS path resolution, and bounded `$XDG_CACHE_HOME` logging.
  - [ ] `S03`: Add Gamescope preset flag builder and on-demand NVIDIA offload detection in `steam_toggle.sh`.
- **Phase P2 — Reactive Settings & Presets:**
  - [ ] `S04`: Fix `pluginId: "dankConsoleSteam"` and rebuild `SteamToggleSettings.qml` with `VMonitorSRV`-style sections and Gamescope preset selectors.
- **Phase P3 — Dux Shell 2.0 Frontend:**
  - [ ] `S05`: Rebuild `SteamToggle.qml` polling lifecycle (`interactionActive`, `transitionState`, single-flight `statusProcess`) and bar pills with `DIcon` and `Theme.iconSize`.
  - [ ] `S06`: Rebuild `SteamToggle.qml` popout UI using `Theme` tokens, `DButton` / `DIconButton`, status header card, quick mode toggles, and direct Settings navigation.
- **Phase P4 — Verification & Documentation:**
  - [ ] `S07`: Update `README.md`, `README.es.md`, and registry manifest dependencies (`jq`, `pciutils`).
  - [ ] `S08`: Run full verification suite against all 5 items in `dux-plugin-registry#658`.

## Verification gates

- [ ] `./steam_toggle.sh status` exits before any `jq` or `lspci` execution (verified via `strace -e trace=execve` or `bash -x`).
- [ ] `SteamToggleSettings.qml` and `plugin.json` both use `"dankConsoleSteam"`.
- [ ] `steam_toggle.log` is untracked in git and written to `${XDG_CACHE_HOME:-$HOME/.cache}/dankConsoleSteam/steam_toggle.log` with size capping.
- [ ] `SteamToggle.qml` contains zero hardcoded icon/row/dot pixel sizes where `Theme` tokens apply, and uses `qs.DCommon.Widgets`.
- [ ] Human review of `plan.md`, `roadmap.md`, `CODESTYLE.md`, and `todo.md` completed before code edits begin.
