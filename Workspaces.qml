import Quickshell
import Quickshell.Niri
import QtQuick

Item {
  property bool horizontal: true

  implicitHeight: horizontal ? 20 : column.childrenRect.height
  implicitWidth: horizontal ? row.width : 20

  Row {
    id: row
    spacing: 4
    visible: horizontal

    Repeater {
      model: Niri.workspaces

      delegate: Text {
        required property var modelData

        text: modelData.idx
        color: modelData.focused ? "#eee" : (modelData.occupied ? "#888" : "#444")
        font { pixelSize: 13; weight: Font.Medium }

        Behavior on color { ColorAnimation { duration: 120 } }

        MouseArea {
          anchors { fill: parent; margins: -4 }
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(modelData.idx)])
          }
        }
      }
    }
  }

  Column {
    id: column
    spacing: 6
    visible: !horizontal
    anchors.horizontalCenter: parent.horizontalCenter

    Repeater {
      model: Niri.workspaces

      delegate: Text {
        required property var modelData

        text: modelData.idx
        color: modelData.focused ? "#eee" : (modelData.occupied ? "#888" : "#444")
        font { pixelSize: 13; weight: Font.Medium }

        Behavior on color { ColorAnimation { duration: 120 } }

        MouseArea {
          anchors { fill: parent; margins: -4 }
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(modelData.idx)])
          }
        }
      }
    }
  }
}
