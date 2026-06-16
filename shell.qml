//@ Env QSG_RENDER_LOOP=threaded

import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
  IpcHandler {
    target: "launcher"
    function onSignalTriggered(signal: string, value: string) {
      if (signal === "toggle") {
        bar.launcherOpen = !bar.launcherOpen
      }
    }
  }

  Bar {
    id: bar
    onAppLaunched: bar.launcherOpen = false
    onCanceled: bar.launcherOpen = false
  }
}
