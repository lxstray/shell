import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Item {
  id: root

  property bool horizontal: true
  property var barRef: null

  readonly property var trayItems: SystemTray.items.values
  readonly property int itemCount: trayItems.length

  visible: itemCount > 0

  implicitWidth: flow.implicitWidth
  implicitHeight: flow.implicitHeight

  Flow {
    id: flow
    spacing: 2
    flow: root.horizontal ? Flow.LeftToRight : Flow.TopToBottom

    Repeater {
      model: ScriptModel {
        values: root.trayItems
      }

      delegate: TrayItem {
        trayMenuHost: root.barRef
      }
    }
  }
}
