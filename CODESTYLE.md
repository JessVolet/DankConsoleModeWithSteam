# Code Quality and Dux Shell 2.0 Plugin Style

Status: required coding contract for the `dankConsoleSteam` 2.0 modernization. All implementation tasks in `todo.md` must follow this document. Derived from `Gbuds-Widget` and `VMonitorSRV` conventions.

## 1. Quality standard

Write clear, fast, safe, bounded code that integrates natively with Dux Shell (`>=2.0.0`). Prefer a small, cohesive implementation over over-engineered abstractions or fragile shell hacks.

Use English for identifiers, comments, documentation, log messages, and UI copy (`README.es.md` provides Spanish documentation separately). Comments must be sparse and explain an invariant, process lifecycle detail, compositor limitation, or hardware quirk. Delete comments that merely narrate the next line. Do not hide intent behind nested ternaries, magic pixel numbers, or repeated shell subshells.

## 2. Responsibility and dependency rules

- **Plugin ID invariant:** The canonical plugin identifier is `"dankConsoleSteam"`. It must match identically across `plugin.json`, `SteamToggleSettings.qml`, `SteamToggle.qml`, `steam_toggle.sh`, and the registry manifest.
- **QML surfaces (`SteamToggle.qml`, `SteamToggleSettings.qml`, `components/`):** Render state, apply `Theme` tokens, and emit user intents. Surfaces do not parse raw config files on disk or run hardware discovery commands.
- **Configuration normalization:** `pluginData` is normalized with safe defaults (`useFlatpak`, `useGamescope`, `gamescopePreset`, `gamescopeArgs`, `nvidiaOffload`, `targetAudio`, `targetVolume`, `maxAudioIntentos`, `extraStartCmd`, `extraStopCmd`, `reopenNormalCmd`).
- **Process adapter (`steam_toggle.sh`):** Owns Steam/Gamescope launch, teardown, `dms ipc` audio switching, and background exit monitoring.
- **Line-count review prompts:** Review any QML file approaching ~200 lines or shell function approaching ~40 lines for mixed responsibilities. Extract only when a sub-card (`HeaderCard`, `ActionCard`) clarifies visual hierarchy and ownership.

## 3. Process and shell efficiency contract

Every background process spawned by a bar widget has a system-wide cost. The following rules are mandatory:

1. **Zero-overhead `status` fast path:**
   `steam_toggle.sh status` must execute `is_running` (`pgrep -x "steam" >/dev/null || pgrep -x "steamwebhelper" >/dev/null`) and `exit` at the very top of the script **before** loading settings, resolving paths, calling `jq`, or checking GPU hardware (`lspci`).
2. **Adaptive polling cadence:**
   - Do not run a blind 3-second timer 24/7.
   - Poll every `3000 ms` only while `interactionActive` (popout is open) or during a bounded transition window (`isTransitioning`, e.g., 25 seconds after starting/stopping).
   - When the popout is closed and idle, poll at a slow background cadence (`15000 ms`).
   - Prevent overlapping status checks (`if (!statusProcess.running) statusProcess.running = true`).
3. **Single-pass settings resolution & QML environment injection:**
   - When launching `start` or `stop` from QML, pass resolved settings via environment variables or arguments, or read `plugin_settings.json` in a **single** `jq` invocation rather than spawning `jq` nine separate times.
   - Support both Dux Shell (`${XDG_CONFIG_HOME:-$HOME/.config}/dms/plugin_settings.json`) and legacy DankMaterialShell (`${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugin_settings.json`) paths.
4. **On-demand hardware detection:**
   - Check NVIDIA offload (`command -v nvidia-smi` or `/proc/driver/nvidia/version` before falling back to `lspci`) **only** inside the `start` action when `useGamescope` is enabled—never at script top-level.
5. **Bounded logging outside the plugin directory:**
   - Never write logs inside the plugin installation directory or commit `.log` files to git.
   - Log to `${XDG_CACHE_HOME:-$HOME/.cache}/dankConsoleSteam/steam_toggle.log`.
   - Cap log size automatically (truncate or keep tail when exceeding 64 KiB / 500 lines) so `stop`, `monitor`, and `gamescope` output cannot grow without bound.

## 4. Dux Shell 2.0 UI and Theme contract (`VMonitorSRV` & `Gbuds-Widget` patterns)

1. **Native Dux widgets (`qs.DCommon.Widgets`):**
   - Use `DIcon`, `DButton`, and `DIconButton` instead of legacy `DankIcon` or manual `StyledRect` + `MouseArea` button boilerplates.
   - Use `SelectionSetting`, `ToggleSetting`, `SliderSetting`, and `StringSetting` in `SteamToggleSettings.qml` with explicit `defaultValue` properties and sectioned headers separated by `Rectangle { width: parent.width; height: 1; color: Theme.withAlpha(Theme.outlineStrong, 0.35) }`.
2. **Theme tokens over hardcoded pixels:**
   - Never hardcode icon sizes (`18`), status dots (`10` / `radius: 5`), or row heights (`50`, `40`) where `Theme` tokens exist.
   - Use `Theme.iconSize`, `Theme.cornerRadius`, `Theme.spacingXS`, `Theme.spacingS`, `Theme.spacingM`, `Theme.spacingL`, `Theme.fontSizeSmall`, `Theme.fontSizeMedium`, and `Theme.fontSizeLarge`.
   - Derive dimensions from content `implicitHeight` + `Theme.spacing*` padding.
3. **Visual hierarchy (focused utility layout):**
   - **Header region (inspired by `VMonitorSRV/components/HeaderCard.qml`):** Left accent bar (`Theme.primary` when running, `Theme.warning` when starting/stopping, `Theme.surfaceVariantText` when stopped), `DIcon`, primary title, active mode subtitle (`Native` / `Flatpak` · `Gamescope`), status badge (`ACTIVE` / `STARTING` / `STOPPED`), and a `DIconButton` (`iconName: "settings"`) that opens plugin settings directly via `PopoutService.openSettingsWithTab(SettingsTabs.pluginPage(root.pluginId).id)`.
   - **Summary & Quick Toggles:** Clear badges or compact rows showing effective launch configuration (Display preset, Gamescope status, Target audio) and quick one-click toggles for `useGamescope` / `useFlatpak` so the user does not have to open full settings for routine switches.
   - **Primary action buttons:** Prominent Start / Stop controls using `DButton` with proper enabled/disabled states, tooltips, and immediate transition feedback.

## 5. Review and verification gates

Before committing any task slice:

- Inspect `git diff` for hardcoded pixel values, mismatched `pluginId` strings, unguarded shell evaluations, or top-level subshells in `steam_toggle.sh`.
- Verify `bash -n steam_toggle.sh` and trace process spawns on `./steam_toggle.sh status` (must be at most `pgrep`, zero `jq` or `lspci`).
- Verify `steam_toggle.log` is absent from `git status` and written only under `$XDG_CACHE_HOME/dankConsoleSteam/`.
- Confirm every task in `todo.md` records its verification evidence before marking it complete.

## 6. Definition of done

The plugin loads cleanly in Dux Shell `>=2.0.0`, passes all five review points in `dux-plugin-registry#658`, spawns zero unnecessary processes while polling status, persists and reflects all settings immediately under `dankConsoleSteam`, keeps logs bounded in `$XDG_CACHE_HOME`, and presents a responsive, token-driven Material 3 UI consistent with `VMonitorSRV` and `Gbuds-Widget`.
