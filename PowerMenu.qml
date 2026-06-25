import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
  id: root

  property bool menuOpen: false
  signal closeRequested()

  property bool visuallyOpen: false
  visible: visuallyOpen
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusionMode: ExclusionMode.Ignore
  WlrLayershell.exclusiveZone: 0

  anchors.top: true
  anchors.bottom: true
  anchors.left: true
  anchors.right: true

  onMenuOpenChanged: {
    if (menuOpen) {
      visuallyOpen = true
      slideTransform.x = -(slideArea.width + 100)
      slideIn.start()
      Qt.callLater(forceActiveFocus)
    } else {
      slideOut.to = -(slideArea.width + 100)
      slideOut.start()
    }
  }

  Shortcut { sequence: "Escape"; onActivated: closeRequested() }

  MouseArea {
    anchors.fill: parent
    z: 0
    onClicked: closeRequested()
  }

  readonly property var actions: [
    { icon: "lock", label: "Lock", cmd: ["loginctl", "lock-session"] },
    { icon: "power_settings_new", label: "Shutdown", cmd: ["systemctl", "poweroff"] },
    { icon: "restart_alt", label: "Reboot", cmd: ["systemctl", "reboot"] },
    { icon: "settings", label: "UEFI", cmd: ["systemctl", "reboot", "--firmware-setup"] },
    { icon: "logout", label: "Logout", cmd: ["sh", "-c", "niri msg action quit --skip-confirmation"] }
  ]

  Item {
    id: slideArea
    anchors.fill: parent
    z: 1

    transform: Translate { id: slideTransform }

    NumberAnimation {
      id: slideIn
      target: slideTransform
      property: "x"
      to: 0
      duration: 300
      easing.type: Easing.OutCubic
    }

    NumberAnimation {
      id: slideOut
      target: slideTransform
      property: "x"
      duration: 300
      easing.type: Easing.InCubic
      onFinished: visuallyOpen = false
    }

    RowLayout {
      anchors.centerIn: parent
      spacing: 16

      Repeater {
        model: root.actions

        delegate: Item {
          required property var modelData
          required property int index

          Layout.preferredWidth: 110
          Layout.preferredHeight: 110

          Rectangle {
            anchors.fill: parent
            radius: 16
            color: mouseArea.containsMouse ? "#333" : "#1a1a1a"
            border { color: mouseArea.containsMouse ? "#eee" : "#333"; width: 1 }

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            ColumnLayout {
              anchors.centerIn: parent
              spacing: 8

              Text {
                Layout.alignment: Qt.AlignHCenter
                text: modelData.icon
                font.family: "Material Symbols Rounded"
                font.pixelSize: 34
                color: mouseArea.containsMouse ? "#fff" : "#aaa"

                Behavior on color { ColorAnimation { duration: 150 } }
              }

              Text {
                Layout.alignment: Qt.AlignHCenter
                text: modelData.label
                font.pixelSize: 12
                color: mouseArea.containsMouse ? "#fff" : "#888"

                Behavior on color { ColorAnimation { duration: 150 } }
              }
            }
          }

          MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              var p = cmdComp.createObject(root)
              p.command = modelData.cmd
              p.running = true
              closeRequested()
            }
          }
        }
      }
    }
  }

  Component {
    id: cmdComp
    Process {}
  }
}
