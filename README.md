# Steam Big Picture Toggle

A DankMaterialShell widget plugin to run Steam in Big Picture mode with custom arguments, startup commands, and automated audio routing.

![Steam Control Panel](./screenshot.png)

## About

Steam Big Picture Toggle provides a simple toggle button on your bar or control center to switch Steam into Big Picture mode. It supports running Steam natively or via Flatpak, optionally inside Gamescope with custom window arguments.

This plugin integrates with shell features — you can specify custom startup and shutdown commands (such as switching monitor output profiles via `dms ipc`) and automatically target specific audio devices (like an HDMI TV) and set the volume.

## Install

### Plugin manager

The plugin can be installed from the plugin browser in DankMaterialShell.

### Manual install

1. Download or clone this repository.
2. Extract or symlink it into your DankMaterialShell plugins directory:

```bash
ln -sf /path/to/DankConsoleModeWithSteam "${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugins/SteamToggle"
```

3. Open DankMaterialShell Settings → Plugins, click "Scan for Plugins", and enable **Steam Big Picture**.
4. Add the widget to your DankBar widgets list.

## IPC Commands

Control the toggle via DMS IPC:

| Command | Description |
| --- | --- |
| `dms ipc call plugins reload DankConsoleSteam` | Reload the plugin at runtime |

## Customization

Configure the following settings in DMS Settings under **Steam Big Picture Settings**:
- **Use Flatpak**: Run Steam via Flatpak (`com.valvesoftware.Steam`) or natively.
- **Use Gamescope**: Run Steam inside Gamescope.
- **Gamescope Arguments**: Arguments for Gamescope window (e.g., `-W 1920 -H 1080 -f -e`).
- **Command on Close**: Program to run when Big Picture exits (e.g., `steam` to reopen normal desktop client).
- **Extra Startup / Shutdown Commands**: Command hooks executed before start and after exit (e.g. `dms ipc outputs setProfile BigPicture`).
- **Target Audio Device / Volume / Attempts**: Target audio device name, volume, and search retries to automatically route audio to the gaming screen on startup.
