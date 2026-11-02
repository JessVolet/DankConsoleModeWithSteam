import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets
import qs.DCommon.Widgets

PluginSettings {
    id: root
    pluginId: "dankConsoleSteam"

    StyledText {
        width: parent.width
        text: "Steam Big Picture Settings"
        font.pixelSize: Theme.fontSizeLarge + 2
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Configure launch mode, Gamescope presets, audio routing, and lifecycle commands."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.withAlpha(Theme.outlineStrong, 0.35)
    }

    StyledText {
        width: parent.width
        text: "Launch Mode"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    ToggleSetting {
        settingKey: "useFlatpak"
        label: "Use Flatpak"
        description: "Run Steam using Flatpak (com.valvesoftware.Steam)"
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "useGamescope"
        label: "Use Gamescope"
        description: "Run Steam Big Picture inside the Gamescope micro-compositor"
        defaultValue: false
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.withAlpha(Theme.outlineStrong, 0.35)
    }

    StyledText {
        width: parent.width
        text: "Gamescope & Display"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    SelectionSetting {
        settingKey: "gamescopeResolution"
        label: "Resolution Preset"
        description: "Set render resolution or use custom arguments"
        options: [
            { label: "Custom (from Arguments)", value: "custom" },
            { label: "1080p (1920x1080)", value: "1080p" },
            { label: "1440p (2560x1440)", value: "1440p" },
            { label: "4K (3840x2160)", value: "4k" },
            { label: "720p (1280x720)", value: "720p" }
        ]
        defaultValue: "custom"
    }

    SelectionSetting {
        settingKey: "gamescopeRefreshRate"
        label: "Refresh Rate"
        description: "Target display refresh rate (-r)"
        options: [
            { label: "Default / Uncapped", value: "default" },
            { label: "60 Hz", value: "60" },
            { label: "120 Hz", value: "120" },
            { label: "144 Hz", value: "144" },
            { label: "165 Hz", value: "165" },
            { label: "240 Hz", value: "240" }
        ]
        defaultValue: "default"
    }

    ToggleSetting {
        settingKey: "gamescopeFullscreen"
        label: "Fullscreen Mode"
        description: "Run Gamescope in fullscreen mode (-f)"
        defaultValue: true
    }

    SelectionSetting {
        settingKey: "nvidiaOffload"
        label: "NVIDIA Prime Offload"
        description: "GPU render offload when Gamescope is active"
        options: [
            { label: "Auto-detect NVIDIA GPU", value: "auto" },
            { label: "Force NVIDIA Offload", value: "force" },
            { label: "Disabled / Integrated GPU", value: "off" }
        ]
        defaultValue: "auto"
    }

    StringSetting {
        settingKey: "gamescopeArgs"
        label: "Additional Gamescope Arguments"
        description: "Custom flags passed directly to Gamescope (e.g., -b --force-grab-cursor)"
        defaultValue: ""
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.withAlpha(Theme.outlineStrong, 0.35)
    }

    StyledText {
        width: parent.width
        text: "Audio Routing"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    ToggleSetting {
        settingKey: "enableAudioRouting"
        label: "Enable Audio Routing"
        description: "Automatically cycle audio outputs and set volume when Steam launches"
        defaultValue: false
    }

    StringSetting {
        settingKey: "targetAudio"
        label: "Target Audio Device"
        description: "Part of the audio device name to switch to (e.g., HDMI, TV, AD107)"
        defaultValue: ""
    }

    SliderSetting {
        settingKey: "targetVolume"
        label: "Target Volume"
        description: "Desired volume level for the audio device"
        minimum: 0
        maximum: 100
        unit: "%"
        defaultValue: 100
    }

    SliderSetting {
        settingKey: "audioSearchAttempts"
        label: "Audio Search Attempts"
        description: "Maximum attempts when searching for target audio output"
        minimum: 1
        maximum: 30
        defaultValue: 10
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.withAlpha(Theme.outlineStrong, 0.35)
    }

    StyledText {
        width: parent.width
        text: "Lifecycle Commands"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StringSetting {
        settingKey: "reopenNormalCmd"
        label: "Command on Close"
        description: "Command to reopen desktop Steam when Big Picture exits (e.g., steam)"
        defaultValue: ""
    }

    StringSetting {
        settingKey: "extraStartCmd"
        label: "Extra Startup Command"
        description: "Command executed before launching Steam (e.g., change display profile)"
        defaultValue: ""
    }

    StringSetting {
        settingKey: "extraStopCmd"
        label: "Extra Shutdown Command"
        description: "Command executed after Steam exits (e.g., restore display profile)"
        defaultValue: ""
    }
}
