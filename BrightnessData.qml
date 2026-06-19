import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property int rawValue: 0
  readonly property int maxBrightness: 64250
  readonly property real level: maxBrightness > 0 ? rawValue / maxBrightness : 0
  readonly property string icon: "light_mode"

  FileView {
    path: "/sys/class/backlight/amdgpu_bl1/brightness"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      var val = parseInt(text().trim())
      root.rawValue = isNaN(val) ? 0 : val
    }
    onLoadFailed: root.rawValue = 0
  }
}
