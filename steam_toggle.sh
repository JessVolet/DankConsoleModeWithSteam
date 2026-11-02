#!/bin/bash
# Control script for Steam Big Picture (dankConsoleSteam)
# Optimized for Dux Shell 2.0 / DMS with zero-overhead status polling and detached process execution

ACTION="$1"

# Fast path: status check must execute immediately with zero jq/lspci overhead
is_running() {
    pgrep -x "steam" > /dev/null || pgrep -x "steamwebhelper" > /dev/null || pgrep -x "gamescope" > /dev/null
}

if [ "$ACTION" = "status" ]; then
    is_running && exit 0 || exit 1
fi

# Set up bounded log file in $XDG_CACHE_HOME
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dankConsoleSteam"
mkdir -p "$LOG_DIR" 2>/dev/null
LOG_FILE="$LOG_DIR/steam_toggle.log"

log() {
    # Cap log size to ~64 KiB (keep last 250 lines) so it never grows without bound
    if [ -f "$LOG_FILE" ] && [ "$(wc -c < "$LOG_FILE" 2>/dev/null || echo 0)" -gt 65536 ]; then
        tail -n 250 "$LOG_FILE" > "$LOG_FILE.tmp" 2>/dev/null && mv "$LOG_FILE.tmp" "$LOG_FILE" 2>/dev/null
    fi
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$ACTION] $*" >> "$LOG_FILE"
}

# Resolve settings file path (support Dux Shell and legacy DankMaterialShell paths)
SETTINGS_FILE=""
if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/dms/plugin_settings.json" ]; then
    SETTINGS_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/dms/plugin_settings.json"
elif [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugin_settings.json" ]; then
    SETTINGS_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugin_settings.json"
fi

# Default fallback values
USE_FLATPAK="false"
USE_GAMESCOPE="false"
GAMESCOPE_RESOLUTION="custom"
GAMESCOPE_REFRESH_RATE="default"
GAMESCOPE_FULLSCREEN="false"
NVIDIA_OFFLOAD="auto"
GAMESCOPE_ARGS=""
REOPEN_NORMAL_CMD=""
EXTRA_START_CMD=""
EXTRA_STOP_CMD=""
ENABLE_AUDIO_ROUTING="false"
TARGET_AUDIO=""
TARGET_VOLUME="100"
AUDIO_SEARCH_ATTEMPTS="10"

# Load settings in a single jq pass (supporting .dankConsoleSteam and legacy .DankConsoleSteam)
if [ -n "$SETTINGS_FILE" ] && command -v jq &>/dev/null; then
    eval "$(jq -r '
        (.dankConsoleSteam // .DankConsoleSteam // {}) | to_entries | .[] |
        "CFG_\(.key)=\(@sh "\(.value)")"
    ' "$SETTINGS_FILE" 2>/dev/null)"

    [ -n "$CFG_useFlatpak" ] && USE_FLATPAK="$CFG_useFlatpak"
    [ -n "$CFG_useGamescope" ] && USE_GAMESCOPE="$CFG_useGamescope"
    [ -n "$CFG_gamescopeResolution" ] && GAMESCOPE_RESOLUTION="$CFG_gamescopeResolution"
    [ -n "$CFG_gamescopeRefreshRate" ] && GAMESCOPE_REFRESH_RATE="$CFG_gamescopeRefreshRate"
    [ -n "$CFG_gamescopeFullscreen" ] && GAMESCOPE_FULLSCREEN="$CFG_gamescopeFullscreen"
    [ -n "$CFG_nvidiaOffload" ] && NVIDIA_OFFLOAD="$CFG_nvidiaOffload"
    [ -n "$CFG_gamescopeArgs" ] && GAMESCOPE_ARGS="$CFG_gamescopeArgs"
    [ -n "$CFG_reopenNormalCmd" ] && REOPEN_NORMAL_CMD="$CFG_reopenNormalCmd"
    [ -n "$CFG_extraStartCmd" ] && EXTRA_START_CMD="$CFG_extraStartCmd"
    [ -n "$CFG_extraStopCmd" ] && EXTRA_STOP_CMD="$CFG_extraStopCmd"
    [ -n "$CFG_enableAudioRouting" ] && ENABLE_AUDIO_ROUTING="$CFG_enableAudioRouting"
    [ -n "$CFG_targetAudio" ] && TARGET_AUDIO="$CFG_targetAudio"
    [ -n "$CFG_targetVolume" ] && TARGET_VOLUME="$CFG_targetVolume"
    [ -n "$CFG_audioSearchAttempts" ] && AUDIO_SEARCH_ATTEMPTS="$CFG_audioSearchAttempts"
    [ -z "$CFG_audioSearchAttempts" ] && [ -n "$CFG_maxAudioIntentos" ] && AUDIO_SEARCH_ATTEMPTS="$CFG_maxAudioIntentos"
fi

# Set Steam executable and kill command depending on Flatpak option
if [ "$USE_FLATPAK" = "true" ]; then
    STEAM_BIN="flatpak run com.valvesoftware.Steam"
    KILL_CMD="flatpak kill com.valvesoftware.Steam; pkill -x gamescope"
else
    STEAM_BIN="steam"
    KILL_CMD="pkill -x -TERM steam || pkill -x steam; pkill -x -TERM gamescope || pkill -x gamescope"
fi

# Helper for dms/dux IPC
dms_ipc() {
    if command -v dms &>/dev/null; then
        dms ipc "$@"
    elif command -v dux &>/dev/null; then
        dux ipc "$@"
    fi
}

# Safely switches audio output and sets volume to target device without rapid cycling
set_audio() {
    [ "$ENABLE_AUDIO_ROUTING" != "true" ] && return
    [ -z "$TARGET_AUDIO" ] && return

    # Allow PipeWire and Steam to settle first before touching audio sinks
    sleep 3

    log "set_audio: Target device '$TARGET_AUDIO' with volume '$TARGET_VOLUME'"

    # Try pactl directly if available to switch sink without rapid re-enumeration
    if command -v pactl &>/dev/null; then
        local target_sink
        target_sink=$(pactl list short sinks 2>/dev/null | grep -i "$TARGET_AUDIO" | awk '{print $2}' | head -n 1)
        if [ -n "$target_sink" ]; then
            log "set_audio: Found sink via pactl '$target_sink', setting as default"
            pactl set-default-sink "$target_sink" 2>/dev/null
            pactl set-sink-volume "$target_sink" "${TARGET_VOLUME}%" 2>/dev/null
            return
        fi
    fi

    # Fallback to bounded dms ipc cycle with conservative delay
    local attempt=0
    while [ $attempt -lt "$AUDIO_SEARCH_ATTEMPTS" ]; do
        local output_device
        output_device=$(dms_ipc call audio cycleoutput 2>/dev/null)
        log "set_audio: Attempt $((attempt+1)) - cycleoutput: '$output_device'"
        if [[ "$output_device" == *"$TARGET_AUDIO"* ]]; then
            log "set_audio: Target device found. Setting volume to $TARGET_VOLUME"
            dms_ipc call audio setvolume "$TARGET_VOLUME" 2>/dev/null
            break
        fi
        ((attempt++))
        sleep 0.5
    done
}

# Build Gamescope command and arguments when enabled
build_start_cmd() {
    if [ "$USE_GAMESCOPE" != "true" ]; then
        echo "$STEAM_BIN -gamepadui"
        return
    fi

    if ! command -v gamescope &>/dev/null; then
        log "WARNING: gamescope executable not found in PATH."
    fi

    local gs_flags=""

    # Apply resolution preset
    case "$GAMESCOPE_RESOLUTION" in
        "1080p") gs_flags="-W 1920 -H 1080" ;;
        "1440p") gs_flags="-W 2560 -H 1440" ;;
        "4k")    gs_flags="-W 3840 -H 2160" ;;
        "720p")  gs_flags="-W 1280 -H 720" ;;
        *)       gs_flags="" ;;
    esac

    # Apply refresh rate preset
    if [ -n "$GAMESCOPE_REFRESH_RATE" ] && [ "$GAMESCOPE_REFRESH_RATE" != "default" ]; then
        gs_flags="$gs_flags -r $GAMESCOPE_REFRESH_RATE"
    fi

    # Apply fullscreen preset
    if [ "$GAMESCOPE_FULLSCREEN" = "true" ]; then
        if [[ "$GAMESCOPE_ARGS" != *"-f"* ]] && [[ "$GAMESCOPE_ARGS" != *"-b"* ]]; then
            gs_flags="$gs_flags -f"
        fi
    fi

    # Combine preset flags with user-supplied custom args
    local all_gs_args="${gs_flags# } $GAMESCOPE_ARGS"
    all_gs_args="$(echo "$all_gs_args" | xargs)"

    # Check for NVIDIA offload
    local gpu_env=""
    local use_nvidia=false

    if [ "$NVIDIA_OFFLOAD" = "force" ]; then
        use_nvidia=true
    elif [ "$NVIDIA_OFFLOAD" = "auto" ]; then
        if [ -f "/proc/driver/nvidia/version" ] || command -v nvidia-smi &>/dev/null; then
            use_nvidia=true
        elif command -v lspci &>/dev/null && lspci 2>/dev/null | grep -qi nvidia; then
            use_nvidia=true
        fi
    fi

    if [ "$use_nvidia" = "true" ]; then
        gpu_env="env __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia"
    fi

    if [ -n "$all_gs_args" ]; then
        if [ -n "$gpu_env" ]; then
            echo "gamescope $all_gs_args -- $gpu_env $STEAM_BIN -gamepadui"
        else
            echo "gamescope $all_gs_args -- $STEAM_BIN -gamepadui"
        fi
    else
        if [ -n "$gpu_env" ]; then
            echo "gamescope -- $gpu_env $STEAM_BIN -gamepadui"
        else
            echo "gamescope -- $STEAM_BIN -gamepadui"
        fi
    fi
}

# Spawns background process completely detached from Quickshell/dms
launch_detached() {
    local cmd="$1"
    log "launch_detached: Starting '$cmd'"
    nohup setsid bash -c "$cmd" </dev/null >> "$LOG_FILE" 2>&1 &
    disown $! 2>/dev/null
}

case "$ACTION" in
    start)
        # Clear log on fresh start
        > "$LOG_FILE"
        START_CMD="$(build_start_cmd)"

        log "=== Starting Steam Big Picture ==="
        log "Settings: USE_FLATPAK=$USE_FLATPAK, USE_GAMESCOPE=$USE_GAMESCOPE, RESOLUTION=$GAMESCOPE_RESOLUTION, REFRESH=$GAMESCOPE_REFRESH_RATE, AUDIO_ENABLED=$ENABLE_AUDIO_ROUTING, TARGET_AUDIO='$TARGET_AUDIO'"
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

        # Launch Steam/Gamescope completely detached using nohup setsid & disown
        launch_detached "$START_CMD"

        # Launch monitor detached
        launch_detached "$0 monitor"

        # Optional audio routing (runs in background with settle delay)
        if [ "$ENABLE_AUDIO_ROUTING" = "true" ] && [ -n "$TARGET_AUDIO" ]; then
            log "Queueing set_audio in background"
            set_audio &
        fi
        ;;
    stop)
        log "=== Stopping Steam Big Picture ==="
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
    monitor)
        # Background loop that waits for Steam to start, and runs cleanup commands when it exits
        log "Monitor: Waiting for Steam to start (timeout 25s)..."
        start_timeout=25
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
            sleep 3
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
