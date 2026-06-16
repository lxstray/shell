import Quickshell
import QtQuick
Item {
  Component.onCompleted: {
    // Test various icon names
    var icons = [
      "preferences-system", "emblem-system", "applications-utilities",
      "application-x-executable", "application-default-icon",
      "system-run", "computer", "folder", "document",
      "text-x-generic", "unknown"
    ]
    for (var i = 0; i < icons.length; i++) {
      var p = Quickshell.iconPath(icons[i])
      print(icons[i] + " => " + (p.length > 0 ? p : "NOT FOUND"))
    }
    Qt.quit()
  }
}
