import QtQuick
import QtQuick.Layouts
import Quickshell
import "services"
import "utils"

Item {
  id: root

  property bool open: false
  property var network: null

  signal closeRequested()

  visible: open
  enabled: open
  focus: enabled

  Keys.onEscapePressed: close()

  opacity: open ? 1 : 0
  scale: open ? 1 : 0.8

  Behavior on opacity {
    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
  }
  Behavior on scale {
    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
  }

  onVisibleChanged: {
    if (open) {
      Qt.callLater(() => { root.forceActiveFocus(); passField.forceActiveFocus() })
    }
  }

  function close(): void {
    root.open = false
    passField.text = ""
    connecting = false
    connectError = false
    closeRequested()
  }

  property bool connecting: false
  property bool connectError: false

  Rectangle {
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors.centerIn: parent
      width: Math.min(320, parent.width - 24)
      spacing: 0

      Rectangle {
        id: dialogBg
        Layout.fillWidth: true
        implicitHeight: innerCol.implicitHeight + 32
        radius: 12
        color: "#1a1a1a"
        border { color: "#333"; width: 1 }

        ColumnLayout {
          id: innerCol
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: 16
          spacing: 14

          // Back button row
          RowLayout {
            Layout.fillWidth: true

            Text {
              text: "arrow_back"
              font.family: "Material Symbols Rounded"
              font.pixelSize: 20
              color: "#aaa"
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.close()
              }
            }

            Item { Layout.fillWidth: true }

            Text {
              text: "lock"
              font.family: "Material Symbols Rounded"
              font.pixelSize: 24
              color: "#aaa"
            }
          }

          Text {
            text: "Enter password"
            font.pixelSize: 15
            font.weight: Font.Medium
            color: "#eee"
          }

          Text {
            text: network ? network.ssid : ""
            font.pixelSize: 11
            color: "#888"
            elide: Text.ElideRight
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 8
            color: passField.activeFocus ? "#2a2a2a" : "#222"
            border.width: connectError ? 2 : (passField.activeFocus ? 2 : 1)
            border.color: connectError ? "#888" : (passField.activeFocus ? "#ccc" : "#444")

            Behavior on border.color {
              ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            TextInput {
              id: passField
              anchors.fill: parent
              anchors.margins: 10
              verticalAlignment: TextInput.AlignVCenter
              color: "#eee"
              font.pixelSize: 13
              echoMode: TextInput.Password
              focus: true
              onTextChanged: connectError = false
              Keys.onEscapePressed: root.close()
              Keys.onReturnPressed: doConnect()
            }
          }

          Text {
            visible: connectError
            text: "Connection failed. Check password and try again."
            color: "#888"
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 36
              radius: 8
              color: "#333"
              Text {
                anchors.centerIn: parent
                text: "Cancel"
                font.pixelSize: 13
                color: "#ccc"
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.close()
              }
            }

            Rectangle {
              id: connectBtn
              Layout.fillWidth: true
              Layout.preferredHeight: 36
              radius: 8
              color: connecting ? "#555" : (passField.text.length > 0 ? "#ccc" : "#444")

              Text {
                anchors.centerIn: parent
                text: connecting ? "Connecting..." : "Connect"
                font.pixelSize: 13
                font.weight: Font.Medium
                color: passField.text.length > 0 && !connecting ? "#111" : "#888"
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: passField.text.length > 0 && !connecting
                onClicked: doConnect()
              }
            }
          }
        }
      }
    }
  }

  function doConnect(): void {
    if (!network || connecting || !passField.text) return
    connectError = false
    connecting = true

    NetworkConnection.connectWithPassword(network, passField.text, result => {
      if (result && result.success) {
        Qt.callLater(() => { root.close() })
      } else {
        connecting = false
        connectError = true
      }
    })
  }

  Timer {
    id: closeDelay
    interval: 500
    onTriggered: root.close()
  }

  Connections {
    target: Nmcli
    function onActiveChanged() {
      if (root.open && connecting && network && Nmcli.active) {
        var activeSsid = Nmcli.active.ssid
        var targetSsid = network.ssid
        if (activeSsid.toLowerCase().trim() === targetSsid.toLowerCase().trim()) {
          connecting = false
          closeDelay.start()
        }
      }
    }
  }
}
