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

    // Config variables
    property bool isFlatpak: false
    property bool isGamescope: false
    property string gamescopeArgs: ""
    property string reopenNormalCmd: ""
    property string extraStartCmd: ""
    property string extraStopCmd: ""

    // UI state
    property bool showSettingsView: false

    layerNamespacePlugin: "steam-toggle"
    popoutWidth: 350
    popoutHeight: 480

    ccWidgetIcon: "sports_esports"
    ccWidgetPrimaryText: "Big Picture"
    ccWidgetSecondaryText: isRunning ? "Iniciado" : "Detenido"
    ccWidgetIsActive: isRunning

    function loadConfigFromFile() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", Qt.resolvedUrl("steam_toggle.conf"), false);
        try {
            xhr.send(null);
            if (xhr.status === 200 || xhr.status === 0) {
                var lines = xhr.responseText.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.indexOf("#") === 0 || line.indexOf("=") === -1) continue;
                    var parts = line.split("=");
                    var key = parts[0].trim();
                    var val = parts.slice(1).join("=").trim();
                    if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
                        val = val.substring(1, val.length - 1);
                    }
                    if (key === "USE_FLATPAK") root.isFlatpak = (val === "true");
                    else if (key === "USE_GAMESCOPE") root.isGamescope = (val === "true");
                    else if (key === "GAMESCOPE_ARGS") root.gamescopeArgs = val;
                    else if (key === "REOPEN_NORMAL_CMD") root.reopenNormalCmd = val;
                    else if (key === "EXTRA_START_CMD") root.extraStartCmd = val;
                    else if (key === "EXTRA_STOP_CMD") root.extraStopCmd = val;
                }
            }
        } catch (e) {
            console.log("Error cargando steam_toggle.conf: " + e);
        }
    }

    function saveConfigValue(key, value) {
        Quickshell.execDetached([root.scriptPath, "set_config", key, value]);
    }

    Component.onCompleted: {
        loadConfigFromFile();
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
            Quickshell.execDetached([root.scriptPath, "start"])
            ToastService.showInfo("Steam", "Iniciando Big Picture...")
            root.isRunning = true
        } else {
            Quickshell.execDetached([root.scriptPath, "stop"])
            ToastService.showInfo("Steam", "Cerrando Steam...")
            root.isRunning = false
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popoutColumn
            headerText: root.showSettingsView ? "Ajustes de Steam" : "Steam Control"
            detailsText: root.showSettingsView ? "Configuración de ejecución" : (root.isRunning ? "Steam está en ejecución" : "Steam está detenido")
            showCloseButton: true

            // Cargar configuración al abrir el popout
            Component.onCompleted: {
                root.loadConfigFromFile();
                root.showSettingsView = false;
            }

            Column {
                width: parent.width - Theme.spacingM * 2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingM

                // --- VISTA PRINCIPAL ---
                Column {
                    width: parent.width
                    spacing: Theme.spacingM
                    visible: !root.showSettingsView

                    // Estado actual
                    StyledRect {
                        width: parent.width
                        height: 60
                        color: Theme.surfaceContainerHigh

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            spacing: Theme.spacingM

                            Rectangle {
                                width: 12
                                height: 12
                                radius: 6
                                color: root.isRunning ? Theme.primary : Theme.surfaceVariantText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                StyledText {
                                    text: root.isRunning ? "Steam Big Picture activo" : "Steam inactivo"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }

                                StyledText {
                                    text: root.isFlatpak ? "Modo: Flatpak" : "Modo: Nativo"
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
                            height: 48
                            radius: Theme.cornerRadius
                            color: startBtnMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                            border.width: 1
                            border.color: root.isRunning ? Theme.outline : Theme.primary

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.spacingXS

                                DankIcon {
                                    name: "play_arrow"
                                    size: 20
                                    color: root.isRunning ? Theme.surfaceVariantText : Theme.primary
                                }

                                StyledText {
                                    text: "Iniciar"
                                    font.pixelSize: Theme.fontSizeMedium
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
                                    Quickshell.execDetached([root.scriptPath, "start"])
                                    ToastService.showInfo("Steam", "Iniciando Big Picture...")
                                    root.isRunning = true
                                    popoutColumn.closePopout()
                                }
                            }
                        }

                        // Botón Detener
                        StyledRect {
                            width: (parent.width - Theme.spacingS) / 2
                            height: 48
                            radius: Theme.cornerRadius
                            color: stopBtnMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                            border.width: 1
                            border.color: !root.isRunning ? Theme.outline : Theme.error

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.spacingXS

                                DankIcon {
                                    name: "stop"
                                    size: 20
                                    color: !root.isRunning ? Theme.surfaceVariantText : Theme.error
                                }

                                StyledText {
                                    text: "Detener"
                                    font.pixelSize: Theme.fontSizeMedium
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
                                    Quickshell.execDetached([root.scriptPath, "stop"])
                                    ToastService.showInfo("Steam", "Cerrando Steam...")
                                    root.isRunning = false
                                    popoutColumn.closePopout()
                                }
                            }
                        }
                    }

                    // Botón para ir a Ajustes
                    StyledRect {
                        width: parent.width
                        height: 44
                        radius: Theme.cornerRadius
                        color: settingsBtnMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "settings"
                                size: 18
                                color: Theme.surfaceText
                            }

                            StyledText {
                                text: "Ajustes de Configuración"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }
                        }

                        MouseArea {
                            id: settingsBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.showSettingsView = true;
                            }
                        }
                    }
                }

                // --- VISTA DE CONFIGURACIÓN ---
                Column {
                    width: parent.width
                    spacing: Theme.spacingM
                    visible: root.showSettingsView

                    // Botón volver
                    StyledRect {
                        width: parent.width
                        height: 36
                        color: backBtnMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                        radius: Theme.cornerRadius

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "arrow_back"
                                size: 16
                                color: Theme.primary
                            }

                            StyledText {
                                text: "Volver al Control"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.primary
                                font.weight: Font.Bold
                            }
                        }

                        MouseArea {
                            id: backBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.showSettingsView = false;
                            }
                        }
                    }

                    // Contenedor scroleable de campos
                    Flickable {
                        width: parent.width
                        height: 310
                        contentHeight: scrollCol.implicitHeight
                        clip: true

                        Column {
                            id: scrollCol
                            width: parent.width
                            spacing: Theme.spacingM

                            // Toggle Flatpak
                            Row {
                                width: parent.width
                                spacing: Theme.spacingM

                                StyledText {
                                    text: "Usar versión Flatpak"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    width: parent.width - flatpakSwitch.width - Theme.spacingM
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    id: flatpakSwitch
                                    width: 44
                                    height: 24
                                    radius: 12
                                    color: root.isFlatpak ? Theme.primary : Theme.surfaceVariant
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: "white"
                                        x: root.isFlatpak ? 24 : 2
                                        y: 3
                                        Behavior on x { NumberAnimation { duration: 150 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.isFlatpak = !root.isFlatpak;
                                            root.saveConfigValue("USE_FLATPAK", root.isFlatpak ? "true" : "false");
                                        }
                                    }
                                }
                            }

                            // Toggle Gamescope
                            Row {
                                width: parent.width
                                spacing: Theme.spacingM

                                StyledText {
                                    text: "Usar Gamescope"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    width: parent.width - gamescopeSwitch.width - Theme.spacingM
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    id: gamescopeSwitch
                                    width: 44
                                    height: 24
                                    radius: 12
                                    color: root.isGamescope ? Theme.primary : Theme.surfaceVariant
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: "white"
                                        x: root.isGamescope ? 24 : 2
                                        y: 3
                                        Behavior on x { NumberAnimation { duration: 150 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.isGamescope = !root.isGamescope;
                                            root.saveConfigValue("USE_GAMESCOPE", root.isGamescope ? "true" : "false");
                                        }
                                    }
                                }
                            }

                            // Input Gamescope Args
                            Column {
                                width: parent.width
                                spacing: 4
                                visible: root.isGamescope

                                StyledText {
                                    text: "Argumentos de Gamescope"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                }

                                StyledRect {
                                    width: parent.width
                                    height: 36
                                    color: Theme.surfaceContainerHighest
                                    border.width: 1
                                    border.color: gArgsInput.activeFocus ? Theme.primary : Theme.outline

                                    TextInput {
                                        id: gArgsInput
                                        anchors.fill: parent
                                        anchors.leftMargin: Theme.spacingS
                                        anchors.rightMargin: Theme.spacingS
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Theme.surfaceText
                                        text: root.gamescopeArgs
                                        onEditingFinished: {
                                            root.gamescopeArgs = text;
                                            root.saveConfigValue("GAMESCOPE_ARGS", text);
                                        }
                                    }
                                }
                            }

                            // Input Reopen Command
                            Column {
                                width: parent.width
                                spacing: 4

                                StyledText {
                                    text: "Comando al Reabrir Modo Normal"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                }

                                StyledRect {
                                    width: parent.width
                                    height: 36
                                    color: Theme.surfaceContainerHighest
                                    border.width: 1
                                    border.color: reopenInput.activeFocus ? Theme.primary : Theme.outline

                                    TextInput {
                                        id: reopenInput
                                        anchors.fill: parent
                                        anchors.leftMargin: Theme.spacingS
                                        anchors.rightMargin: Theme.spacingS
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Theme.surfaceText
                                        text: root.reopenNormalCmd
                                        onEditingFinished: {
                                            root.reopenNormalCmd = text;
                                            root.saveConfigValue("REOPEN_NORMAL_CMD", text);
                                        }
                                    }
                                }
                            }

                            // Input Extra Start Cmd
                            Column {
                                width: parent.width
                                spacing: 4

                                StyledText {
                                    text: "Comando Extra al Iniciar"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                }

                                StyledRect {
                                    width: parent.width
                                    height: 36
                                    color: Theme.surfaceContainerHighest
                                    border.width: 1
                                    border.color: startCmdInput.activeFocus ? Theme.primary : Theme.outline

                                    TextInput {
                                        id: startCmdInput
                                        anchors.fill: parent
                                        anchors.leftMargin: Theme.spacingS
                                        anchors.rightMargin: Theme.spacingS
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Theme.surfaceText
                                        text: root.extraStartCmd
                                        onEditingFinished: {
                                            root.extraStartCmd = text;
                                            root.saveConfigValue("EXTRA_START_CMD", text);
                                        }
                                    }
                                }
                            }

                            // Input Extra Stop Cmd
                            Column {
                                width: parent.width
                                spacing: 4

                                StyledText {
                                    text: "Comando Extra al Detener / Cerrar"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                }

                                StyledRect {
                                    width: parent.width
                                    height: 36
                                    color: Theme.surfaceContainerHighest
                                    border.width: 1
                                    border.color: stopCmdInput.activeFocus ? Theme.primary : Theme.outline

                                    TextInput {
                                        id: stopCmdInput
                                        anchors.fill: parent
                                        anchors.leftMargin: Theme.spacingS
                                        anchors.rightMargin: Theme.spacingS
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Theme.surfaceText
                                        text: root.extraStopCmd
                                        onEditingFinished: {
                                            root.extraStopCmd = text;
                                            root.saveConfigValue("EXTRA_STOP_CMD", text);
                                        }
                                    }
                                }
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
