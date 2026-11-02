import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets

StyledRect {
    id: root

    property bool isRunning: false
    property string transitionState: ""
    property bool useFlatpak: false
    property bool useGamescope: false
    signal settingsClicked()

    Layout.fillWidth: true
    implicitHeight: 74
    radius: Theme.cornerRadiusL || 16
    color: Theme.surfaceContainerHigh
    border.width: 1
    border.color: Theme.withAlpha(Theme.outline, 0.12)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingS
        spacing: Theme.spacingM

        // Squircle Icon Badge
        Rectangle {
            width: 42
            height: 42
            radius: Theme.cornerRadius || 12
            color: root.transitionState !== "" ? Theme.withAlpha(Theme.warning, 0.15) :
                   root.isRunning ? Theme.withAlpha(Theme.primary, 0.15) :
                   Theme.withAlpha(Theme.surfaceVariantText, 0.12)

            DIcon {
                name: "sports_esports"
                size: 24
                anchors.centerIn: parent
                color: root.transitionState !== "" ? Theme.warning :
                       root.isRunning ? Theme.primary : Theme.surfaceVariantText
            }
        }

        // Title & Mode Details
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                text: "Steam Big Picture"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Bold
                color: Theme.surfaceText
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            RowLayout {
                spacing: 4
                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    color: root.transitionState !== "" ? Theme.warning :
                           root.isRunning ? Theme.primary : Theme.surfaceVariantText
                }
                StyledText {
                    text: root.transitionState === "starting" ? "Starting session..." :
                          root.transitionState === "stopping" ? "Stopping..." :
                          root.isRunning ? "Session Active" : "Ready to launch"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }
        }

        // Status Badge Pill
        Rectangle {
            height: 24
            implicitWidth: badgeText.implicitWidth + Theme.spacingM
            radius: 12
            color: root.transitionState !== "" ? Theme.withAlpha(Theme.warning, 0.15) :
                   root.isRunning ? Theme.withAlpha(Theme.primary, 0.15) :
                   Theme.withAlpha(Theme.surfaceVariantText, 0.12)
            border.width: 1
            border.color: root.transitionState !== "" ? Theme.warning :
                          root.isRunning ? Theme.primary : Theme.withAlpha(Theme.outline, 0.18)

            StyledText {
                id: badgeText
                anchors.centerIn: parent
                text: root.transitionState === "starting" ? "STARTING" :
                      root.transitionState === "stopping" ? "STOPPING" :
                      root.isRunning ? "RUNNING" : "STOPPED"
                font.pixelSize: 10
                font.weight: Font.Bold
                color: root.transitionState !== "" ? Theme.warning :
                       root.isRunning ? Theme.primary : Theme.surfaceVariantText
            }
        }

        // Settings Shortcut Button
        DIconButton {
            iconName: "settings"
            tooltipText: "Open Plugin Settings"
            onClicked: root.settingsClicked()
        }
    }
}
