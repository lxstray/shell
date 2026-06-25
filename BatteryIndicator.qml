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

  // Horizontal mode: side by side
  RowLayout {
    id: rowH
    anchors.centerIn: parent
    spacing: 3
    visible: root.horizontal

    // Battery icon (drawn)
    Item {
      width: 18
      height: 10

      Rectangle {
        anchors.fill: parent
        radius: 2
        color: "transparent"
        border { color: root.chg ? "#4fc3f7" : "#888"; width: 1 }

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

        Text {
          anchors.centerIn: parent
          text: "\u26A1"
          color: "#111"
          font.pixelSize: 8
          visible: root.chg
        }
      }

      Rectangle {
        x: parent.width - 1
        y: parent.height / 2 - 2
        width: 3
        height: 4
        radius: 1
        color: root.chg ? "#4fc3f7" : "#888"
      }
    }

    Text {
      Layout.topMargin: 2
      Layout.rightMargin: -5
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
    }
  }

  // Vertical mode: stacked (battery on top, profile below)
  ColumnLayout {
    anchors.centerIn: parent
    spacing: 2
    visible: !root.horizontal

    Item {
      Layout.alignment: Qt.AlignHCenter
      width: 18
      height: 10

      Rectangle {
        anchors.fill: parent
        radius: 2
        color: "transparent"
        border { color: root.chg ? "#4fc3f7" : "#888"; width: 1 }

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

        Text {
          anchors.centerIn: parent
          text: "\u26A1"
          color: "#111"
          font.pixelSize: 8
          visible: root.chg
        }
      }

      Rectangle {
        x: parent.width - 1
        y: parent.height / 2 - 2
        width: 3
        height: 4
        radius: 1
        color: root.chg ? "#4fc3f7" : "#888"
      }
    }

    Text {
      Layout.alignment: Qt.AlignHCenter
      Layout.bottomMargin: -10
      text: {
        if (root.profile === "power-saver") return "energy_savings_leaf"
        if (root.profile === "performance") return "rocket_launch"
        return "balance"
      }
      font.family: "Material Symbols Rounded"
      font.pixelSize: 14
      color: {
        if (!root.avail) return "#444"
        if (root.profile === "power-saver") return "#66bb6a"
        if (root.profile === "performance") return "#ef5350"
        return "#4fc3f7"
      }
    }
  }

  implicitHeight: root.horizontal ? 20 : 28
  implicitWidth: root.horizontal ? rowH.width + 4 : 22
}
