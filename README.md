# Steam Big Picture Toggle Plugin

A widgets plugin for **DankMaterialShell** (DMS) that provides a toggle switch to run Steam in Big Picture mode with custom settings, gamescope configurations, and automated audio routing.

## Features

- **Toggle Steam Big Picture**: Easily start and stop Steam Big Picture mode from your bar or control center.
- **Flatpak & Native Support**: Supports running Steam either natively or via Flatpak.
- **Gamescope Integration**: Run Steam inside Gamescope with custom size and display options (automatically optimizes for NVIDIA GPUs using prime offload environment variables).
- **Custom Hook Commands**: Run custom shell commands on startup and teardown (e.g., switching monitor profiles using `dms ipc`).
- **Automated Audio Routing**: Automatically cycles through audio outputs on launch to find a target audio device (e.g., your TV) and configures the volume.
- **Reopen Normal Steam**: Optionally restart Steam in normal desktop mode once you exit Big Picture.

## Configuration Options

Configure these options directly in the DankMaterialShell settings interface:

- **Use Flatpak**: Toggle to run Steam via Flatpak (`com.valvesoftware.Steam`) or native.
- **Use Gamescope**: Toggle to run Steam inside Gamescope.
- **Gamescope Arguments**: Extra window parameters for Gamescope (e.g. `-W 1920 -H 1080 -f -e`).
- **Command on Close**: Program to run when Big Picture exits (e.g., `steam` to reopen the desktop UI).
- **Extra Startup / Shutdown Commands**: Custom scripts or DMS IPC commands to run when starting/stopping Steam.
- **Target Audio Device / Volume**: Cycle through audio devices to find one matching a specific name (e.g., `HDMI` or `AD107`) and set the desired volume.

## Internal Architecture

This plugin consists of two main parts:
1. **`SteamToggle.qml` & `SteamToggleSettings.qml`**: Renders the toggle widgets, popout controls, and manages UI configurations.
2. **`steam_toggle.sh`**: A background control script that manages launching, monitoring, and cleaning up Steam processes. It reads current settings directly from DMS configuration (`~/.config/DankMaterialShell/plugin_settings.json`).
