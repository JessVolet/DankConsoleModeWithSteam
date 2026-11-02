# Steam Big Picture (`dankConsoleSteam`) 2.0 Roadmap

Status: proposed modernization plan, not yet implemented. Baseline: `1.0.0`, commit `cffe375`. Read with `plan.md`, `CODESTYLE.md`, and `todo.md`.

## Outcome and visual direction

Modernize `dankConsoleSteam` from legacy DankMaterialShell 1.x to **Dux Shell 2.0** (`requires_dms: ">=2.0.0"`), resolving every blocker and issue reported in `duxlabs-dev/dux-plugin-registry#658` while upgrading the user experience with focused frontend patterns from `VMonitorSRV` and `Gbuds-Widget`.

The redesigned widget preserves its lightweight purpose—launching and stopping Steam Big Picture with optional Gamescope, audio routing, and custom lifecycle hooks—while eliminating background process storms, fixing broken settings persistence, and providing presets and quick toggles so common console-mode setups require zero manual CLI flag memorization.

## Review findings and architectural consequences (`dux-plugin-registry#658`)

| Inspected finding | Modernization consequence |
|---|---|
| **Blocker (`SteamToggle.qml:35` & `steam_toggle.sh`):** 3s timer runs `steam_toggle.sh status` 24/7; script runs `jq` 9 times + `lspci\|grep` before reaching `case status` (~10 processes every 3s) | Move `status` check to line 1 of `steam_toggle.sh` (`pgrep` only, 0 `jq`/`lspci` calls). Use adaptive polling in QML (`3s` only when `interactionActive` or transitioning; `15s` when closed) |
| **Issue (`SteamToggleSettings.qml:8` & `steam_toggle.sh:15`):** `pluginId` is `"DankConsoleSteam"` in settings/script but `"dankConsoleSteam"` in `plugin.json`; saved values never bind to `pluginData` | Unify `pluginId` to `"dankConsoleSteam"` everywhere; support both `~/.config/dms/plugin_settings.json` and `~/.config/DankMaterialShell/plugin_settings.json` with single-pass `jq` |
| **Issue (`steam_toggle.sh:37`):** Writes unbounded `steam_toggle.log` inside plugin install directory and commits `steam_toggle.log` to git | Remove committed `steam_toggle.log`, add `.gitignore`, relocate log to `${XDG_CACHE_HOME:-$HOME/.cache}/dankConsoleSteam/steam_toggle.log`, and cap size at 64 KiB / 500 lines |
| **Issue (`plugin.json` / registry manifest):** Dependencies omit `jq` and `pciutils`; missing Dux Shell 2.0 `$schema` and `requires_dms` fields | Declare `dependencies: ["steam", "gamescope", "jq"]` (and use `/proc/driver/nvidia` + `nvidia-smi` before optional `lspci`), add `$schema` and `requires_dms: ">=2.0.0"` |
| **Issue (`SteamToggle.qml:80`):** Hardcoded geometry (`height: 50`, `40`, `size: 18`, `width: 10`, `radius: 5`) and legacy `DankIcon` instead of `Theme` tokens | Replace with `qs.DCommon.Widgets` (`DIcon`, `DButton`, `DIconButton`), `Theme.iconSize`, `Theme.cornerRadius`, `Theme.spacing*`, and content-driven `implicitHeight` |
| **UX gap:** Configuring Gamescope requires typing raw flags (`-W 1920 -H 1080 -r 60 -f -e`) and switching modes requires opening full Settings | Add easy presets in `SteamToggleSettings.qml` (Resolution, Refresh Rate, Fullscreen, GPU offload) + quick mode chips and direct Settings shortcut in the popout |

## Capability map

Dependencies flow top-down; cycles are forbidden. Because this plugin is a focused utility, components stay compact and cohesive.

| Module ID | Responsibility | Depends on |
|---|---|---|
| `manifest` | `plugin.json` Dux Shell 2.0 schema, `.gitignore`, repo hygiene | — |
| `backend` | `steam_toggle.sh`: fast-path `status`, single-pass config, Gamescope preset builder, `$XDG_CACHE_HOME` bounded log, audio IPC | `manifest` |
| `settings` | `SteamToggleSettings.qml`: sectioned preferences (`VMonitorSRV` style), presets, audio & hook configuration under `"dankConsoleSteam"` | `manifest` |
| `surfaces` | `SteamToggle.qml`: adaptive polling, bar pills, Control Center integration, and Material 3 popout (`HeaderCard` + quick toggles + actions) | `backend`, `settings` |
| `docs` | `README.md`, `README.es.md`, and registry entry alignment | All above |

## Delivery phases

| Phase | Usable slice | Exit gate |
|---|---|---|
| **P0: Hygiene & Manifest** | Remove committed log, add `.gitignore`, upgrade `plugin.json` to Dux Shell 2.0 schema with complete dependencies | `git status` clean of logs; `plugin.json` validates against Dux 2.0 fields |
| **P1: Backend & Process Efficiency** | Refactored `steam_toggle.sh` with immediate `status` exit, single-pass `jq`, Dux/DMS config lookup, preset expansion, and bounded `$XDG_CACHE_HOME` log | `status` spawns 0 `jq`/`lspci` processes; logs write to `$XDG_CACHE_HOME` and stay under 64 KiB |
| **P2: Settings & Presets** | Fixed `pluginId: "dankConsoleSteam"` and sectioned `SteamToggleSettings.qml` with Gamescope resolution/FPS presets + custom overrides | Saving any setting updates `~/.config/dms/plugin_settings.json` under `dankConsoleSteam` and reflects immediately in `pluginData` |
| **P3: Dux Shell 2.0 Frontend** | Redesigned `SteamToggle.qml` using `qs.DCommon.Widgets`, `Theme` tokens, adaptive polling, status header, quick mode toggles, and Settings button | Zero hardcoded pixel sizes/radii; popout opens Settings directly; polling drops to 15s when closed |
| **P4: Verification & Docs** | End-to-end verification of all 5 review items in `#658` and updated English/Spanish READMEs | All acceptance criteria in `todo.md` verified and documented |

## Migration strategy

1. **Preserve backward compatibility with existing user settings:** Existing keys (`useFlatpak`, `useGamescope`, `gamescopeArgs`, `reopenNormalCmd`, `extraStartCmd`, `extraStopCmd`, `targetAudio`, `targetVolume`, `maxAudioIntentos`) remain supported so current users do not lose their commands.
2. **Add non-breaking preset keys:** New preset keys (`gamescopeResolution`, `gamescopeRefreshRate`, `gamescopeFullscreen`, `nvidiaOffload`) combine cleanly with `gamescopeArgs` (presets provide base flags, `gamescopeArgs` appends extra flags).
3. **Dual config path lookup in `steam_toggle.sh`:** Check `${XDG_CONFIG_HOME:-$HOME/.config}/dms/plugin_settings.json` first, falling back to `${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugin_settings.json`. Also migrate any orphaned `.DankConsoleSteam` object if `.dankConsoleSteam` is empty when reading from the script.

## Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| User previously saved settings under `"DankConsoleSteam"` (uppercase D) | Medium | In `steam_toggle.sh`, fallback to `.DankConsoleSteam` if `.dankConsoleSteam` is null so existing configs still work until re-saved |
| Gamescope started with conflicting resolution flags if user already set `-W`/`-H` in `gamescopeArgs` | Medium | Default `gamescopeResolution` to `"custom"` when `gamescopeArgs` already contains `-W` or `-H`, or only prepend preset flags when preset != `"custom"` |
| `lspci` missing on minimal distros | Low | Detect NVIDIA first via `/proc/driver/nvidia/version` and `command -v nvidia-smi`, using `lspci` only as a last resort if installed |
| Rapid clicking on Start/Stop in popout or Control Center | Medium | Track `isTransitioning` state (`"starting"` / `"stopping"`) to disable duplicate clicks and poll at 2s until state settles |
