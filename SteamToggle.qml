import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    readonly property string scriptPath: Qt.resolvedUrl("steam_toggle.sh").toString().replace("file://", "")
    property bool isRunning: false

    // Config variables (loaded dynamically from plugin settings)
    property bool useFlatpak: pluginData.useFlatpak ?? false
    property bool useGamescope: pluginData.useGamescope ?? true
    property string gamescopeArgs: pluginData.gamescopeArgs ?? ""
    property string reopenNormalCmd: pluginData.reopenNormalCmd ?? ""
    property string extraStartCmd: pluginData.extraStartCmd ?? "dms ipc outputs setProfile BigPicture"
    property string extraStopCmd: pluginData.extraStopCmd ?? "dms ipc outputs setProfile Main"
    property string targetAudio: pluginData.targetAudio ?? "AD107"
    property int targetVolume: pluginData.targetVolume ?? 100
    property int maxAudioIntentos: pluginData.maxAudioIntentos ?? 10

    layerNamespacePlugin: "steam-toggle"
    popoutWidth: 320
    popoutHeight: 180

    ccWidgetIcon: "sports_esports"
    ccWidgetPrimaryText: "Big Picture"
    ccWidgetSecondaryText: isRunning ? "Iniciado" : "Detenido"
    ccWidgetIsActive: isRunning

    function getArgs() {
        return [
            root.useFlatpak ? "true" : "false",
            root.useGamescope ? "true" : "false",
            root.gamescopeArgs,
            root.reopenNormalCmd,
            root.extraStartCmd,
            root.extraStopCmd,
            root.targetAudio,
            root.targetVolume.toString(),
            root.maxAudioIntentos.toString()
        ];
    }

    Timer {
        id: statusTimer
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statusProcess.running = true
    }

    Process {
        id: statusProcess
        command: [root.scriptPath, "status"]
        running: false
        onExited: (exitCode) => {
            root.isRunning = (exitCode === 0);
        }
    }

    onCcWidgetToggled: {
        if (!isRunning) {
            Quickshell.execDetached([root.scriptPath, "start"].concat(getArgs()))
            ToastService.showInfo("Steam", "Iniciando Big Picture...")
            root.isRunning = true
        } else {
            Quickshell.execDetached([root.scriptPath, "stop"].concat(getArgs()))
            ToastService.showInfo("Steam", "Cerrando Steam...")
            root.isRunning = false
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popoutColumn
            headerText: "Steam Control"
            detailsText: root.isRunning ? "Steam está en ejecución" : "Steam está detenido"
            showCloseButton: true

            Column {
                width: parent.width - Theme.spacingM * 2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingM

                // Estado actual
                StyledRect {
                    width: parent.width
                    height: 50
                    color: Theme.surfaceContainerHigh

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingM
                        spacing: Theme.spacingM

                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: root.isRunning ? Theme.primary : Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            StyledText {
                                text: root.isRunning ? "Steam Big Picture activo" : "Steam inactivo"
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }

                            StyledText {
                                text: root.useFlatpak ? "Modo: Flatpak" : "Modo: Nativo"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }
                        }
                    }
                }

                // Botones de acción
                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    // Botón Iniciar
                    StyledRect {
                        width: (parent.width - Theme.spacingS) / 2
                        height: 40
                        radius: Theme.cornerRadius
                        color: startBtnMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                        border.width: 1
                        border.color: root.isRunning ? Theme.outline : Theme.primary

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS

                            DankIcon {
                                name: "play_arrow"
                                size: 18
                                color: root.isRunning ? Theme.surfaceVariantText : Theme.primary
                            }

                            StyledText {
                                text: "Iniciar"
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Bold
                                color: root.isRunning ? Theme.surfaceVariantText : Theme.primary
                            }
                        }

                        MouseArea {
                            id: startBtnMouse
                            anchors.fill: parent
                            hoverEnabled: !root.isRunning
                            cursorShape: root.isRunning ? Qt.ArrowCursor : Qt.PointingHandCursor
                            enabled: !root.isRunning
                            onClicked: {
                                Quickshell.execDetached([root.scriptPath, "start"].concat(root.getArgs()))
                                ToastService.showInfo("Steam", "Iniciando Big Picture...")
                                root.isRunning = true
                                popoutColumn.closePopout()
                            }
                        }
                    }

                    // Botón Detener
                    StyledRect {
                        width: (parent.width - Theme.spacingS) / 2
                        height: 40
                        radius: Theme.cornerRadius
                        color: stopBtnMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                        border.width: 1
                        border.color: !root.isRunning ? Theme.outline : Theme.error

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS

                            DankIcon {
                                name: "stop"
                                size: 18
                                color: !root.isRunning ? Theme.surfaceVariantText : Theme.error
                            }

                            StyledText {
                                text: "Detener"
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Bold
                                color: !root.isRunning ? Theme.surfaceVariantText : Theme.error
                            }
                        }

                        MouseArea {
                            id: stopBtnMouse
                            anchors.fill: parent
                            hoverEnabled: root.isRunning
                            cursorShape: !root.isRunning ? Qt.ArrowCursor : Qt.PointingHandCursor
                            enabled: root.isRunning
                            onClicked: {
                                Quickshell.execDetached([root.scriptPath, "stop"].concat(root.getArgs()))
                                ToastService.showInfo("Steam", "Cerrando Steam...")
                                root.isRunning = false
                                popoutColumn.closePopout()
                            }
                        }
                    }
                }
            }
        }
    }

    horizontalBarPill: Component {
        Row {
            DankIcon { 
                name: "sports_esports"
                color: root.isRunning ? Theme.primary : Theme.surfaceVariantText 
            }
        }
    }

    verticalBarPill: Component {
        Column {
            DankIcon { 
                name: "sports_esports"
                color: root.isRunning ? Theme.primary : Theme.surfaceVariantText 
            }
        }
    }
}
