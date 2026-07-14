#!/bin/bash
# Control script for Steam Toggle plugin

CONFIG_FILE="$(dirname "$0")/steam_toggle.conf"

# Default configuration values
USE_FLATPAK=false
USE_GAMESCOPE=false
GAMESCOPE_ARGS="-W 1920 -H 1080 -f -e"
REOPEN_NORMAL_CMD="steam"
EXTRA_START_CMD=""
EXTRA_STOP_CMD=""

# Load user configuration override if exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Dynamically set commands based on configuration
if [ "$USE_FLATPAK" = true ]; then
    STEAM_BIN="flatpak run com.valvesoftware.Steam"
    KILL_CMD="flatpak kill com.valvesoftware.Steam"
else
    STEAM_BIN="steam"
    KILL_CMD="pkill -TERM steam"
fi

if [ "$USE_GAMESCOPE" = true ]; then
    START_CMD="gamescope $GAMESCOPE_ARGS -- env __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia $STEAM_BIN -gamepadui"
else
    START_CMD="$STEAM_BIN -tenfoot -fullscreen"
fi

is_running() {
    pgrep -x "steam" > /dev/null || pgrep -x "steamwebhelper" > /dev/null
}

case "$1" in
    start)
        # Kill any active monitoring daemon
        pkill -f "steam_toggle.sh monitor" 2>/dev/null

        if is_running; then
            echo "Cerrando instancia previa de Steam..."
            eval "$KILL_CMD"
            sleep 2
        fi

        if [ -n "$EXTRA_START_CMD" ]; then
            echo "Ejecutando comando de inicio extra..."
            eval "$EXTRA_START_CMD"
        fi

        echo "Iniciando Steam..."
        eval "$START_CMD" &

        # Launch the background monitoring process
        "$0" monitor > /dev/null 2>&1 &
        ;;
    stop)
        # Kill the monitoring process so it doesn't trigger reopen
        pkill -f "steam_toggle.sh monitor" 2>/dev/null

        echo "Cerrando Steam..."
        eval "$KILL_CMD"

        if [ -n "$EXTRA_STOP_CMD" ]; then
            echo "Ejecutando comando de detencion extra..."
            eval "$EXTRA_STOP_CMD"
        fi
        ;;
    status)
        if is_running; then
            echo "running"
            exit 0
        else
            echo "stopped"
            exit 1
        fi
        ;;
    monitor)
        # Wait for Steam to launch
        sleep 5
        while is_running; do
            sleep 2
        done
        
        echo "Steam finalizado de manera externa. Restaurando configuracion..."
        if [ -n "$EXTRA_STOP_CMD" ]; then
            eval "$EXTRA_STOP_CMD"
        fi
        if [ -n "$REOPEN_NORMAL_CMD" ]; then
            eval "$REOPEN_NORMAL_CMD" &
        fi
        ;;
    set_config)
        key="$2"
        val="$3"
        if [ -z "$key" ]; then
            echo "Error: se requiere una clave"
            exit 1
        fi
        if grep -q -E "^${key}=" "$CONFIG_FILE" 2>/dev/null; then
            escaped_val=$(echo "$val" | sed 's/\//\\\//g')
            sed -i "s/^${key}=.*/${key}=\"${escaped_val}\"/" "$CONFIG_FILE"
        else
            echo "${key}=\"${val}\"" >> "$CONFIG_FILE"
        fi
        echo "Configuracion actualizada: ${key}=${val}"
        ;;
    *)
        echo "Uso: $0 {start|stop|status|monitor|set_config}"
        exit 1
        ;;
esac
