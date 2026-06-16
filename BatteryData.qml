import Quickshell
import Quickshell.Services.UPower
import QtQuick

Item {
  id: root

  readonly property QtObject device: UPower.displayDevice
  readonly property QtObject profiles: PowerProfiles

  readonly property var healthDevice: {
    for (var i = 0; i < UPower.devices.count; i++) {
      var d = UPower.devices.get(i);
      if (d.isLaptopBattery) return d;
    }
    return device;
  }

  property real percentage: device.ready && device.isPresent ? Math.round(device.percentage * 100) : 0
  property bool charging: device.ready && device.isPresent ?
    device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.FullyCharged || device.state === UPowerDeviceState.PendingCharge : false

  property string powerProfile: {
    var p = profiles.profile;
    if (p === PowerProfile.PowerSaver) return "power-saver";
    if (p === PowerProfile.Performance) return "performance";
    return "balanced";
  }

  property real health: healthDevice.ready && healthDevice.healthSupported ? Math.round(healthDevice.healthPercentage * 100) : 100
  property bool available: device.ready && device.isPresent && device.isLaptopBattery

  property string timeRemaining: ""
  property string timeToFull: ""

  function formatTime(seconds) {
    if (seconds <= 0) return "";
    var h = Math.floor(seconds / 3600);
    var m = Math.floor((seconds % 3600) / 60);
    if (h > 0) return h + "h " + m + "m";
    return m + "m";
  }

  function refreshTime() {
    if (!device.ready) return;
    timeRemaining = !root.charging && device.timeToEmpty > 0 ? formatTime(device.timeToEmpty) : "";
    timeToFull = root.charging && device.timeToFull > 0 ? formatTime(device.timeToFull) : "";
  }

  Timer {
    interval: 5000
    repeat: true
    running: root.available
    onTriggered: root.refreshTime()
  }
}
