#!/bin/bash
# Control script for Steam Toggle plugin (Optimized with Audio features)

export ACTION="$1"
export USE_FLATPAK="${2:-false}"
export USE_GAMESCOPE="${3:-false}"
export GAMESCOPE_ARGS="$4"
export REOPEN_NORMAL_CMD="$5"
export EXTRA_START_CMD="$6"
export EXTRA_STOP_CMD="$7"
export TARGET_AUDIO="$8"
export TARGET_VOLUME="${9:-100}"
export MAX_AUDIO_INTENTOS="${10:-10}"

if [ "$USE_FLATPAK" = "true" ]; then
    STEAM_BIN="flatpak run com.valvesoftware.Steam"
    KILL_CMD="flatpak kill com.valvesoftware.Steam"
else
    STEAM_BIN="steam"
    KILL_CMD="pkill -TERM steam"
fi

if [ "$USE_GAMESCOPE" = "true" ]; then
    START_CMD="gamescope $GAMESCOPE_ARGS -- env __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia $STEAM_BIN -gamepadui"
else
    START_CMD="$STEAM_BIN -tenfoot -fullscreen"
fi

is_running() {
    pgrep -x "steam" > /dev/null || pgrep -x "steamwebhelper" > /dev/null
}

set_audio() {
    [ -z "$TARGET_AUDIO" ] && return
    local intento=0
    while [ $intento -lt "$MAX_AUDIO_INTENTOS" ]; do
        local salida
        salida=$(dms ipc call audio cycleoutput 2>/dev/null)
        if [[ "$salida" == *"$TARGET_AUDIO"* ]]; then
            dms ipc call audio setvolume "$TARGET_VOLUME" 2>/dev/null
            break
        fi
        ((intento++))
        sleep 0.2
    done
}

case "$ACTION" in
    start)
        pkill -f "steam_toggle.sh monitor" 2>/dev/null
        if is_running; then
            eval "$KILL_CMD"
            sleep 2
        fi
        [ -n "$EXTRA_START_CMD" ] && eval "$EXTRA_START_CMD"
        set_audio &
        sleep 5
        eval "$START_CMD" &
        "$0" monitor > /dev/null 2>&1 &
        ;;
    stop)
        pkill -f "steam_toggle.sh monitor" 2>/dev/null
        eval "$KILL_CMD"
        [ -n "$EXTRA_STOP_CMD" ] && eval "$EXTRA_STOP_CMD"
        ;;
    status)
        is_running && exit 0 || exit 1
        ;;
    monitor)
        sleep 5
        while is_running; do
            sleep 2
        done
        [ -n "$EXTRA_STOP_CMD" ] && eval "$EXTRA_STOP_CMD"
        [ -n "$REOPEN_NORMAL_CMD" ] && eval "$REOPEN_NORMAL_CMD" &
        ;;
    *)
        echo "Usage: $0 {start|stop|status|monitor}"
        exit 1
        ;;
esac
