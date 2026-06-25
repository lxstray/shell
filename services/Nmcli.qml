pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property list<AccessPoint> networks: []
  readonly property AccessPoint active: networks.find(n => n.active) ?? null
  property bool wifiEnabled: true
  readonly property bool scanning: rescanProc.running
  property string activeInterface: ""

  property real rxBytes: 0
  property real txBytes: 0
  property real rxSpeed: 0
  property real txSpeed: 0

  signal connectionFailed(string ssid)

  function executeCommand(args: list<string>, callback: var): void {
    const proc = cmdComp.createObject(root)
    proc.cmdArgs = ["nmcli", ...args]
    proc.callback = callback
    Qt.callLater(() => proc.exec(proc.cmdArgs))
  }

  function enableWifi(enabled: bool, callback: var): void {
    executeCommand(["radio", "wifi", enabled ? "on" : "off"], result => {
      if (result.success) { root.wifiEnabled = enabled }
      if (callback) callback(result)
    })
  }

  function rescanWifi(): void {
    rescanProc.running = true
  }

  function getNetworks(callback: var): void {
    executeCommand(["-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"], result => {
      if (!result.success) { if (callback) callback([]); return }

      const parsed = parseNetworks(result.output)
      const deduped = deduplicate(parsed)
      const rNetworks = root.networks

      const newKeys = new Set(deduped.map(n => `${n.frequency}:${n.ssid}:${n.bssid}`))

      for (let i = rNetworks.length - 1; i >= 0; i--) {
        const rn = rNetworks[i]
        if (!newKeys.has(`${rn.frequency}:${rn.ssid}:${rn.bssid}`)) {
          rNetworks.splice(i, 1)
          rn.destroy()
        }
      }

      const existing = new Map()
      for (const rn of rNetworks) existing.set(`${rn.frequency}:${rn.ssid}:${rn.bssid}`, rn)

      for (const n of deduped) {
        const key = `${n.frequency}:${n.ssid}:${n.bssid}`
        if (existing.has(key)) {
          existing.get(key).lastIpcObject = n
        } else {
          rNetworks.push(apComp.createObject(root, { lastIpcObject: n }))
        }
      }

      if (callback) callback(root.networks)
    })
  }

  function connectToNetwork(ssid: string, password: string, bssid: string, callback: var): void {
    if (password && password.length > 0) {
      if (bssid && bssid.length > 0) {
        createConnection(ssid, bssid, password, result => {
          if (callback) callback(result)
        })
        return
      }
      executeCommand(["device", "wifi", "connect", ssid, "password", password], result => {
        if (callback) callback(result)
      })
    } else {
      executeCommand(["device", "wifi", "connect", ssid], result => {
        if (result.success) {
          if (callback) callback(result)
        } else {
          const needsPw = result.error && (result.error.includes("Secrets") || result.error.includes("password"))
          if (callback) callback({ success: result.success, output: result.output, error: result.error, exitCode: result.exitCode, needsPassword: needsPw })
        }
      })
    }
  }

  function createConnection(ssid: string, bssid: string, password: string, callback: var): void {
    executeCommand(["connection", "delete", ssid], () => {})
    createConnTimer.ssid = ssid
    createConnTimer.bssid = bssid
    createConnTimer.password = password
    createConnTimer.callback = callback
    createConnTimer.step = 1
    createConnTimer.start()
  }

  Timer {
    id: createConnTimer
    property string ssid: ""
    property string bssid: ""
    property string password: ""
    property var callback: null
    property int step: 0
    interval: 300
    repeat: false
    onTriggered: {
      if (step === 1) {
        executeCommand([
          "connection", "add", "type", "802-11-wireless",
          "con-name", ssid, "ifname", "*", "ssid", ssid,
          "802-11-wireless.bssid", bssid.toUpperCase(),
          "802-11-wireless-security.key-mgmt", "wpa-psk",
          "802-11-wireless-security.psk", password
        ], addResult => {
          if (addResult.success) {
            step = 2
            start()
          } else if (callback) callback(addResult)
        })
      } else if (step === 2) {
        executeCommand(["connection", "up", ssid], callback)
      }
    }
  }

  function disconnectFromNetwork(): void {
    if (active?.ssid) {
      executeCommand(["connection", "down", active.ssid], () => getNetworks(() => {}))
    } else {
      executeCommand(["device", "disconnect", "wifi"], () => getNetworks(() => {}))
    }
  }

  function hasSavedProfile(ssid: string): bool {
    if (!ssid) return false
    const lower = ssid.toLowerCase().trim()
    for (const n of root.networks) {
      if (n.active && n.ssid.toLowerCase().trim() === lower) return true
    }
    return false
  }

  function parseNetworks(output: string): list<var> {
    if (!output) return []
    const PH = "@PH@"
    const esc = new RegExp("\\\\:", "g")
    const unesc = new RegExp(PH, "g")
    return output.trim().split("\n")
      .filter(l => l)
      .map(l => {
        const p = l.replace(esc, PH).split(":")
        return {
          active: p[0] === "yes",
          strength: parseInt(p[1]) || 0,
          frequency: parseInt(p[2]) || 0,
          ssid: (p[3]?.replace(unesc, ":") ?? "").trim(),
          bssid: (p[4]?.replace(unesc, ":") ?? "").trim(),
          security: (p[5] ?? "").trim()
        }
      })
      .filter(n => n.ssid)
  }

  function deduplicate(networks: list<var>): list<var> {
    const map = new Map()
    for (const n of networks) {
      const e = map.get(n.ssid)
      if (!e) { map.set(n.ssid, n) }
      else if (n.active && !e.active) { map.set(n.ssid, n) }
      else if (!n.active && !e.active && n.strength > e.strength) { map.set(n.ssid, n) }
    }
    return Array.from(map.values())
  }

  function refreshNetworks(): void {
    getNetworks(() => {})
    updateActiveInterface()
  }

  function updateActiveInterface(): void {
    executeCommand(["-t", "-f", "DEVICE,TYPE,STATE", "device", "status"], r => {
      if (!r.success) return
      const lines = r.output.trim().split("\n")
      for (const line of lines) {
        const parts = line.split(":")
        if (parts[1] === "wifi" && parts[2] === "connected") {
          root.activeInterface = parts[0]
          return
        }
      }
      root.activeInterface = ""
    })
  }

  Component.onCompleted: {
    executeCommand(["radio", "wifi"], r => {
      if (r.success) root.wifiEnabled = r.output.trim() === "enabled"
    })
    getNetworks(() => {})
    updateActiveInterface()
  }

  Component {
    id: cmdComp
    CommandProcess {}
  }

  Component {
    id: apComp
    AccessPoint {}
  }

  Process {
    id: rescanProc
    command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
    onExited: root.getNetworks()
  }

  Process {
    id: monitorProc
    running: true
    command: ["nmcli", "monitor"]
    environment: ({ LANG: "C.UTF-8", LC_ALL: "C.UTF-8" })
    stdout: SplitParser { onRead: root.refreshNetworks() }
    onExited: restartTimer.start()
  }

  Timer {
    id: restartTimer
    interval: 2000
    onTriggered: { monitorProc.running = true }
  }

  function updateSpeed(): void {
    if (!root.activeInterface) {
      root.rxSpeed = 0
      root.txSpeed = 0
      return
    }
    speedProc.running = true
  }

  Process {
    id: speedProc
    property real prevRx: 0
    property real prevTx: 0
    command: ["sh", "-c", "cat /sys/class/net/" + root.activeInterface + "/statistics/rx_bytes /sys/class/net/" + root.activeInterface + "/statistics/tx_bytes 2>/dev/null || true"]
    stdout: StdioCollector { id: speedOut }
    onExited: {
      if (!speedOut.text) { running = false; return }
      const lines = speedOut.text.trim().split("\n")
      if (lines.length < 2) { root.rxSpeed = 0; root.txSpeed = 0; return }
      const rx = parseFloat(lines[0]) || 0
      const tx = parseFloat(lines[1]) || 0
      if (speedProc.prevRx > 0) {
        root.rxSpeed = Math.max(0, (rx - speedProc.prevRx))
        root.txSpeed = Math.max(0, (tx - speedProc.prevTx))
      }
      speedProc.prevRx = rx
      speedProc.prevTx = tx
      root.rxBytes = rx
      root.txBytes = tx
      running = false
    }
  }

  Timer {
    id: speedTimer
    interval: 1000
    repeat: true
    running: true
    onTriggered: root.updateSpeed()
  }

  component CommandProcess: Process {
    id: proc
    property var callback: null
    property list<string> cmdArgs: []

    environment: ({ LANG: "C.UTF-8", LC_ALL: "C.UTF-8" })
    stdout: StdioCollector { id: so }
    stderr: StdioCollector { id: se }

    onExited: code => {
      Qt.callLater(() => {
        if (proc.callback) {
          proc.callback({
            success: code === 0,
            output: so?.text ?? "",
            error: se?.text ?? "",
            exitCode: code,
            needsPassword: false
          })
        }
      })
    }
  }

  component AccessPoint: QtObject {
    required property var lastIpcObject
    readonly property string ssid: lastIpcObject.ssid
    readonly property string bssid: lastIpcObject.bssid
    readonly property int strength: lastIpcObject.strength
    readonly property int frequency: lastIpcObject.frequency
    readonly property bool active: lastIpcObject.active
    readonly property string security: lastIpcObject.security
    readonly property bool isSecure: security.length > 0
  }
}
