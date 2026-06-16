import Quickshell
import QtQuick

Item {
  implicitHeight: 20
  implicitWidth: label.width + 4

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Text {
    id: label
    anchors.centerIn: parent
    text: Qt.formatDateTime(clock.date, "HH:mm")
    color: "#eee"
    font { pixelSize: 13; weight: Font.Medium }
  }
}
