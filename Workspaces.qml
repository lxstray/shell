import Quickshell
import Quickshell.Niri
import QtQuick

Item {
  implicitHeight: 20
  implicitWidth: row.width

  Row {
    id: row
    spacing: 4

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
