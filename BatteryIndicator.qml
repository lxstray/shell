import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
  id: root

  property var batteryData: null
  property bool horizontal: true

  signal clicked()

  readonly property real pct: batteryData ? batteryData.percentage : 0
  readonly property bool chg: batteryData ? batteryData.charging : false
  readonly property string profile: batteryData ? batteryData.powerProfile : "balanced"
  readonly property bool avail: batteryData ? batteryData.available : false

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }

  Item {
    anchors.centerIn: parent
    width: 18
    height: root.horizontal ? 10 : 14

    Rectangle {
      anchors.fill: parent
      anchors.rightMargin: root.horizontal ? 0 : 2
      anchors.bottomMargin: root.horizontal ? 0 : 4
      radius: 2
      color: "transparent"
      border { color: root.chg ? "#69f0ae" : "#888"; width: 1 }

      Rectangle {
        x: 1; y: 1
        width: Math.max(0, (parent.width - 2) * Math.min(1, root.pct / 100))
        height: parent.height - 2
        radius: 1
        color: {
          if (!root.avail) return "#444"
          if (root.chg) return "#69f0ae"
          if (root.pct <= 15) return "#ef5350"
          return "#eee"
        }
      }
    }

    Rectangle {
      x: parent.width - 1
      y: parent.height / 2 - 2
      width: 3
      height: 4
      radius: 1
      color: root.chg ? "#69f0ae" : "#888"
    }

    Item {
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.rightMargin: -2
      anchors.bottomMargin: -5
      width: 14
      height: 14

      Rectangle {
        anchors.fill: parent
        radius: 7
        color: "#111"
        border { color: "#333"; width: 1 }
      }

      Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 0.5
        text: {
          if (root.profile === "power-saver") return "energy_savings_leaf"
          if (root.profile === "performance") return "rocket_launch"
          return "balance"
        }
        font.family: "Material Symbols Rounded"
        font.pixelSize: 11
        color: {
          if (!root.avail) return "#444"
          if (root.profile === "power-saver") return "#66bb6a"
          if (root.profile === "performance") return "#ef5350"
          return "#4fc3f7"
        }
      }
    }
  }

  implicitHeight: root.horizontal ? 14 : 20
  implicitWidth: root.horizontal ? 24 : 22
}
