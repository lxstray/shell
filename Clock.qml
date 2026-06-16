import Quickshell
import QtQuick

Item {
  property bool horizontal: true

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  readonly property string hours: Qt.formatDateTime(clock.date, "HH")
  readonly property string minutes: Qt.formatDateTime(clock.date, "mm")

  implicitHeight: horizontal ? 20 : (verticalLayout.height)
  implicitWidth: horizontal ? label.width + 4 : (verticalLayout.width)

  Text {
    id: label
    anchors.centerIn: parent
    text: hours + ":" + minutes
    color: "#eee"
    font { pixelSize: 13; weight: Font.Medium }
    visible: horizontal
  }

  Column {
    id: verticalLayout
    anchors.centerIn: parent
    spacing: 2
    visible: !horizontal

    Text {
      text: hours
      color: "#eee"
      font { pixelSize: 13; weight: Font.Medium }
      horizontalAlignment: Text.AlignHCenter
    }

    Text {
      text: minutes
      color: "#eee"
      font { pixelSize: 13; weight: Font.Medium }
      horizontalAlignment: Text.AlignHCenter
    }
  }
}
