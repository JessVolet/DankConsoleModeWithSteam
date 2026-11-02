import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.DCommon.Widgets
import qs.Modules.Plugins
import "./components"

PluginComponent {
    id: root

    readonly property string scriptPath: Qt.resolvedUrl("steam_toggle.sh").toString().replace("file://", "")
    property bool isRunning: false
    property string transitionState: "" // "starting", "stopping", or ""

    // Reactive properties from pluginData
    readonly property bool useFlatpak: pluginData.useFlatpak === true
    readonly property bool useGamescope: pluginData.useGamescope === true
    readonly property string gamescopeResolution: pluginData.gamescopeResolution || "custom"
    readonly property string gamescopeRefreshRate: pluginData.gamescopeRefreshRate || "default"
    readonly property bool gamescopeFullscreen: pluginData.gamescopeFullscreen !== false
    readonly property bool enableAudioRouting: pluginData.enableAudioRouting === true
    readonly property string targetAudio: pluginData.targetAudio || ""
    readonly property int targetVolume: pluginData.targetVolume !== undefined ? pluginData.targetVolume : 100

    layerNamespacePlugin: "steam-toggle"
    popoutWidth: 360
    popoutHeight: 0 // Content-driven height

    ccWidgetIcon: "sports_esports"
    ccWidgetPrimaryText: "Big Picture"
    ccWidgetSecondaryText: transitionState === "starting" ? "Starting..." :
                           transitionState === "stopping" ? "Stopping..." :
                           isRunning ? "Active" : "Stopped"
    ccWidgetIsActive: isRunning

    // Adaptive polling: fast during transition, responsive when popout is open, relaxed when idle
    Timer {
        id: statusTimer
        interval: root.transitionState !== "" ? 2000 : (root.interactionActive ? 3000 : 15000)
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!statusProcess.running) {
                statusProcess.running = true
            }
        }
    }

    // Safety timeout to clear transition state if Steam takes too long
    Timer {
        id: transitionTimeout
        interval: 25000
        onTriggered: root.transitionState = ""
    }

    Process {
        id: statusProcess
        command: [root.scriptPath, "status"]
        running: false
        onExited: (exitCode) => {
            var active = (exitCode === 0)
            root.isRunning = active
            if (root.transitionState === "starting" && active) {
                root.transitionState = ""
                transitionTimeout.stop()
            } else if (root.transitionState === "stopping" && !active) {
                root.transitionState = ""
                transitionTimeout.stop()
            }
        }
    }

    function startSteam() {
        if (root.transitionState !== "") return
        root.transitionState = "starting"
        transitionTimeout.restart()
        Quickshell.execDetached([root.scriptPath, "start"])
        ToastService.showInfo("Steam", "Starting Steam Big Picture...")
    }

    function stopSteam() {
        if (root.transitionState !== "") return
        root.transitionState = "stopping"
        transitionTimeout.restart()
        Quickshell.execDetached([root.scriptPath, "stop"])
        ToastService.showInfo("Steam", "Closing Steam...")
    }

    function toggleSetting(key, currentVal) {
        var nextVal = !currentVal
        if (root.pluginService) {
            root.pluginService.savePluginData(root.pluginId, key, nextVal)
        }
    }

    function openSettings() {
        try {
            if (typeof PopoutService !== "undefined" && typeof SettingsTabs !== "undefined") {
                PopoutService.openSettingsWithTab(SettingsTabs.pluginPage(root.pluginId).id)
            }
        } catch (e) {
            // Fallback gracefully if service is absent
        }
    }

    onCcWidgetToggled: {
        if (!isRunning) {
            startSteam()
        } else {
            stopSteam()
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popoutContainer
            headerText: "Steam Control"
            detailsText: root.transitionState === "starting" ? "Launching Big Picture mode..." :
                         root.transitionState === "stopping" ? "Terminating Steam session..." :
                         root.isRunning ? "Steam session is active" : "Steam session is stopped"
            showCloseButton: true

            ColumnLayout {
                width: parent.width - Theme.spacingM * 2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingM

                // Modular Status Header
                StatusHeader {
                    isRunning: root.isRunning
                    transitionState: root.transitionState
                    useFlatpak: root.useFlatpak
                    useGamescope: root.useGamescope
                    onSettingsClicked: {
                        popoutContainer.closePopout()
                        root.openSettings()
                    }
                }

                // Modular Interactive Mode Switchers
                ModeSwitchers {
                    isRunning: root.isRunning
                    transitionState: root.transitionState
                    useGamescope: root.useGamescope
                    useFlatpak: root.useFlatpak
                    gamescopeResolution: root.gamescopeResolution
                    onToggleGamescope: root.toggleSetting("useGamescope", root.useGamescope)
                    onToggleFlatpak: root.toggleSetting("useFlatpak", root.useFlatpak)
                }

                // Modular Preset & Audio Summary
                PresetSummary {
                    useGamescope: root.useGamescope
                    gamescopeResolution: root.gamescopeResolution
                    gamescopeRefreshRate: root.gamescopeRefreshRate
                    gamescopeFullscreen: root.gamescopeFullscreen
                    enableAudioRouting: root.enableAudioRouting
                    targetAudio: root.targetAudio
                    targetVolume: root.targetVolume
                }

                // Modular Dynamic Action Hero Button
                ActionControl {
                    isRunning: root.isRunning
                    transitionState: root.transitionState
                    onActionTriggered: {
                        if (root.isRunning) {
                            root.stopSteam()
                        } else {
                            root.startSteam()
                        }
                        popoutContainer.closePopout()
                    }
                }
            }
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS
            DIcon {
                name: "sports_esports"
                size: Theme.iconSize
                color: root.transitionState !== "" ? Theme.warning :
                       root.isRunning ? Theme.primary : (Theme.widgetIconColor || Theme.surfaceVariantText)
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS
            DIcon {
                name: "sports_esports"
                size: Theme.iconSize
                color: root.transitionState !== "" ? Theme.warning :
                       root.isRunning ? Theme.primary : (Theme.widgetIconColor || Theme.surfaceVariantText)
            }
        }
    }
}
