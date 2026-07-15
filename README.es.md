# Plugin Steam Big Picture Toggle

Un plugin de tipo widget para **DankMaterialShell** (DMS) que proporciona un interruptor para ejecutar Steam en modo Big Picture con configuraciones personalizadas, ajustes de Gamescope y enrutamiento automático de audio.

## Características

- **Alternar Steam Big Picture**: Inicia y detén fácilmente el modo Big Picture de Steam desde tu barra de herramientas o el panel de control.
- **Soporte para Flatpak y Nativo**: Permite ejecutar Steam tanto de forma nativa como a través de Flatpak.
- **Integración con Gamescope**: Ejecuta Steam dentro de Gamescope con opciones personalizadas de pantalla (se optimiza automáticamente para GPUs NVIDIA mediante variables de entorno *prime offload*).
- **Comandos Adicionales (Hooks)**: Ejecuta comandos de shell personalizados al iniciar y cerrar Steam (por ejemplo, cambiar perfiles de monitor usando `dms ipc`).
- **Enrutamiento de Audio Automatizado**: Recorre los dispositivos de salida de audio al iniciar para encontrar un dispositivo específico (por ejemplo, tu TV) y configurar su volumen.
- **Reabrir Steam Normal**: Reinicia opcionalmente Steam en modo de escritorio normal una vez que salgas de Big Picture.

## Opciones de Configuración

Configura estas opciones directamente en la interfaz de ajustes de DankMaterialShell:

- **Usar Flatpak**: Activa para ejecutar Steam mediante Flatpak (`com.valvesoftware.Steam`) o nativo.
- **Usar Gamescope**: Activa para ejecutar Steam dentro de Gamescope.
- **Argumentos de Gamescope**: Parámetros de ventana adicionales para Gamescope (ej. `-W 1920 -H 1080 -f -e`).
- **Comando al Cerrar**: Programa a ejecutar cuando Big Picture termine (ej. `steam` para reabrir la interfaz de escritorio).
- **Comandos Extra al Iniciar / Cerrar**: Scripts personalizados o comandos de `dms ipc` para ejecutar antes de iniciar o al detener Steam.
- **Dispositivo de Audio Objetivo / Volumen**: Busca entre las salidas de audio un dispositivo que coincida con parte de un nombre (ej. `HDMI` o `AD107`) y le asigna el volumen deseado.

## Arquitectura Interna

Este plugin está compuesto por dos partes principales:
1. **`SteamToggle.qml` y `SteamToggleSettings.qml`**: Renderizan el widget de la interfaz, el menú emergente y gestionan la configuración visual.
2. **`steam_toggle.sh`**: Script de control ejecutado en segundo plano que administra el lanzamiento, monitoreo y limpieza de los procesos de Steam. Lee directamente los ajustes guardados por DMS (`~/.config/DankMaterialShell/plugin_settings.json`).
