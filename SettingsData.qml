import QtQuick
import Quickshell.Io

Item {
  id: root

  property string barPosition: "top"
  property string barStyle: "island"
  property bool ready: false

  property string settingsPath: ""

  FileView {
    id: fileView
    onLoaded: applySettings()
    onLoadFailed: root.ready = true
  }

  function load() {
    if (root.settingsPath.length === 0) {
      root.ready = true
      return
    }
    fileView.path = root.settingsPath
  }

  function applySettings() {
    var raw = fileView.text()
    if (raw.length > 0) {
      try {
        var obj = JSON.parse(raw)
        if (obj.barPosition) root.barPosition = obj.barPosition
        if (obj.barStyle) root.barStyle = obj.barStyle
      } catch (e) {}
    }
    root.ready = true
  }

  function save() {
    if (root.settingsPath.length === 0) return
    var obj = {
      barPosition: root.barPosition,
      barStyle: root.barStyle
    }
    fileView.path = root.settingsPath
    fileView.setText(JSON.stringify(obj, null, 2) + "\n")
  }
}
