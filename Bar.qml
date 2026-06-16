import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
  id: root

  property bool launcherOpen: false
  property var settings: null

  readonly property real barRatio: 0.25

  signal appLaunched()
  signal canceled()
  signal openSettings()

  color: "transparent"

  readonly property string pos: settings ? settings.barPosition : "top"
  readonly property string style: settings ? settings.barStyle : "island"
  readonly property bool isIsland: style === "island"
  readonly property bool isHorizontal: pos === "top" || pos === "bottom"

  property var scr: Quickshell.screens[0] || screen

  anchors.left: pos !== "right"
  anchors.right: pos !== "left"
  anchors.top: pos !== "bottom"
  anchors.bottom: pos !== "top"

  readonly property real axisSize: scr ? (isHorizontal ? scr.width : scr.height) : 100
  readonly property real islandMargin: scr ? Math.round(axisSize * (1 - barRatio) / 2) : 0

  margins.top: pos === "top" ? (isIsland ? 8 : 0) : (isIsland ? islandMargin : 0)
  margins.bottom: pos === "bottom" ? (isIsland ? 8 : 0) : (isIsland ? islandMargin : 0)
  margins.left: pos === "left" ? (isIsland ? 8 : 0) : (isIsland ? islandMargin : 0)
  margins.right: pos === "right" ? (isIsland ? 8 : 0) : (isIsland ? islandMargin : 0)

  WlrLayershell.keyboardFocus: launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.exclusionMode: ExclusionMode.Normal
  WlrLayershell.exclusiveZone: 32

  readonly property real closedThickness: 32
  readonly property real maxOpenThickness: 572

  implicitHeight: isHorizontal ? (launcherOpen ? Math.min(maxOpenThickness, 54 + launcher.desiredContentHeight) : closedThickness) : (scr ? scr.height : 600)
  implicitWidth: isHorizontal ? (scr ? scr.width : 800) : (launcherOpen ? maxOpenThickness : closedThickness)

  Behavior on implicitHeight {
    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
  }

  Behavior on implicitWidth {
    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
  }

  Rectangle {
    anchors.fill: parent
    radius: isIsland ? 16 : 0
    color: "#111"
    border { color: "#2a2a2a"; width: isIsland ? 1 : 0 }
    clip: true

    Item {
      id: barStrip
      x: isHorizontal ? 0 : (pos === "right" ? parent.width - 32 : 0)
      y: isHorizontal ? (pos === "bottom" ? parent.height - 32 : 0) : 0
      width: isHorizontal ? parent.width : 32
      height: isHorizontal ? 32 : parent.height

      // Horizontal mode content (top/bottom bar)
      RowLayout {
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        spacing: 4
        visible: isHorizontal

        x: root.launcherOpen ? -120 : 0
        opacity: root.launcherOpen ? 0 : 1

        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Workspaces { horizontal: true }
      }

      RowLayout {
        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
        spacing: 4
        visible: isHorizontal

        x: root.launcherOpen ? parent.width + 120 : 0
        opacity: root.launcherOpen ? 0 : 1

        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Clock { horizontal: true }
      }

      // Vertical mode content (left/right bar)
      Item {
        anchors { top: parent.top; topMargin: 8; bottom: parent.verticalCenter; horizontalCenter: parent.horizontalCenter }
        visible: !isHorizontal
        x: root.launcherOpen ? -90 : 0
        opacity: root.launcherOpen ? 0 : 1

        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Column {
          anchors.centerIn: parent
          spacing: 6
          Workspaces { horizontal: false }
        }
      }

      Item {
        anchors { top: parent.verticalCenter; bottom: parent.bottom; bottomMargin: 8; horizontalCenter: parent.horizontalCenter }
        visible: !isHorizontal
        x: root.launcherOpen ? 90 : 0
        opacity: root.launcherOpen ? 0 : 1

        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Column {
          anchors.centerIn: parent
          spacing: 6
          Clock { horizontal: false }
        }
      }
    }

    Launcher {
      id: launcher
      open: root.launcherOpen
      barPosition: root.pos
      anchors.top: isHorizontal ? (pos === "bottom" ? parent.top : barStrip.bottom) : parent.top
      anchors.left: isHorizontal ? parent.left : (pos === "right" ? parent.left : barStrip.right)
      anchors.right: isHorizontal ? parent.right : (pos === "right" ? barStrip.left : parent.right)
      anchors.bottom: isHorizontal ? (pos === "bottom" ? barStrip.top : parent.bottom) : parent.bottom
      anchors.topMargin: 6
      onAppLaunched: root.appLaunched()
      onCanceled: root.canceled()
      onOpenSettings: root.openSettings()
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
