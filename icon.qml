import Quickshell
import QtQuick
Item {
  Component.onCompleted: {
    var names = [
      "preferences-system",
      "emblem-system",
      "applications-utilities",
      "input-keyboard",
      "computer",
      "system-run"
    ]
    for (var i = 0; i < names.length; i++) {
      var p = Quickshell.iconPath(names[i], 48)
      print(names[i] + " -> " + (p.length > 0 ? p : "NOT FOUND"))
    }
    Qt.quit()
  }
}
