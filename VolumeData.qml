import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property real level: 0
  property bool muted: false
  property string icon: "volume_up"

  FileView {
    id: volFile
    path: "/tmp/qs-vol.txt"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      var raw = text().trim()
      var m = raw.match(/(\d+\.\d+)/)
      if (m) {
        var val = parseFloat(m[1])
        if (!isNaN(val) && root.level !== val) root.level = val
      }
      root.muted = raw.indexOf("MUTED") !== -1
    }
  }

  Timer {
    interval: 300
    running: true
    repeat: true
    onTriggered: {
      Quickshell.execDetached(["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ > /tmp/qs-vol.txt 2>&1"])
    }
  }
}
