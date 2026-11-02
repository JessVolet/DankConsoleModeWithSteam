import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets

RowLayout {
    id: root

    property bool isRunning: false
    property string transitionState: ""
    property bool useGamescope: false
    property bool useFlatpak: false
    property string gamescopeResolution: "custom"

    signal toggleGamescope()
    signal toggleFlatpak()

    Layout.fillWidth: true
    spacing: Theme.spacingS

    // Gamescope Toggle Card
    StyledRect {
        Layout.fillWidth: true
        implicitHeight: 58
        radius: Theme.cornerRadius || 12
        color: root.useGamescope ? Theme.primaryContainer : Theme.surfaceContainerHigh
        border.width: 1
        border.color: root.useGamescope ? Theme.primary : Theme.withAlpha(Theme.outline, 0.15)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingM
            anchors.rightMargin: Theme.spacingM
            spacing: Theme.spacingS

            DIcon {
                name: "aspect_ratio"
                size: 20
                color: root.useGamescope ? Theme.onPrimaryContainer : Theme.surfaceVariantText
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                StyledText {
                    text: "Gamescope"
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Bold
                    color: root.useGamescope ? Theme.onPrimaryContainer : Theme.surfaceText
                }
                StyledText {
                    text: root.useGamescope ? (root.gamescopeResolution === "custom" ? "Custom" : root.gamescopeResolution.toUpperCase()) : "Disabled"
                    font.pixelSize: Theme.fontSizeSmall - 1
                    color: root.useGamescope ? Theme.onPrimaryContainer : Theme.surfaceVariantText
                }
            }

            Rectangle {
                width: 18
                height: 18
                radius: 9
                color: root.useGamescope ? Theme.primary : Theme.withAlpha(Theme.surfaceVariantText, 0.25)
                DIcon {
                    visible: root.useGamescope
                    name: "check"
                    size: 13
                    color: Theme.onPrimary
                    anchors.centerIn: parent
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: (!root.isRunning && root.transitionState === "") ? Qt.PointingHandCursor : Qt.ArrowCursor
            enabled: !root.isRunning && root.transitionState === ""
            onClicked: root.toggleGamescope()
        }
    }

    // Runtime Toggle Card
    StyledRect {
        Layout.fillWidth: true
        implicitHeight: 58
        radius: Theme.cornerRadius || 12
        color: root.useFlatpak ? Theme.secondaryContainer : Theme.surfaceContainerHigh
        border.width: 1
        border.color: root.useFlatpak ? Theme.secondary : Theme.withAlpha(Theme.outline, 0.15)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingM
            anchors.rightMargin: Theme.spacingM
            spacing: Theme.spacingS

            DIcon {
                name: "inventory_2"
                size: 20
                color: root.useFlatpak ? Theme.onSecondaryContainer : Theme.surfaceVariantText
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                StyledText {
                    text: "Runtime"
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Bold
                    color: root.useFlatpak ? Theme.onSecondaryContainer : Theme.surfaceText
                }
                StyledText {
                    text: root.useFlatpak ? "Flatpak" : "Native"
                    font.pixelSize: Theme.fontSizeSmall - 1
                    color: root.useFlatpak ? Theme.onSecondaryContainer : Theme.surfaceVariantText
                }
            }

            Rectangle {
                width: 18
                height: 18
                radius: 9
                color: root.useFlatpak ? Theme.secondary : Theme.withAlpha(Theme.surfaceVariantText, 0.25)
                DIcon {
                    visible: root.useFlatpak
                    name: "check"
                    size: 13
                    color: Theme.onSecondary
                    anchors.centerIn: parent
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: (!root.isRunning && root.transitionState === "") ? Qt.PointingHandCursor : Qt.ArrowCursor
            enabled: !root.isRunning && root.transitionState === ""
            onClicked: root.toggleFlatpak()
        }
    }
}
