import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Item {
  id: root

  required property QsMenuHandle trayItemMenu

  property var menuHistory: []
  property QsMenuHandle currentHandle: trayItemMenu
  property bool contentChanging: false

  onCurrentHandleChanged: {
    contentChanging = true
    Qt.callLater(function() { contentChanging = false })
  }

  onTrayItemMenuChanged: {
    menuHistory = []
    currentHandle = trayItemMenu
  }

  implicitHeight: Math.min(column.implicitHeight, 170)

  Flickable {
    id: flick
    anchors.fill: parent
    contentWidth: parent.width
    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    opacity: root.contentChanging ? 0.4 : 1
    Behavior on opacity { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }

    Column {
      id: column
      width: parent.width
      spacing: 2
      bottomPadding: 6

    Rectangle {
      width: parent.width
      height: 28
      radius: 4
      visible: root.menuHistory.length > 0
      color: backMouse.containsMouse ? "#3a3a3a" : "transparent"

      Behavior on color { ColorAnimation { duration: 80 } }

      MouseArea {
        id: backMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.currentHandle = root.menuHistory.pop()
      }

      Text {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: "\u2190 Back"
        color: "#eee"
        font.pixelSize: 13
      }
    }

    QsMenuOpener {
      id: opener
      menu: root.currentHandle
    }

    Repeater {
      id: repeater
      model: opener.children

      delegate: Item {
        required property var modelData

        width: column.width
        height: modelData.isSeparator ? 1 : 28

        Rectangle {
          anchors.fill: parent
          radius: 4
          visible: !modelData.isSeparator
          color: mouseArea.containsMouse ? "#4a4a4a" : "transparent"

          Behavior on color { ColorAnimation { duration: 80 } }

          MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: modelData.enabled

            onClicked: {
              if (modelData.hasChildren) {
                root.menuHistory.push(root.currentHandle)
                root.currentHandle = modelData.menu
              } else {
                modelData.triggered()
              }
            }
          }

          Text {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.text
            color: modelData.enabled ? (mouseArea.containsMouse ? "#fff" : "#eee") : "#666"
            font.pixelSize: 13
            elide: Text.ElideRight
            width: parent.width - 32
          }

          Text {
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: "\u25B6"
            color: mouseArea.containsMouse ? "#fff" : "#666"
            font.pixelSize: 10
            visible: modelData.hasChildren
          }
        }

        Rectangle {
          anchors.fill: parent
          color: "#2a2a2a"
          visible: modelData.isSeparator
        }
      }
    }
  }
  }
}
