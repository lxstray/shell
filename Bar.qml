import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import "services"
import "utils"

PanelWindow {
  id: root

  property bool launcherOpen: false
  property bool batteryPanelOpen: false
  property bool wifiOpen: false
  property bool powerMenuOpen: false
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

  readonly property bool audioMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false

  VolumeData {
    id: volumeData
    onLevelChanged: {
      if (root.audioMuted && volumeData.level > 0) {
        var s = Pipewire.defaultAudioSink
        if (s?.audio) s.audio.muted = false
      }
      showOverlay(volumeData.level, volumeData.icon, 1)
    }
  }

  PwObjectTracker {
    objects: [ Pipewire.defaultAudioSink ]
  }

  onAudioMutedChanged: {
    if (root.overlayActive) showOverlay(volumeData.level, volumeData.icon, 1)
  }

  BrightnessData {
    id: brightnessData
    onLevelChanged: showOverlay(brightnessData.level, brightnessData.icon, 2)
  }

  property bool overlayActive: false
  property real overlayLevel: 0
  property string overlayIcon: ""
  property int overlaySource: 0

  Timer { id: overlayTimer; interval: 1500; onTriggered: root.overlayActive = false }

  function showOverlay(level, icon, source) {
    if (source === 1 && root.audioMuted) {
      overlayLevel = 0
      overlayIcon = "volume_off"
    } else {
      overlayLevel = level
      overlayIcon = icon
    }
    overlaySource = source
    overlayActive = true
    overlayTimer.restart()
  }

  onOverlayActiveChanged: {
    if (!overlayActive) overlaySource = 0
  }

  function closeAllPanels() {
    launcherOpen = false
    batteryPanelOpen = false
    wifiOpen = false
  }

  onPosChanged: closeAllPanels()

  anchors.left: isHorizontal || pos === "left"
  anchors.right: isHorizontal || pos === "right"
  anchors.top: pos !== "bottom"
  anchors.bottom: pos !== "top"

  readonly property real axisSize: scr ? (isHorizontal ? scr.width : scr.height) : 100
  readonly property real islandMargin: scr ? Math.round(axisSize * (1 - barRatio) / 2) : 0
  readonly property real verticalIslandMargin: scr ? Math.round(axisSize * (1 - verticalBarRatio) / 2) : 0

  readonly property bool anyPanelOpen: launcherOpen || batteryPanelOpen || wifiOpen
  property bool shouldBeFull: anyPanelOpen

  readonly property real closedThickness: 32
  readonly property real maxOpenThickness: 572
  readonly property real batteryPanelExtra: 150
  readonly property real wifiPanelExtra: 380

  onAnyPanelOpenChanged: {
    if (anyPanelOpen) shouldBeFull = true
    else collapseTimer.restart()
  }

  Timer {
    id: collapseTimer
    interval: 200
    onTriggered: shouldBeFull = anyPanelOpen
  }

  WlrLayershell.keyboardFocus: anyPanelOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.exclusionMode: ExclusionMode.Normal
  WlrLayershell.exclusiveZone: closedThickness + (isIsland ? 8 : 0)

  readonly property real currentPanelHeight: launcherOpen ? Math.min(maxOpenThickness, 54 + launcher.desiredContentHeight) :
    batteryPanelOpen ? batteryPanelExtra :
    wifiOpen ? wifiPanelExtra :
    closedThickness

  readonly property real currentPanelWidth: launcherOpen ? maxOpenThickness :
    batteryPanelOpen ? batteryPanelExtra :
    wifiOpen ? wifiPanelExtra :
    closedThickness

  implicitHeight: isHorizontal ? (shouldBeFull ? (scr?.height ?? 600) : closedThickness + (isIsland ? 8 : 0)) : (scr?.height ?? 600)
  implicitWidth: isHorizontal ? (scr?.width ?? 800) : (shouldBeFull ? (scr?.width ?? 800) : closedThickness + (isIsland ? 8 : 0))

  Item {
    id: contentContainer
    anchors.fill: parent

    MouseArea {
      anchors.fill: parent
      z: 0
      enabled: anyPanelOpen
      onClicked: closeAllPanels()
    }

    Item {
      id: barContainer
      x: isHorizontal ? (isIsland ? islandMargin : 0) : (pos === "left" ? (isIsland ? 8 : 0) : (parent.width - width - (isIsland ? 8 : 0)))
      y: isHorizontal ? (pos === "top" ? (isIsland ? 8 : 0) : (parent.height - height - (isIsland ? 8 : 0))) : (isIsland ? verticalIslandMargin : 0)
      width: isHorizontal ? (parent.width - (isIsland ? 2 * islandMargin : 0)) : currentPanelWidth
      height: isHorizontal ? currentPanelHeight : (parent.height - (isIsland ? 2 * verticalIslandMargin : 0))

      Behavior on height {
        enabled: isHorizontal
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
      }

      Behavior on width {
        enabled: !isHorizontal
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
      }

      Rectangle {
        id: mainRect
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
          clip: true

          readonly property bool panelOpen: root.anyPanelOpen

          // Horizontal mode content (top/bottom bar)
          RowLayout {
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            spacing: 4
            visible: isHorizontal
            enabled: !parent.panelOpen && !root.overlayActive

            x: parent.panelOpen || root.overlayActive ? -120 : 0
            opacity: parent.panelOpen || root.overlayActive ? 0 : 1

            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

            Workspaces { horizontal: true }
          }

          RowLayout {
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            spacing: 4
            visible: isHorizontal
            enabled: !parent.panelOpen && !root.overlayActive

            x: parent.panelOpen || root.overlayActive ? parent.width + 120 : 0
            opacity: parent.panelOpen || root.overlayActive ? 0 : 1

            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

            Text {
              text: Nmcli.active ? Icons.getNetworkIcon(Nmcli.active.strength ?? 0) : "wifi_off"
              font.family: "Material Symbols Rounded"
              font.pixelSize: 18
              color: Nmcli.active ? "#eee" : "#888"

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.wifiOpen = !root.wifiOpen
              }
            }

            BatteryIndicator { batteryData: batteryData; onClicked: root.batteryPanelOpen = !root.batteryPanelOpen }
            Clock { horizontal: true }
            Text {
              text: "power_settings_new"
              font.family: "Material Symbols Rounded"
              font.pixelSize: 18
              color: "#888"

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.powerMenuOpen = !root.powerMenuOpen
              }
            }
          }

          // Vertical mode content (left/right bar)
          Item {
            anchors { top: parent.top; topMargin: 8; bottom: parent.verticalCenter; horizontalCenter: parent.horizontalCenter }
            visible: !isHorizontal
            enabled: !parent.panelOpen && !root.overlayActive

            x: parent.panelOpen || root.overlayActive ? -90 : 0
            opacity: parent.panelOpen || root.overlayActive ? 0 : 1

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
            enabled: !parent.panelOpen && !root.overlayActive

            x: parent.panelOpen || root.overlayActive ? 90 : 0
            opacity: parent.panelOpen || root.overlayActive ? 0 : 1

            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

            ColumnLayout {
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.bottom: parent.bottom
              spacing: 6

              Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: -7
                text: Nmcli.active ? Icons.getNetworkIcon(Nmcli.active.strength ?? 0) : "wifi_off"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 18
                color: Nmcli.active ? "#eee" : "#888"

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.wifiOpen = !root.wifiOpen
                }
              }

              BatteryIndicator {
                Layout.alignment: Qt.AlignHCenter
                batteryData: batteryData; horizontal: false
                onClicked: root.batteryPanelOpen = !root.batteryPanelOpen
              }
              Clock {
                Layout.rightMargin: 1
                Layout.alignment: Qt.AlignHCenter
                horizontal: false
              }
              Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 10
                text: "power_settings_new"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 16
                color: "#888"

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.powerMenuOpen = !root.powerMenuOpen
                }
              }
            }
          }

          // Overlay for volume/brightness indicator
          Item {
            id: overlayItem
            anchors.fill: parent
            visible: root.overlayActive
            opacity: root.overlayActive ? 1 : 0
            clip: true

            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            readonly property real lineSize: Math.round(root.closedThickness * 0.1)

            // Horizontal mode
            RowLayout {
              anchors { left: parent.left; leftMargin: 24; right: parent.right; rightMargin: 24; verticalCenter: parent.verticalCenter }
              spacing: 16
              visible: isHorizontal

              Text {
                text: root.overlayIcon
                font.family: "Material Symbols Rounded"
                font.pixelSize: 22
                color: "#eee"
                Layout.preferredWidth: 32
              }

              Rectangle {
                Layout.fillWidth: true
                height: parent.parent.lineSize
                radius: Math.round(height / 2)
                color: "#2a2a2a"
                clip: true

                Rectangle {
                  width: parent.width * root.overlayLevel
                  height: parent.height
                  radius: parent.radius
                  color: "#eee"

                  Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                }
              }

              Text {
                text: Math.round(root.overlayLevel * 100) + "%"
                color: "#eee"
                font.pixelSize: 13
                font.weight: Font.Medium
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
              }
            }

            // Vertical mode
            ColumnLayout {
              anchors { top: parent.top; topMargin: 16; bottom: parent.bottom; bottomMargin: 16; horizontalCenter: parent.horizontalCenter }
              spacing: 12
              visible: !isHorizontal

              Text {
                text: root.overlayIcon
                font.family: "Material Symbols Rounded"
                font.pixelSize: 20
                color: "#eee"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 24
                horizontalAlignment: Text.AlignHCenter
              }

              Rectangle {
                Layout.fillHeight: true
                width: parent.parent.lineSize
                radius: Math.round(width / 2)
                color: "#2a2a2a"
                Layout.alignment: Qt.AlignHCenter
                clip: true

                Rectangle {
                  width: parent.width
                  height: parent.height * root.overlayLevel
                  radius: parent.radius
                  color: "#eee"
                  anchors.bottom: parent.bottom

                  Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                }
              }

              Text {
                text: Math.round(root.overlayLevel * 100) + "%"
                color: "#eee"
                font.pixelSize: 11
                font.weight: Font.Medium
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 30
                horizontalAlignment: Text.AlignHCenter
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
        anchors.fill: parent
        onCanceled: root.batteryPanelOpen = false
      }

      Item {
        id: wifiPanel
        anchors.fill: parent
        visible: root.wifiOpen

        WifiPopout {
          id: wifiPopout
          open: root.wifiOpen
          anchors.fill: parent
          onOpenPasswordDialog: network => {
            wifiPasswordPopout.network = network
            wifiPasswordPopout.open = true
            wifiPopout.open = false
          }
          onCloseRequested: root.wifiOpen = false
        }

        WirelessPassword {
          id: wifiPasswordPopout
          anchors.fill: parent
          onCloseRequested: {
            wifiPopout.open = true
          }
        }
      }

      Item {
        anchors.fill: parent
        clip: true
        Launcher {
          id: launcher
          z: 1
          open: root.launcherOpen
          barPosition: root.pos
          anchors.fill: parent
          onAppLaunched: root.appLaunched()
          onCanceled: root.canceled()
          onOpenSettings: root.openSettings()
        }
      }
    }
  }

  onLauncherOpenChanged: {
    if (launcherOpen) {
      batteryPanelOpen = false
      wifiOpen = false
      powerMenuOpen = false
      Qt.callLater(function() {
        launcher.focusSearch()
      })
    }
  }

  onBatteryPanelOpenChanged: {
    if (batteryPanelOpen) {
      launcherOpen = false
      wifiOpen = false
      powerMenuOpen = false
      Qt.callLater(function() {
        batteryPanel.forceActiveFocus()
      })
    }
  }

  onWifiOpenChanged: {
    if (wifiOpen) {
      launcherOpen = false
      batteryPanelOpen = false
      powerMenuOpen = false
    }
  }

  onPowerMenuOpenChanged: {
    if (powerMenuOpen) {
      launcherOpen = false
      batteryPanelOpen = false
      wifiOpen = false
    }
  }

  PowerMenu {
    menuOpen: root.powerMenuOpen
    onCloseRequested: root.powerMenuOpen = false
  }
}
