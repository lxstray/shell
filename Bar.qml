import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
  id: root

  property bool launcherOpen: false
  readonly property real barRatio: 0.25

  signal appLaunched()
  signal canceled()

  color: "transparent"

  anchors { left: true; right: true; top: true }

  property var scr: Quickshell.screens[0] || screen

  margins.top: 8
  margins.left: scr ? Math.round(scr.width * (1 - barRatio) / 2) : 0
  margins.right: scr ? Math.round(scr.width * (1 - barRatio) / 2) : 0

  WlrLayershell.keyboardFocus: launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.exclusionMode: ExclusionMode.Normal
  WlrLayershell.exclusiveZone: 32

  readonly property real closedHeight: 32
  readonly property real openHeight: 572

  implicitHeight: launcherOpen ? openHeight : closedHeight

  Behavior on implicitHeight {
    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
  }

  Rectangle {
    anchors.fill: parent
    radius: 16
    color: "#111"
    border { color: "#2a2a2a"; width: 1 }
    clip: true

    ColumnLayout {
      anchors.fill: parent
      spacing: 0

      Item {
        Layout.fillWidth: true
        implicitHeight: 32

        RowLayout {
          anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
          spacing: 4

          x: root.launcherOpen ? -120 : 0
          opacity: root.launcherOpen ? 0 : 1

          Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
          Behavior on opacity { NumberAnimation { duration: 200 } }

          Workspaces { }
        }

        RowLayout {
          anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
          spacing: 4

          x: root.launcherOpen ? parent.width + 120 : 0
          opacity: root.launcherOpen ? 0 : 1

          Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
          Behavior on opacity { NumberAnimation { duration: 200 } }

          Clock { }
        }
      }

      Launcher {
        id: launcher
        open: root.launcherOpen
        Layout.fillWidth: true
        Layout.fillHeight: true
        onAppLaunched: root.appLaunched()
        onCanceled: root.canceled()
      }
    }
  }

  onLauncherOpenChanged: {
    if (launcherOpen) {
      Qt.callLater(function() {
        launcher.focusSearch()
      })
    }
  }
}
