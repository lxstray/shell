import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property string barPosition: "top"
  property string barStyle: "island"
  property string currentWallpaper: ""
  property var wallpaperHistory: []
  property bool ready: false

  property string settingsPath: ""

  FileView {
    id: fileView
    onLoaded: applySettings()
    onLoadFailed: root.ready = true
  }

  function startSwaybg(path) {
    Quickshell.execDetached(["sh", "-c", "pkill -x swaybg 2>/dev/null; swaybg -i '" + path + "' -m fill &"])
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
        if (obj.currentWallpaper) {
          root.currentWallpaper = obj.currentWallpaper
          startSwaybg(obj.currentWallpaper)
        }
        if (obj.wallpaperHistory) root.wallpaperHistory = obj.wallpaperHistory
      } catch (e) {}
    }
    root.ready = true
  }

  function save() {
    if (root.settingsPath.length === 0) return
    var obj = {
      barPosition: root.barPosition,
      barStyle: root.barStyle,
      currentWallpaper: root.currentWallpaper,
      wallpaperHistory: root.wallpaperHistory
    }
    fileView.path = root.settingsPath
    fileView.setText(JSON.stringify(obj, null, 2) + "\n")
  }

  function setWallpaper(path) {
    root.currentWallpaper = path
    startSwaybg(path)
    var idx = root.wallpaperHistory.indexOf(path)
    if (idx !== -1) root.wallpaperHistory.splice(idx, 1)
    root.wallpaperHistory.unshift(path)
    if (root.wallpaperHistory.length > 20) root.wallpaperHistory = root.wallpaperHistory.slice(0, 20)
    save()
  }
}
