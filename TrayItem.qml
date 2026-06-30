import QtQuick
import Quickshell.Services.SystemTray

Item {
  id: root
  required property SystemTrayItem modelData
  required property var trayMenuHost

  implicitWidth: 24
  implicitHeight: 24

  Timer {
    id: hoverTimer
    interval: 200
    onTriggered: openMenu()
  }

  function openMenu() {
    if (!root.modelData.hasMenu) return
    var host = root.trayMenuHost
    host.currentTrayMenu = root.modelData.menu
    host.trayMenuY = root.mapToItem(host.trayMenuLayer, 12, 12).y
    if (!host.trayMenuOpen) {
      host.trayMenuOpen = true
    }
    host.keepTrayOpen()
  }

  MouseArea {
    id: hoverArea
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true

    onEntered: {
      root.trayMenuHost.keepTrayOpen()
      if (root.modelData.hasMenu)
        hoverTimer.start()
    }

    onExited: {
      hoverTimer.stop()
    }

    onClicked: event => {
      hoverTimer.stop()
      if (event.button === Qt.LeftButton)
        root.modelData.activate()
      else if (event.button === Qt.RightButton)
        openMenu()
    }
  }

  Image {
    anchors.centerIn: parent
    source: root.modelData.icon
    sourceSize.width: 20
    sourceSize.height: 20
    fillMode: Image.PreserveAspectFit
    smooth: true
    asynchronous: true
  }

  Rectangle {
    anchors.fill: parent
    radius: 4
    color: hoverArea.containsMouse ? "#3a3a3a" : "transparent"
    z: -1
    Behavior on color { ColorAnimation { duration: 80 } }
  }
}
