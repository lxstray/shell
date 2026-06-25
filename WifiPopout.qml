import QtQuick
import QtQuick.Layouts
import Quickshell
import "services"
import "utils"

Item {
  id: root

  property bool open: false
  property bool connecting: false
  property string connectingToSsid: ""
  property var passwordNetwork: null
  property bool showPasswordDialog: false

  signal openPasswordDialog(var network)
  signal closeRequested()

  visible: open
  enabled: open

  Keys.onEscapePressed: closeRequested()

  Rectangle {
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors.fill: parent
      anchors.topMargin: 8
      anchors.leftMargin: 12
      anchors.rightMargin: 12
      anchors.bottomMargin: 8
      spacing: 6

      // Header with back button
      RowLayout {
        Layout.fillWidth: true
        spacing: 4

        Text {
          text: "arrow_back"
          font.family: "Material Symbols Rounded"
          font.pixelSize: 20
          color: "#aaa"

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: closeRequested()
          }
        }

        Text {
          text: "Wireless"
          font.pixelSize: 14
          font.weight: Font.Medium
          color: "#eee"
          Layout.leftMargin: 4
        }

        Item { Layout.fillWidth: true }

        Text {
          text: "wifi"
          font.family: "Material Symbols Rounded"
          font.pixelSize: 18
          color: Nmcli.wifiEnabled ? "#eee" : "#555"
        }
      }

      // Spacer
      Item { Layout.preferredHeight: 4 }

      // Wifi toggle
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
          text: "Enabled"
          color: "#ccc"
          font.pixelSize: 13
          Layout.fillWidth: true
        }

        Rectangle {
          id: toggleBg
          width: 44
          height: 24
          radius: 12
          color: Nmcli.wifiEnabled ? "#4CAF50" : "#555"

          Behavior on color {
            ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
          }

          Rectangle {
            x: Nmcli.wifiEnabled ? parent.width - width - 2 : 2
            y: 2
            width: 20
            height: 20
            radius: 10
            color: "#fff"

            Behavior on x {
              NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Nmcli.enableWifi(!Nmcli.wifiEnabled)
          }
        }
      }

      // Connection info
      ColumnLayout {
        Layout.fillWidth: true
        visible: Nmcli.wifiEnabled && Nmcli.activeInterface.length > 0
        spacing: 2

        Text {
          text: "Connected: " + (Nmcli.active?.ssid ?? Nmcli.activeInterface)
          color: "#ccc"
          font.pixelSize: 12
          font.weight: Font.Medium
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 16

          RowLayout {
            spacing: 4

            Text {
              text: "arrow_downward"
              font.family: "Material Symbols Rounded"
              font.pixelSize: 12
              color: "#aaa"
            }

            Text {
              text: formatSpeed(Nmcli.rxSpeed)
              color: "#888"
              font.pixelSize: 11
            }
          }

          RowLayout {
            spacing: 4

            Text {
              text: "arrow_upward"
              font.family: "Material Symbols Rounded"
              font.pixelSize: 12
              color: "#aaa"
            }

            Text {
              text: formatSpeed(Nmcli.txSpeed)
              color: "#888"
              font.pixelSize: 11
            }
          }
        }
      }

      // Networks
      Text {
        text: Nmcli.networks.length + " networks available"
        color: "#999"
        font.pixelSize: 11
        visible: Nmcli.wifiEnabled
      }

      ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: Nmcli.wifiEnabled
        clip: true

        model: {
          const nets = []
          for (const n of Nmcli.networks)
            nets.push(n)
          nets.sort((a, b) => {
            if (a.active !== b.active) return b.active - a.active
            return b.strength - a.strength
          })
          return nets.slice(0, 8)
        }

        delegate: Item {
          id: netItem
          width: ListView.view.width
          height: 40

          required property var modelData
          readonly property bool isActive: modelData.active
          readonly property bool isConnecting: root.connectingToSsid === modelData.ssid

          opacity: 0
          scale: 0.7

          Component.onCompleted: { opacity = 1; scale = 1 }

          Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
          }
          Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
          }

          Rectangle {
            anchors.fill: parent
            radius: 8
            color: netItem.isActive ? Qt.rgba(1, 1, 1, 0.1) : "transparent"

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              enabled: !root.connecting
              onClicked: {
                if (netItem.isActive) {
                  Nmcli.disconnectFromNetwork()
                } else {
                  const r = root
                  root.connectingToSsid = modelData.ssid
                  root.connecting = true
                  NetworkConnection.handleConnect(modelData, network => {
                    r.passwordNetwork = network
                    r.showPasswordDialog = true
                    r.openPasswordDialog(network)
                    r.connecting = false
                  })
                }
              }
            }
          }

          RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            spacing: 6

            Text {
              text: Icons.getNetworkIcon(modelData.strength)
              font.family: "Material Symbols Rounded"
              font.pixelSize: 18
              color: netItem.isActive ? "#ccc" : "#aaa"
            }

            Text {
              visible: modelData.isSecure
              text: "lock"
              font.family: "Material Symbols Rounded"
              font.pixelSize: 11
              color: "#888"
            }

            Text {
              Layout.fillWidth: true
              text: modelData.ssid
              elide: Text.ElideRight
              font.pixelSize: 12
              font.weight: netItem.isActive ? Font.Medium : Font.Normal
              color: netItem.isActive ? "#ccc" : "#ddd"
            }

            Rectangle {
              implicitWidth: 26
              implicitHeight: 26
              radius: 13
              color: netItem.isActive ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.05)
              visible: !netItem.isConnecting

              Text {
                anchors.centerIn: parent
                text: netItem.isActive ? "link_off" : "link"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 14
                color: netItem.isActive ? "#ccc" : "#888"
              }
            }

            Item {
              width: 26
              height: 26
              visible: netItem.isConnecting

              Rectangle {
                anchors.centerIn: parent
                width: 14
                height: 14
                radius: 7
                color: "transparent"
                border.width: 2
                border.color: "#ccc"
                NumberAnimation on rotation {
                  from: 0; to: 360; duration: 800; loops: Animation.Infinite
                }
              }
            }
          }
        }
      }

      // Rescan button
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 34
        radius: 17
        visible: Nmcli.wifiEnabled
        color: Qt.rgba(1, 1, 1, 0.08)

        RowLayout {
          anchors.centerIn: parent
          spacing: 6
          visible: !Nmcli.scanning

          Text {
            text: "wifi_find"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 15
            color: "#ccc"
          }
          Text {
            text: "Rescan networks"
            font.pixelSize: 12
            color: "#ccc"
          }
        }

        Item {
          anchors.centerIn: parent
          width: 16
          height: 16
          visible: Nmcli.scanning

          Rectangle {
            anchors.centerIn: parent
            width: 14
            height: 14
            radius: 7
            color: "transparent"
            border.width: 2
            border.color: "#ccc"
            NumberAnimation on rotation {
              from: 0; to: 360; duration: 800; loops: Animation.Infinite
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          enabled: !Nmcli.scanning
          onClicked: Nmcli.rescanWifi()
        }
      }
    }
  }

  function formatSpeed(bytesPerSec: real): string {
    if (bytesPerSec < 1024) return bytesPerSec.toFixed(0) + " B/s"
    if (bytesPerSec < 1048576) return (bytesPerSec / 1024).toFixed(1) + " KB/s"
    return (bytesPerSec / 1048576).toFixed(1) + " MB/s"
  }

  Connections {
    target: Nmcli
    function onActiveChanged() {
      if (Nmcli.active && root.connectingToSsid === Nmcli.active.ssid) {
        root.connectingToSsid = ""
        root.connecting = false
      }
    }
  }
}
