#!/bin/bash
# Control script for Steam Toggle plugin (Optimized with Audio features)

export ACTION="$1"

SETTINGS_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugin_settings.json"

# Helper function to read plugin settings using jq.
# Returns the saved user value, or falls back to the default value provided as the second argument.
get_setting() {
    local key="$1"
    local default="$2"
    if [ -f "$SETTINGS_FILE" ] && command -v jq &>/dev/null; then
        local val
        val=$(jq -r ".steamToggle.\"$key\"" "$SETTINGS_FILE" 2>/dev/null)
        if [ "$val" != "null" ]; then
            echo "$val"
            return
        fi
    fi
    echo "$default"
}

# Load plugin configurations.
# NOTE: The second arguments (e.g. "false", "") are only FALLBACK DEFAULTS.
# If you have saved your own options in the DMS settings GUI, they will be loaded from the JSON file.
export USE_FLATPAK=$(get_setting "useFlatpak" "false")
export USE_GAMESCOPE=$(get_setting "useGamescope" "false")       # Disabled by default for general compatibility
export GAMESCOPE_ARGS=$(get_setting "gamescopeArgs" "")
export REOPEN_NORMAL_CMD=$(get_setting "reopenNormalCmd" "")
export EXTRA_START_CMD=$(get_setting "extraStartCmd" "")         # Custom startup command, empty by default
export EXTRA_STOP_CMD=$(get_setting "extraStopCmd" "")           # Custom teardown command, empty by default
export TARGET_AUDIO=$(get_setting "targetAudio" "")               # Target audio device name, empty by default
export TARGET_VOLUME=$(get_setting "targetVolume" "100")
export MAX_AUDIO_INTENTOS=$(get_setting "maxAudioIntentos" "10")

LOG_FILE="$(dirname "$0")/steam_toggle.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$ACTION] $*" >> "$LOG_FILE"
}

# Set Steam executable and kill command depending on Flatpak option
if [ "$USE_FLATPAK" = "true" ]; then
    STEAM_BIN="flatpak run com.valvesoftware.Steam"
    KILL_CMD="flatpak kill com.valvesoftware.Steam"
else
    STEAM_BIN="steam"
    KILL_CMD="pkill -TERM steam"
fi

# Set up command to start Steam (optionally within Gamescope and with NVIDIA offload)
if [ "$USE_GAMESCOPE" = "true" ]; then
    if ! command -v gamescope &>/dev/null; then
        log "ERROR: gamescope command not found in PATH."
    fi
    if lspci | grep -qi nvidia || command -v nvidia-smi &>/dev/null; then
        START_CMD="gamescope $GAMESCOPE_ARGS -- env __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia $STEAM_BIN -gamepadui"
    else
        START_CMD="gamescope $GAMESCOPE_ARGS -- $STEAM_BIN -gamepadui"
    fi
else
    START_CMD="$STEAM_BIN -tenfoot -fullscreen"
fi

is_running() {
    pgrep -x "steam" > /dev/null || pgrep -x "steamwebhelper" > /dev/null
}

# Automatically switches audio output and sets volume to target device
set_audio() {
    [ -z "$TARGET_AUDIO" ] && return
    log "set_audio: target device '$TARGET_AUDIO' with volume '$TARGET_VOLUME'"
    local intento=0
    while [ $intento -lt "$MAX_AUDIO_INTENTOS" ]; do
        local salida
        # Cycle through available output devices via DMS IPC
        salida=$(dms ipc call audio cycleoutput 2>/dev/null)
        log "set_audio: Attempt $((intento+1)) - cycleoutput: '$salida'"
        if [[ "$salida" == *"$TARGET_AUDIO"* ]]; then
            log "set_audio: Target device found. Setting volume to $TARGET_VOLUME"
            dms ipc call audio setvolume "$TARGET_VOLUME" 2>/dev/null
            break
        fi
        ((intento++))
        sleep 0.2
    done
}

case "$ACTION" in
    start)
        # Clear log on fresh start to keep it readable
        > "$LOG_FILE"
        log "=== Starting Steam Big Picture Toggle Script ==="
        log "Args: USE_FLATPAK=$USE_FLATPAK, USE_GAMESCOPE=$USE_GAMESCOPE, GAMESCOPE_ARGS='$GAMESCOPE_ARGS', TARGET_AUDIO='$TARGET_AUDIO', TARGET_VOLUME=$TARGET_VOLUME"
        log "START_CMD: $START_CMD"
        
        pkill -f "steam_toggle.sh monitor" 2>/dev/null
        if is_running; then
            log "Steam is already running. Stopping it first: $KILL_CMD"
            eval "$KILL_CMD" >> "$LOG_FILE" 2>&1
            sleep 2
        fi
        
        if [ -n "$EXTRA_START_CMD" ]; then
            log "Executing EXTRA_START_CMD: $EXTRA_START_CMD"
            eval "$EXTRA_START_CMD" >> "$LOG_FILE" 2>&1
            log "EXTRA_START_CMD exit code: $?"
        fi
        
        log "Starting set_audio in background"
        set_audio &
        
        sleep 5
        log "Executing START_CMD: $START_CMD"
        eval "$START_CMD" >> "$LOG_FILE" 2>&1 &
        
        log "Starting monitor in background"
        "$0" monitor >> "$LOG_FILE" 2>&1 &
        ;;
    stop)
        log "=== Stopping Steam Big Picture Toggle Script ==="
        pkill -f "steam_toggle.sh monitor" 2>/dev/null
        log "Executing KILL_CMD: $KILL_CMD"
        eval "$KILL_CMD" >> "$LOG_FILE" 2>&1
        log "KILL_CMD exit code: $?"
        
        if [ -n "$EXTRA_STOP_CMD" ]; then
            log "Executing EXTRA_STOP_CMD: $EXTRA_STOP_CMD"
            eval "$EXTRA_STOP_CMD" >> "$LOG_FILE" 2>&1
            log "EXTRA_STOP_CMD exit code: $?"
        fi
        ;;
    status)
        is_running && exit 0 || exit 1
        ;;
    monitor)
        # Background loop that waits for Steam to start, and runs cleanup commands when it exits
        log "Monitor: Waiting for Steam to start (timeout 20s)..."
        start_timeout=20
        while ! is_running && [ $start_timeout -gt 0 ]; do
            sleep 1
            ((start_timeout--))
        done
        
        if is_running; then
            log "Monitor: Steam is running. Monitoring process..."
        else
            log "Monitor ERROR: Steam failed to start within timeout."
        fi
        
        while is_running; do
            sleep 2
        done
        
        log "Monitor: Steam process terminated."
        if [ -n "$EXTRA_STOP_CMD" ]; then
            log "Monitor: Executing EXTRA_STOP_CMD: $EXTRA_STOP_CMD"
            eval "$EXTRA_STOP_CMD" >> "$LOG_FILE" 2>&1
        fi
        if [ -n "$REOPEN_NORMAL_CMD" ]; then
            log "Monitor: Executing REOPEN_NORMAL_CMD: $REOPEN_NORMAL_CMD"
            eval "$REOPEN_NORMAL_CMD" >> "$LOG_FILE" 2>&1 &
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|status|monitor}"
        exit 1
        ;;
esac
