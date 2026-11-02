import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets

StyledRect {
    id: root

    property bool useGamescope: false
    property string gamescopeResolution: "custom"
    property string gamescopeRefreshRate: "default"
    property bool gamescopeFullscreen: true
    property bool enableAudioRouting: false
    property string targetAudio: ""
    property int targetVolume: 100

    Layout.fillWidth: true
    visible: root.useGamescope || (root.enableAudioRouting && root.targetAudio.length > 0)
    implicitHeight: summaryColumn.implicitHeight + Theme.spacingS * 2
    radius: Theme.cornerRadius || 10
    color: Theme.surfaceContainer
    border.width: 1
    border.color: Theme.withAlpha(Theme.outline, 0.1)

    ColumnLayout {
        id: summaryColumn
        anchors.fill: parent
        anchors.margins: Theme.spacingS
        spacing: 4

        RowLayout {
            visible: root.useGamescope
            spacing: Theme.spacingXS
            DIcon {
                name: "tv"
                size: 16
                color: Theme.surfaceVariantText
            }
            StyledText {
                text: "Display: " + (root.gamescopeResolution === "custom" ? "Custom args" : root.gamescopeResolution.toUpperCase()) +
                      (root.gamescopeRefreshRate !== "default" ? " @ " + root.gamescopeRefreshRate + "Hz" : "") +
                      (root.gamescopeFullscreen ? " (Fullscreen)" : " (Windowed)")
                font.pixelSize: Theme.fontSizeSmall - 1
                color: Theme.surfaceVariantText
            }
        }

        RowLayout {
            visible: root.enableAudioRouting && root.targetAudio.length > 0
            spacing: Theme.spacingXS
            DIcon {
                name: "volume_up"
                size: 16
                color: Theme.surfaceVariantText
            }
            StyledText {
                text: "Audio Route: " + root.targetAudio + " (" + root.targetVolume + "%)"
                font.pixelSize: Theme.fontSizeSmall - 1
                color: Theme.surfaceVariantText
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }
}
