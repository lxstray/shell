import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
  id: root

  property bool launcherOpen: false
  property bool batteryPanelOpen: false
  property var settings: null

  readonly property real barRatio: 0.25
  readonly property real verticalBarRatio: 0.35

  signal appLaunched()
  signal canceled()
  signal openSettings()

  color: "transparent"

  readonly property string pos: settings ? settings.barPosition : "top"
  readonly property string style: settings ? settings.barStyle : "island"
  readonly property bool isIsland: style === "island"
  readonly property bool isHorizontal: pos === "top" || pos === "bottom"

  property var scr: Quickshell.screens[0] || screen

  BatteryData { id: batteryData }

  onPosChanged: {
    launcherOpen = false
    batteryPanelOpen = false
  }

  anchors.left: pos !== "right"
  anchors.right: pos !== "left"
  anchors.top: pos !== "bottom"
  anchors.bottom: pos !== "top"

  readonly property real axisSize: scr ? (isHorizontal ? scr.width : scr.height) : 100
  readonly property real islandMargin: scr ? Math.round(axisSize * (1 - barRatio) / 2) : 0
  readonly property real verticalIslandMargin: scr ? Math.round(axisSize * (1 - verticalBarRatio) / 2) : 0

  margins.top: pos === "top" ? (isIsland ? 8 : 0) : (isIsland ? (isHorizontal ? islandMargin : verticalIslandMargin) : 0)
  margins.bottom: pos === "bottom" ? (isIsland ? 8 : 0) : (isIsland ? (isHorizontal ? islandMargin : verticalIslandMargin) : 0)
  margins.left: pos === "left" ? (isIsland ? 8 : 0) : (isIsland ? (isHorizontal ? islandMargin : verticalIslandMargin) : 0)
  margins.right: pos === "right" ? (isIsland ? 8 : 0) : (isIsland ? (isHorizontal ? islandMargin : verticalIslandMargin) : 0)

  WlrLayershell.keyboardFocus: launcherOpen || batteryPanelOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.exclusionMode: ExclusionMode.Normal
  WlrLayershell.exclusiveZone: 32

  readonly property real closedThickness: 32
  readonly property real maxOpenThickness: 572
  readonly property real batteryPanelExtra: 150

  implicitHeight: isHorizontal ? (
    launcherOpen ? Math.min(maxOpenThickness, 54 + launcher.desiredContentHeight) :
    batteryPanelOpen ? batteryPanelExtra :
    closedThickness
  ) : (scr ? scr.height : 600)
  implicitWidth: isHorizontal ? (scr ? scr.width : 800) : (
    launcherOpen ? maxOpenThickness :
    batteryPanelOpen ? batteryPanelExtra :
    closedThickness
  )

  Behavior on implicitHeight {
    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
  }

  Behavior on implicitWidth {
    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
  }

  Item {
    id: contentContainer
    anchors.fill: parent

    Rectangle {
      id: mainRect
      anchors.fill: parent
      radius: isIsland ? 16 : 0
      color: "#111"
      border { color: "#2a2a2a"; width: isIsland ? 1 : 0 }
      clip: false

      Item {
        id: barStrip
        x: isHorizontal ? 0 : (pos === "right" ? parent.width - 32 : 0)
        y: isHorizontal ? (pos === "bottom" ? parent.height - 32 : 0) : 0
        width: isHorizontal ? parent.width : 32
        height: isHorizontal ? 32 : parent.height
        clip: true

        readonly property bool panelOpen: root.launcherOpen || root.batteryPanelOpen

        // Horizontal mode content (top/bottom bar)
        RowLayout {
          anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
          spacing: 4
          visible: isHorizontal
          enabled: !parent.panelOpen

          x: parent.panelOpen ? -120 : 0
          opacity: parent.panelOpen ? 0 : 1

          Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
          Behavior on opacity { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

          Workspaces { horizontal: true }
        }

        RowLayout {
          anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
          spacing: 4
          visible: isHorizontal
          enabled: !parent.panelOpen

          x: parent.panelOpen ? parent.width + 120 : 0
          opacity: parent.panelOpen ? 0 : 1

          Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
          Behavior on opacity { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

          BatteryIndicator { batteryData: batteryData; onClicked: root.batteryPanelOpen = !root.batteryPanelOpen }
          Clock { horizontal: true }
        }

        // Vertical mode content (left/right bar)
        Item {
          anchors { top: parent.top; topMargin: 8; bottom: parent.verticalCenter; horizontalCenter: parent.horizontalCenter }
          visible: !isHorizontal
          enabled: !parent.panelOpen

          x: parent.panelOpen ? -90 : 0
          opacity: parent.panelOpen ? 0 : 1

          Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
          Behavior on opacity { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

          Column {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            Workspaces { horizontal: false }
          }
        }

        Item {
          anchors { top: parent.verticalCenter; bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
          visible: !isHorizontal
          enabled: !parent.panelOpen

          x: parent.panelOpen ? 90 : 0
          opacity: parent.panelOpen ? 0 : 1

          Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
          Behavior on opacity { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

          ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            spacing: 6
            BatteryIndicator {
              Layout.alignment: Qt.AlignHCenter
              batteryData: batteryData; horizontal: false
              onClicked: root.batteryPanelOpen = !root.batteryPanelOpen
            }
            Clock {
              Layout.alignment: Qt.AlignHCenter
	      Layout.bottomMargin: 10
	      Layout.rightMargin: 3
              horizontal: false
            }
          }
        }
      }
    }

    BatteryPanel {
      id: batteryPanel
      batteryData: batteryData
      open: root.batteryPanelOpen
      barPosition: root.pos
      isIsland: root.isIsland
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      onCanceled: root.batteryPanelOpen = false
    }

    Launcher {
      id: launcher
      z: 1
      open: root.launcherOpen
      barPosition: root.pos
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      onAppLaunched: root.appLaunched()
      onCanceled: root.canceled()
      onOpenSettings: root.openSettings()
    }
  }

  onLauncherOpenChanged: {
    if (launcherOpen) {
      batteryPanelOpen = false
      Qt.callLater(function() {
        launcher.focusSearch()
      })
    }
  }

  onBatteryPanelOpenChanged: {
    if (batteryPanelOpen) {
      launcherOpen = false
      Qt.callLater(function() {
        batteryPanel.forceActiveFocus()
      })
    }
  }
}
