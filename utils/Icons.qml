pragma Singleton

import QtQuick
import Quickshell

Singleton {
  function getNetworkIcon(strength: int): string {
    if (strength >= 80) return "network_wifi"
    if (strength >= 60) return "network_wifi_3_bar"
    if (strength >= 40) return "network_wifi_2_bar"
    if (strength >= 20) return "network_wifi_1_bar"
    return "signal_wifi_0_bar"
  }
}
