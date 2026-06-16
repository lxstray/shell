//@ Env QSG_RENDER_LOOP=threaded

import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
  SettingsData {
    id: settingsData
    settingsPath: Qt.resolvedUrl("settings.json")
    Component.onCompleted: load()
  }

  IpcHandler {
    target: "launcher"
    function onSignalTriggered(signal: string, value: string) {
      if (signal === "toggle") {
        var b = barLoader.item
        if (b) b.launcherOpen = !b.launcherOpen
      }
    }
  }

  Loader {
    id: barLoader
    active: settingsData.ready
    sourceComponent: Bar {
      id: bar
      settings: settingsData
      onAppLaunched: bar.launcherOpen = false
      onCanceled: bar.launcherOpen = false
      onOpenSettings: {
        settingsPopup.show()
        settingsPopup.requestActivate()
      }
    }
  }

  SettingsWindow {
    id: settingsPopup
    settings: settingsData
    onClosing: function(close) {
      close.accepted = false
      hide()
    }
  }
}
