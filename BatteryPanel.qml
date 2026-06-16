import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

Item {
  id: root

  property var batteryData: null
  property bool open: false
  property string barPosition: "top"

  readonly property real pct: batteryData ? batteryData.percentage : 0
  readonly property bool chg: batteryData ? batteryData.charging : false
  readonly property string profile: batteryData ? batteryData.powerProfile : "balanced"
  readonly property bool avail: batteryData ? batteryData.available : false
  readonly property real health: batteryData ? batteryData.health : 100
  readonly property bool isHorizontal: barPosition === "top" || barPosition === "bottom"

  signal canceled()

  clip: true
  visible: root.open

  Keys.onEscapePressed: canceled()

  Rectangle {
    anchors.fill: parent
    color: "#111"

    opacity: root.open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
    radius: 10

    Item {
      anchors.fill: parent
      anchors.margins: 8

      ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Header
        RowLayout {
          Layout.fillWidth: true
          spacing: 12

          Item {
            width: 40
            height: 22

            Rectangle {
              anchors.fill: parent
              radius: 5
              color: "transparent"
              border { color: root.chg ? "#4fc3f7" : "#888"; width: 2 }

              Rectangle {
                x: 2; y: 2
                width: Math.max(0, (parent.width - 4) * Math.min(1, root.pct / 100))
                height: parent.height - 4
                radius: 3
                color: root.chg ? "#4fc3f7" : (root.pct <= 15 ? "#ef5350" : "#eee")
              }

              Text {
                anchors.centerIn: parent
                text: "\u26A1"
                color: "#111"
                font.pixelSize: 16
                visible: root.chg
              }
            }

            Rectangle {
              x: parent.width - 2
              y: parent.height / 2 - 4
              width: 6
              height: 8
              radius: 1
              color: root.chg ? "#4fc3f7" : "#888"
            }
          }

          Text {
            text: Math.round(root.pct) + "%"
            color: "#eee"
            font { pixelSize: 30; weight: Font.Medium }
          }

          Item { Layout.fillWidth: true }

          Text {
            text: root.chg ? "Charging" : "Discharging"
            color: root.chg ? "#4fc3f7" : "#888"
            font.pixelSize: 14
            visible: root.avail
          }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: "#333"
        }

        GridLayout {
          columns: 2
          columnSpacing: 16
          rowSpacing: 6
          Layout.fillWidth: true

          Text { text: "Health"; color: "#888"; font.pixelSize: 14 }
          Text {
            text: Math.round(root.health) + "%"
            color: root.health < 80 ? "#ef5350" : "#eee"
            font.pixelSize: 14
          }

          Text { text: root.chg ? "Time to full" : "Time left"; color: "#888"; font.pixelSize: 14 }
          Text {
            text: {
              if (!root.avail) return "N/A"
              if (root.chg) return root.batteryData.timeToFull || "Calculating..."
              return root.batteryData.timeRemaining || "Calculating..."
            }
            color: "#eee"
            font.pixelSize: 14
          }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: "#333"
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 8

          Text {
            text: "Power Plan"
            color: "#888"
            font { pixelSize: 12; letterSpacing: 0.5 }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 6

            ProfileButton {
              Layout.fillWidth: true
              Layout.preferredHeight: 52
              label: "Saver"
              iconText: "energy_savings_leaf"
              active: root.profile === "power-saver"
              activeColor: "#66bb6a"
              onClicked: PowerProfiles.profile = PowerProfile.PowerSaver
            }

            ProfileButton {
              Layout.fillWidth: true
              Layout.preferredHeight: 52
              label: "Balanced"
              iconText: "balance"
              active: root.profile === "balanced"
              activeColor: "#4fc3f7"
              onClicked: PowerProfiles.profile = PowerProfile.Balanced
            }

            ProfileButton {
              Layout.fillWidth: true
              Layout.preferredHeight: 52
              label: "Perf"
              iconText: "rocket_launch"
              active: root.profile === "performance"
              activeColor: "#ef5350"
              onClicked: PowerProfiles.profile = PowerProfile.Performance
            }
          }
        }
      }
    }
  }

  component ProfileButton: Item {
    id: btn
    property string label: ""
    property string iconText: ""
    property bool active: false
    property string activeColor: "#888"
    signal clicked()

    Rectangle {
      anchors.fill: parent
      radius: 10
      color: btn.active ? Qt.rgba(0, 0, 0, 0.15) : "#2a2a2a"
      border { color: btn.active ? btn.activeColor : "#333"; width: 1 }

      ColumnLayout {
        anchors.centerIn: parent
        spacing: 4

        Text {
          text: btn.iconText
          font.family: "Material Symbols Rounded"
          font.pixelSize: 22
          color: btn.active ? btn.activeColor : "#666"
          Layout.alignment: Qt.AlignHCenter
        }

        Text {
          text: btn.label
          color: btn.active ? btn.activeColor : "#888"
          font.pixelSize: 11
          Layout.alignment: Qt.AlignHCenter
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: btn.clicked()
    }
  }
}
