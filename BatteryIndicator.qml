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

  implicitHeight: 20
  implicitWidth: row.width + 4

  RowLayout {
    id: row
    anchors.centerIn: parent
    spacing: 3

    // Power profile icon (horizontal mode)
    Text {
      text: {
        if (root.profile === "power-saver") return "energy_savings_leaf"
        if (root.profile === "performance") return "rocket_launch"
        return "balance"
      }
      font.family: "Material Symbols Rounded"
      font.pixelSize: 12
      color: {
        if (!root.avail) return "#444"
        if (root.profile === "power-saver") return "#66bb6a"
        if (root.profile === "performance") return "#ef5350"
        return "#4fc3f7"
      }
      visible: root.avail && root.horizontal
    }

    // Power profile indicator (vertical mode)
    Rectangle {
      width: 6; height: 6; radius: 3
      color: {
        if (!root.avail) return "#444"
        if (root.profile === "power-saver") return "#66bb6a"
        if (root.profile === "performance") return "#ef5350"
        return "#4fc3f7"
      }
      visible: root.avail && !root.horizontal
    }

    // Battery icon (drawn)
    Item {
      width: 18
      height: 10

      Rectangle {
        anchors.fill: parent
        radius: 2
        color: "transparent"
        border { color: root.chg ? "#4fc3f7" : "#888"; width: 1 }

        // Fill level
        Rectangle {
          x: 1; y: 1
          width: Math.max(0, (parent.width - 2) * Math.min(1, root.pct / 100))
          height: parent.height - 2
          radius: 1
          color: {
            if (!root.avail) return "#444"
            if (root.chg) return "#4fc3f7"
            if (root.pct <= 15) return "#ef5350"
            return "#eee"
          }
        }

        // Charging indicator
        Text {
          anchors.centerIn: parent
          text: "⚡"
          color: "#111"
          font.pixelSize: 8
          visible: root.chg && root.horizontal
        }
      }

      // Battery nub
      Rectangle {
        x: parent.width - 1
        y: parent.height / 2 - 2
        width: 3
        height: 4
        radius: 1
        color: root.chg ? "#4fc3f7" : "#888"
      }
    }

    // Percentage
    Text {
      text: root.avail ? Math.round(root.pct) + "%" : "?"
      color: root.avail ? (root.pct <= 15 ? "#ef5350" : "#eee") : "#555"
      font.pixelSize: 11
      visible: root.horizontal
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
