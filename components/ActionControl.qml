import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets

DButton {
    id: root

    property bool isRunning: false
    property string transitionState: ""
    signal actionTriggered()

    Layout.fillWidth: true
    iconName: root.isRunning ? "stop" : "play_arrow"
    text: root.transitionState === "starting" ? "Starting Big Picture..." :
          root.transitionState === "stopping" ? "Stopping Session..." :
          root.isRunning ? "Exit Big Picture" : "Launch Big Picture"
    buttonHeight: 46
    backgroundColor: root.isRunning ? Theme.error : Theme.primary
    textColor: root.isRunning ? Theme.onError : Theme.onPrimary
    enabled: root.transitionState === ""
    onClicked: root.actionTriggered()
}
