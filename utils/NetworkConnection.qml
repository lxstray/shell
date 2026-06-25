pragma Singleton

import QtQuick
import "../services"

QtObject {
  id: root

  function handleConnect(network, onPasswordNeeded): void {
    if (!network) return

    if (Nmcli.active && Nmcli.active.ssid !== network.ssid) {
      Nmcli.disconnectFromNetwork()
      Qt.callLater(() => root.tryConnect(network, onPasswordNeeded))
    } else {
      root.tryConnect(network, onPasswordNeeded)
    }
  }

  function tryConnect(network, onPasswordNeeded): void {
    if (!network) return

    if (network.isSecure) {
      Nmcli.connectToNetwork(network.ssid, "", network.bssid, result => {
        if (result.needsPassword) {
          if (onPasswordNeeded) onPasswordNeeded(network)
        }
      })
    } else {
      Nmcli.connectToNetwork(network.ssid, "", network.bssid, null)
    }
  }

  function connectWithPassword(network, password, onResult): void {
    if (!network) return
    Nmcli.connectToNetwork(network.ssid, password ?? "", network.bssid ?? "", onResult ?? null)
  }
}
