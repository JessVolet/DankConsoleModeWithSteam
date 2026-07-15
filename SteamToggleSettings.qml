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

    ToggleSetting {
        settingKey: "useFlatpak"
        label: "Use Flatpak"
        description: "Run Steam using Flatpak"
    }

    ToggleSetting {
        settingKey: "useGamescope"
        label: "Use Gamescope"
        description: "Run Steam in Big Picture mode inside Gamescope"
    }

    StringSetting {
        settingKey: "gamescopeArgs"
        label: "Gamescope Arguments"
        description: "Additional arguments for Gamescope (e.g., -W 1920 -H 1080 -f -e)"
    }

    StringSetting {
        settingKey: "reopenNormalCmd"
        label: "Command on Close"
        description: "Command to reopen normal Steam when Big Picture closes (e.g., steam)"
    }

    StringSetting {
        settingKey: "extraStartCmd"
        label: "Extra Startup Command"
        description: "Extra command executed before starting Big Picture"
    }

    StringSetting {
        settingKey: "extraStopCmd"
        label: "Extra Shutdown Command"
        description: "Extra command executed when Steam closes to restore settings"
    }

    StringSetting {
        settingKey: "targetAudio"
        label: "Target Audio Device"
        description: "Part of the audio device name to search for (e.g., AD107)"
    }

    SliderSetting {
        settingKey: "targetVolume"
        label: "Target Volume"
        description: "Desired volume for the audio device"
        minimum: 0
        maximum: 100
        unit: "%"
    }

    SliderSetting {
        settingKey: "maxAudioIntentos"
        label: "Search Attempts"
        description: "Maximum number of attempts to find the audio device"
        minimum: 1
        maximum: 30
    }
}
