import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
  id: root

  property string wallpaperPath: ""

  color: "#111"
  screen: Quickshell.screens[0] || null

  anchors.top: true
  anchors.bottom: true
  anchors.left: true
  anchors.right: true

  WlrLayershell.layer: WlrLayer.Background
  WlrLayershell.exclusionMode: ExclusionMode.Ignore

  Image {
    x: 0
    y: 0
    width: root.screen ? root.screen.width : 0
    height: root.screen ? root.screen.height : 0
    source: root.wallpaperPath.length > 0 ? "file://" + root.wallpaperPath : ""
    fillMode: Image.PreserveAspectCrop
    visible: source.length > 0
  }
}
