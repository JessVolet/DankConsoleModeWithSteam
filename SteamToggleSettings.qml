import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "steamToggle"

    StyledText {
        width: parent.width
        text: "Steam Big Picture Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "pues bueno, abre steam en codigo."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    ToggleSetting {
        settingKey: "useFlatpak"
        label: "Usar Flatpak"
        description: "Ejecutar Steam utilizando Flatpak"
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "useGamescope"
        label: "Usar Gamescope"
        description: "Ejecutar Steam en modo Big Picture dentro de Gamescope"
        defaultValue: true
    }

    StringSetting {
        settingKey: "gamescopeArgs"
        label: "Argumentos de Gamescope"
        description: "Argumentos adicionales para Gamescope (ej. -W 1920 -H 1080 -f -e)"
        defaultValue: ""
    }

    StringSetting {
        settingKey: "reopenNormalCmd"
        label: "Comando al Cerrar"
        description: "Comando para reabrir Steam normal cuando se cierre Big Picture (ej. steam)"
        defaultValue: ""
    }

    StringSetting {
        settingKey: "extraStartCmd"
        label: "Comando Extra al Iniciar"
        description: "Comando extra ejecutado antes de iniciar Big Picture"
        defaultValue: "dms ipc outputs setProfile BigPicture"
    }

    StringSetting {
        settingKey: "extraStopCmd"
        label: "Comando Extra al Cerrar"
        description: "Comando extra ejecutado al cerrarse Steam para restaurar configuraciones"
        defaultValue: "dms ipc outputs setProfile Main"
    }
}
