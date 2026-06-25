import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Pipewire

Item {
  id: root

  property bool open: false

  signal closeRequested()

  visible: open
  enabled: open

  Keys.onEscapePressed: closeRequested()

  // ── Real-time from Pipewire ──
  readonly property var pwSink: Pipewire.defaultAudioSink
  readonly property real masterVolume: pwSink?.audio?.volume ?? 0
  readonly property bool masterMuted: pwSink?.audio?.muted ?? false
  readonly property string defaultSinkName: pwSink?.name ?? ""

  property var sinks: []
  property var streams: []
  property var devices: []
  property bool deviceDropdownOpen: false
  property var _pendingVols: ({})
  property var clientNames: ({})
  property int muteRev: 0

  function setStreamVolume(idx, vol) {
    root._pendingVols[idx] = vol
    Quickshell.execDetached(["sh", "-c",
      "pactl set-sink-input-volume " + idx + " " + Math.round(vol * 100) + "%"
    ])
  }

  // ── Icon lookup ──
  function findIcon(name, binary, appName) {
    const candidates = []
    if (name && name.length > 0) candidates.push(name)
    if (binary && binary.length > 0) {
      candidates.push(binary)
      // Strip common suffixes
      const s = binary.replace(/-bin$/, "").replace(/\.bin$/, "")
      if (s !== binary) candidates.push(s)
    }
    if (appName && appName.length > 0) {
      candidates.push(appName.toLowerCase())
    }
    const dirs = [
      "/usr/share/icons/hicolor/32x32/apps/",
      "/usr/share/icons/hicolor/48x48/apps/",
      "/usr/share/icons/hicolor/scalable/apps/",
      "/usr/share/pixmaps/"
    ]
    for (const c of candidates) {
      for (const d of dirs) {
        for (const ext of [".png", ".svg", ".xpm"]) {
          const path = d + c + ext
          if (Qt.resolvedUrl(path).toString().length > 0) {
            // Quick existence check via XMLHttpRequest HEAD
          }
        }
      }
    }
    return ""
  }

  function buildDevices() {
    const list = []
    for (const s of root.sinks) {
      if (s.ports.length > 1) {
        for (const p of s.ports) {
          list.push({
            type: "port", sinkName: s.name, portName: p.name,
            label: p.description, available: p.available,
            volume: s.volume, muted: s.muted
          })
        }
      } else {
        list.push({
          type: "sink", sinkName: s.name, portName: s.activePort,
          label: s.description || s.name, available: true,
          volume: s.volume, muted: s.muted
        })
      }
    }
    root.devices = list
  }

  function isActive(dev) {
    if (dev.type === "port") {
      const s = root.sinks.find(n => n.name === dev.sinkName)
      return dev.sinkName === root.defaultSinkName && s && dev.portName === s.activePort
    }
    return dev.sinkName === root.defaultSinkName
  }

  function volumeIcon(vol, muted) {
    if (muted || vol === 0) return "volume_off"
    if (vol > 0.66) return "volume_up"
    if (vol > 0.33) return "volume_down"
    return "volume_mute"
  }

  // ── pactl parsing ──
  function parseSinks(text) {
    const result = []
    let current = null
    for (const line of text.split("\n")) {
      if (/^Sink\s+#/.test(line)) {
        if (current) result.push(current)
        current = { name: "", description: "", volume: 0, muted: false, activePort: "", ports: [] }
      } else if (current) {
        let m
        if (m = line.match(/^\s*Name:\s+(.+)/))
          current.name = m[1]
        else if (m = line.match(/^\s*Description:\s+(.+)/))
          current.description = m[1]
        else if (m = line.match(/^\s*Volume:.+?(\d+)%/))
          current.volume = parseInt(m[1]) / 100
        else if (m = line.match(/^\s*Mute:\s+(yes|no)/))
          current.muted = m[1] === "yes"
        else if (m = line.match(/^\s*Active Port:\s+(.+)/))
          current.activePort = m[1]
        else if (m = line.match(/^\s*(\S+):\s+(.+?)\s*\(/))
          current.ports.push({ name: m[1], description: m[2], available: line.indexOf("available") !== -1 })
      }
    }
    if (current) result.push(current)
    result.sort((a, b) => (a.description || a.name).localeCompare(b.description || b.name))
    return result
  }

  function parseStreams(text) {
    const result = []
    let current = null
    for (const line of text.split("\n")) {
      if (/^Sink\s+Input\s+#/.test(line)) {
        if (current && (current.appName.length > 0 || current.binary.length > 0 || current.clientId > 0)) result.push(current)
        current = { index: 0, volume: 0, muted: false, appName: "", iconName: "", binary: "", mediaName: "", clientId: 0 }
        const m = line.match(/#(\d+)/)
        if (m) current.index = parseInt(m[1])
      } else if (current) {
        let m
        if (m = line.match(/^\s*Client:\s+(\d+)/))
          current.clientId = parseInt(m[1])
        else if (m = line.match(/^\s*Volume:.+?(\d+)%/))
          current.volume = parseInt(m[1]) / 100
        else if (m = line.match(/^\s*Mute:\s+(yes|no)/))
          current.muted = m[1] === "yes"
        else if (m = line.match(/^\s*application\.name\s*=\s*"(.+)"/))
          current.appName = m[1]
        else if (m = line.match(/^\s*application\.icon\.name\s*=\s*"(.+)"/))
          current.iconName = m[1]
        else if (m = line.match(/^\s*application\.process\.binary\s*=\s*"(.+)"/))
          current.binary = m[1]
        else if (m = line.match(/^\s*module-stream-restore\.id\s*=\s*"sink-input-by-application-name:(.+)"$/))
          current.appName = current.appName || m[1]
        else if (m = line.match(/^\s*media\.name\s*=\s*"(.+)"/))
          current.mediaName = m[1]
      }
    }
    if (current && (current.appName.length > 0 || current.binary.length > 0 || current.clientId > 0)) result.push(current)
    result.sort((a, b) => (a.appName || a.binary || "Untitled").localeCompare(b.appName || b.binary || "Untitled"))
    return result
  }

  function parseClients(text) {
    const map = {}
    const blocks = text.split(/(?=^Client\s+#)/m)
    for (const block of blocks) {
      const idm = block.match(/^Client\s+#(\d+)/m)
      const namem = block.match(/application\.name\s*=\s*"(.+)"/)
      if (idm && namem) map[parseInt(idm[1])] = namem[1]
    }
    return map
  }

  // ── Poll pactl ──
  Timer {
    interval: 600
    running: true
    repeat: true
    onTriggered: {
      Quickshell.execDetached(["sh", "-c", "pactl list sinks > /tmp/qs-sinks.tmp && mv /tmp/qs-sinks.tmp /tmp/qs-sinks.txt"])
      Quickshell.execDetached(["sh", "-c", "pactl list sink-inputs > /tmp/qs-streams.tmp && mv /tmp/qs-streams.tmp /tmp/qs-streams.txt"])
      Quickshell.execDetached(["sh", "-c", "pactl list clients > /tmp/qs-clients.tmp && mv /tmp/qs-clients.tmp /tmp/qs-clients.txt"])
      Qt.callLater(function() {
        sinksFile.reload()
        clientsFile.reload()
      })
    }
  }

  FileView {
    id: sinksFile
    path: "/tmp/qs-sinks.txt"
    watchChanges: true
    onLoaded: {
      const t = text().trim()
      if (t.length > 0) {
        root.sinks = parseSinks(t)
        buildDevices()
      }
    }
  }

  FileView {
    id: clientsFile
    path: "/tmp/qs-clients.txt"
    onLoaded: {
      const t = text().trim()
      if (t.length > 0) root.clientNames = parseClients(t)
      streamsFile.reload()
    }
  }

  FileView {
    id: streamsFile
    path: "/tmp/qs-streams.txt"
    onLoaded: {
      const t = text().trim()
      if (t.length > 0) {
        const fresh = parseStreams(t)
        for (const f of fresh) {
          if (!f.appName && !f.binary && f.clientId > 0 && root.clientNames[f.clientId])
            f.appName = root.clientNames[f.clientId]
        }
        const pv = root._pendingVols
        const freshMap = {}
        const seen = new Set()
        for (const f of fresh) { freshMap[f.index] = f; seen.add(f.index) }
        let mutated = false
        for (let i = 0; i < root.streams.length; i++) {
          const e = root.streams[i]
          const f = freshMap[e.index]
          if (f) {
            if (e.index in pv) e.volume = pv[e.index]
            else e.volume = f.volume
            const prevPactlMuted = e._prevPactlMuted
            e._prevPactlMuted = f.muted
            if (prevPactlMuted !== undefined && prevPactlMuted !== f.muted) {
              e.muted = f.muted
              var ditem = streamList.itemAtIndex(root.streams.indexOf(e))
              if (ditem) { ditem._delegateMuted = f.muted; ditem.syncMuted() }
              root.muteRev++
            }
            e.appName = f.appName
            e.iconName = f.iconName
            e.binary = f.binary
            e.mediaName = f.mediaName
            delete freshMap[f.index]
          }
        }
        for (let i = root.streams.length - 1; i >= 0; i--) {
          if (!seen.has(root.streams[i].index)) {
            root.streams.splice(i, 1)
            mutated = true
          }
        }
        const keys = Object.keys(freshMap)
        for (let i = 0; i < keys.length; i++) {
          const f = freshMap[keys[i]]
          if (f.index in pv) f.volume = pv[f.index]
          root.streams.push(f)
          mutated = true
        }
        if (mutated) root.streams = root.streams.slice()
        root._pendingVols = {}
      }
    }
  }

  // ── Actions ──
  function selectDevice(dev) {
    deviceDropdownOpen = false
    if (dev.type === "port") {
      Quickshell.execDetached(["sh", "-c",
        "pactl set-default-sink '" + dev.sinkName.replace(/'/g, "'\\''") + "' && " +
        "pactl set-sink-port '" + dev.sinkName.replace(/'/g, "'\\''") + "' " + dev.portName
      ])
      const idx = root.sinks.findIndex(n => n.name === dev.sinkName)
      if (idx >= 0) {
        root.sinks[idx] = Object.assign({}, root.sinks[idx], { activePort: dev.portName })
        buildDevices()
      }
      migrateStreams(dev.sinkName)
    } else {
      Quickshell.execDetached(["sh", "-c", "pactl set-default-sink '" + dev.sinkName.replace(/'/g, "'\\''") + "'"])
      migrateStreams(dev.sinkName)
    }
  }

  function migrateStreams(sinkName) {
    for (const s of root.streams) {
      Quickshell.execDetached(["sh", "-c",
        "pactl move-sink-input " + s.index + " '" + sinkName.replace(/'/g, "'\\''") + "'"
      ])
    }
  }

  function toggleStreamMute(idx, muted) {
    const val = muted ? "0" : "1"
    const stream = root.streams.find(s => s.index === idx)
    if (stream) {
      stream.muted = !muted
      root.muteRev++
    }
    Quickshell.execDetached(["sh", "-c", "pactl set-sink-input-mute " + idx + " " + val])
  }

  // ── UI ──
  Rectangle {
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors.fill: parent
      anchors.topMargin: 8
      anchors.leftMargin: 12
      anchors.rightMargin: 12
      anchors.bottomMargin: 8
      spacing: 6

      // Header
      RowLayout {
        Layout.fillWidth: true
        spacing: 4
        Text {
          text: "arrow_back"
          font.family: "Material Symbols Rounded"
          font.pixelSize: 20
          color: "#aaa"
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: closeRequested()
          }
        }
        Text {
          text: "Volume"
          font.pixelSize: 14
          font.weight: Font.Medium
          color: "#eee"
          Layout.leftMargin: 4
        }
        Item { Layout.fillWidth: true }
        Text {
          text: root.masterMuted ? "volume_off" : "volume_up"
          font.family: "Material Symbols Rounded"
          font.pixelSize: 18
          color: root.masterMuted ? "#ef5350" : "#eee"
        }
      }

      Item { Layout.preferredHeight: 4 }

      // ── Device dropdown ──
      Text {
        text: "Device (" + root.devices.length + ")"
        color: "#999"
        font.pixelSize: 11
        Layout.bottomMargin: -2
      }

      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: deviceDropdownOpen ? Math.min(dropdownList.contentHeight, 180) : 32
        clip: true

        Behavior on Layout.preferredHeight {
          NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Rectangle {
          id: dropdownButton
          width: parent.width
          height: 32
          radius: 6
          color: "#1a1a1a"
          z: 2

          readonly property var activeDevice: root.devices.find(d => root.isActive(d))

          RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            spacing: 6
            Text {
              text: dropdownButton.activeDevice?.label ?? "No device"
              elide: Text.ElideRight
              font.pixelSize: 12
              font.weight: Font.Medium
              color: "#eee"
              Layout.fillWidth: true
            }
            Text {
              text: "arrow_drop_down"
              font.family: "Material Symbols Rounded"
              font.pixelSize: 18
              color: "#888"
              rotation: root.deviceDropdownOpen ? 180 : 0
              Behavior on rotation { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.deviceDropdownOpen = !root.deviceDropdownOpen
          }
        }

        Rectangle {
          id: dropdownList
          width: parent.width
          y: 32
          radius: 6
          color: "#1a1a1a"
          visible: root.deviceDropdownOpen
          z: 1
          property real contentHeight: deviceListItems.height + 8
          height: deviceDropdownOpen ? Math.min(contentHeight, 180) : 0
          clip: true
          Behavior on height {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
          }

          Column {
            id: deviceListItems
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 4
            spacing: 2

            Repeater {
              model: root.devices.length > 1 ? root.devices.filter(d => !root.isActive(d)) : root.devices
              delegate: Item {
                width: deviceListItems.width
                height: 32
                required property var modelData
                readonly property bool active: root.isActive(modelData)

                Rectangle {
                  anchors.fill: parent
                  anchors.leftMargin: 4
                  anchors.rightMargin: 4
                  radius: 4
                  color: active ? Qt.rgba(1, 1, 1, 0.1) : (ma.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
                }
                RowLayout {
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.left: parent.left
                  anchors.leftMargin: 10
                  anchors.right: parent.right
                  anchors.rightMargin: 8
                  spacing: 6
                  Text {
                    text: active ? "radio_button_checked" : "radio_button_unchecked"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 14
                    color: active ? "#eee" : "#666"
                  }
                  Text {
                    text: modelData.label
                    elide: Text.ElideRight
                    font.pixelSize: 12
                    color: active ? "#eee" : "#aaa"
                    Layout.fillWidth: true
                  }
                }
                MouseArea {
                  id: ma
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.selectDevice(modelData)
                }
              }
            }
          }
        }
      }

      // ── Master volume (Pipewire — instant) ──
      Text {
        text: "Output"
        color: "#999"
        font.pixelSize: 11
        Layout.bottomMargin: -2
      }

      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        spacing: 8
        Text {
          text: root.masterMuted ? "volume_off" : root.volumeIcon(root.masterVolume, false)
          font.family: "Material Symbols Rounded"
          font.pixelSize: 20
          color: root.masterMuted ? "#ef5350" : "#eee"
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: { if (root.pwSink?.audio) root.pwSink.audio.muted = !root.pwSink.audio.muted }
          }
        }
        Item {
          Layout.fillWidth: true
          height: 20
          implicitHeight: 20

          Rectangle {
            id: masterTrack
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: "#2a2a2a"

            Rectangle {
              width: parent.width * root.masterVolume
              height: parent.height
              radius: parent.radius
              color: root.masterMuted ? "#555" : "#eee"
              Behavior on width {
                enabled: !masterSlider.dragging
                NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
              }
              Behavior on color { ColorAnimation { duration: 80 } }
            }
          }

          Rectangle {
            x: Math.max(0, masterTrack.x + masterTrack.width * root.masterVolume - width / 2)
            y: parent.height / 2 - height / 2
            width: 14
            height: 14
            radius: 7
            color: "#eee"
            Behavior on x {
              enabled: !masterSlider.dragging
              NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
            }
          }

          MouseArea {
            id: masterSlider
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            property bool dragging: false
            onPressed: {
              dragging = true
              if (root.pwSink?.audio) root.pwSink.audio.volume = Math.max(0, Math.min(1, mouseX / width))
            }
            onPositionChanged: {
              if (dragging && root.pwSink?.audio)
                root.pwSink.audio.volume = Math.max(0, Math.min(1, mouseX / width))
            }
            onReleased: { dragging = false }
            onCanceled: { dragging = false }
          }
        }
        Text {
          text: Math.round(root.masterVolume * 100) + "%"
          color: "#aaa"
          font.pixelSize: 12
          font.weight: Font.Medium
          Layout.preferredWidth: 36
          horizontalAlignment: Text.AlignRight
        }
      }

      // Separator
      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: "#2a2a2a"
        Layout.topMargin: 2
        Layout.bottomMargin: 2
      }

      // ── Application streams ──
      Text {
        text: "Applications (" + root.streams.length + ")"
        color: "#999"
        font.pixelSize: 11
        Layout.bottomMargin: -2
      }

      ListView {
        id: streamList
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 2
        interactive: false
        model: root.streams

        delegate: Item {
          id: streamDelegate
          width: ListView.view.width
          height: 42
          required property var modelData
          property bool _delegateMuted: false

          Rectangle { id: muteBg; anchors.fill: parent; radius: 6; color: "transparent" }

          function syncMuted() {
            muteBg.color = _delegateMuted ? Qt.rgba(239, 83, 80, 0.08) : "transparent"
            muteFallbackIcon.color = _delegateMuted ? "#555" : "#aaa"
            muteAppName.color = _delegateMuted ? "#666" : "#ddd"
            muteSliderFill.color = _delegateMuted ? "#555" : "#888"
            muteIcon.text = _delegateMuted ? "volume_off" : "volume_up"
            muteIcon.color = _delegateMuted ? "#ef5350" : "#666"
          }

          Component.onCompleted: {
            _delegateMuted = modelData.muted
            syncMuted()
          }

          Connections {
            target: root
            function onMuteRevChanged() { streamDelegate.syncMuted() }
          }

          RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.right: parent.right
            anchors.rightMargin: 6
            spacing: 6

              Rectangle {
                id: iconHolder
                width: 28
                height: 28
                radius: 6
                color: "#1a1a1a"

                readonly property var iconNames: {
                  var out = []
                  if (modelData.iconName.length > 0) out.push(modelData.iconName)
                  var app = (modelData.appName || "").toLowerCase()
                  var bin = (modelData.binary || "").toLowerCase()
                  var sbin = bin.replace(/-bin$/g, "").replace(/\.bin$/g, "")
                  if (app.length > 0) out.push(app)
                  if (bin.length > 0) out.push(bin)
                  if (sbin.length > 0 && sbin !== bin) out.push(sbin)
                  var seen = {}
                  var deduped = []
                  for (var i = 0; i < out.length; i++) {
                    if (!seen[out[i]]) { seen[out[i]] = true; deduped.push(out[i]) }
                  }
                  return deduped
                }

                function loadIcon() {
                  for (var i = 0; i < iconNames.length; i++) {
                    var p = Quickshell.iconPath(iconNames[i], 48)
                    if (p && p.length > 0) { appIcon.source = p; return }
                  }
                  if (DesktopEntries.applications) {
                    var entries = DesktopEntries.applications.values
                    var bin = (modelData.binary || "").toLowerCase()
                    var app = (modelData.appName || "").toLowerCase()
                    var sbin = bin.replace(/-bin$/g, "").replace(/\.bin$/g, "")
                    for (var i = 0; i < entries.length; i++) {
                      var eid = entries[i].id.toLowerCase().replace(/\.desktop$/, "")
                      var match = (bin.length > 0 && (eid.indexOf(bin) >= 0 || bin.indexOf(eid) >= 0))
                      if (!match && app.length > 0) match = eid.indexOf(app) >= 0
                      if (!match && sbin.length > 0 && sbin !== bin) match = eid.indexOf(sbin) >= 0
                      if (match) {
                        var p = Quickshell.iconPath(entries[i].icon, 48)
                        if (p && p.length > 0) { appIcon.source = p; return }
                      }
                    }
                  }
                }

                Image {
                  id: appIcon
                  anchors.fill: parent
                  sourceSize: Qt.size(28, 28)
                  fillMode: Image.PreserveAspectFit
                  mipmap: true
                  asynchronous: true
                }

                Text {
                  id: muteFallbackIcon
                  anchors.centerIn: parent
                  visible: appIcon.status !== Image.Ready
                  text: "music_note"
                  font.family: "Material Symbols Rounded"
                  font.pixelSize: 16
                  color: "#aaa"
                }

                Component.onCompleted: loadIcon()

                Connections {
                  target: DesktopEntries
                  function onApplicationsChanged() {
                    if (appIcon.status !== Image.Ready && appIcon.source.toString().length === 0)
                      iconHolder.loadIcon()
                  }
                }
              }

              ColumnLayout {
              Layout.fillWidth: true
              spacing: 2
              Text {
                id: muteAppName
                Layout.fillWidth: true
                text: {
                  if (modelData.appName || modelData.binary)
                    return modelData.mediaName
                      ? (modelData.appName || modelData.binary) + " — " + modelData.mediaName
                      : modelData.appName || modelData.binary
                  return modelData.mediaName || "Stream " + modelData.index
                }
                elide: Text.ElideRight
                font.pixelSize: 11
                font.weight: Font.Medium
                color: "#ddd"
              }
              RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Item {
                  id: streamSlider
                  Layout.fillWidth: true
                  height: 20
                  implicitHeight: 20

                  Rectangle {
                    id: streamTrack
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: "#2a2a2a"

                    Rectangle {
                      id: muteSliderFill
                      readonly property real vol: sliderArea.pressed ? streamSlider._dragVol : modelData.volume
                      width: parent.width * vol
                      height: parent.height
                      radius: parent.radius
                      color: "#888"
                      Behavior on width {
                        enabled: !sliderArea.pressed
                        NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
                      }
                      Behavior on color { ColorAnimation { duration: 80 } }
                    }

                    Rectangle {
                      readonly property real vol: sliderArea.pressed ? streamSlider._dragVol : modelData.volume
                      x: Math.max(0, parent.width * vol - width / 2)
                      y: parent.height / 2 - height / 2
                      width: 12
                      height: 12
                      radius: 6
                      color: "#ccc"
                    }
                  }

                  property real _dragVol: 0

                  MouseArea {
                    id: sliderArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    property real _lastPactl: 0
                    function streamIdx() { return streamDelegate.modelData.index }
                    onPressed: {
                      streamSlider._dragVol = Math.max(0, Math.min(1, mouseX / width))
                      modelData.volume = streamSlider._dragVol
                      _lastPactl = Date.now()
                      root.setStreamVolume(streamIdx(), streamSlider._dragVol)
                    }
                    onPositionChanged: {
                      streamSlider._dragVol = Math.max(0, Math.min(1, mouseX / width))
                      modelData.volume = streamSlider._dragVol
                      const now = Date.now()
                      if (now - _lastPactl > 100) {
                        _lastPactl = now
                        root.setStreamVolume(streamIdx(), streamSlider._dragVol)
                      }
                    }
                    onReleased: {
                      modelData.volume = streamSlider._dragVol
                      root.setStreamVolume(streamIdx(), streamSlider._dragVol)
                    }
                    onCanceled: {
                      modelData.volume = streamSlider._dragVol
                      root.setStreamVolume(streamIdx(), streamSlider._dragVol)
                    }
                  }
                }
                Text {
                  readonly property real vol: sliderArea.pressed ? streamSlider._dragVol : modelData.volume
                  text: Math.round(vol * 100) + "%"
                  color: "#777"
                  font.pixelSize: 10
                  font.weight: Font.Medium
                  Layout.preferredWidth: 30
                  horizontalAlignment: Text.AlignRight
                }
              }
            }

            Text {
              id: muteIcon
              text: modelData.muted ? "volume_off" : "volume_up"
              font.family: "Material Symbols Rounded"
              font.pixelSize: 14
              color: modelData.muted ? "#ef5350" : "#666"
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  var wasMuted = _delegateMuted
                  _delegateMuted = !wasMuted
                  root.toggleStreamMute(modelData.index, wasMuted)
                  streamDelegate.syncMuted()
                }
              }
            }
          }
        }
      }

      Text {
        Layout.fillWidth: true
        visible: root.streams.length === 0 && root.open
        text: "No applications found"
        color: "#666"
        font.pixelSize: 11
        horizontalAlignment: Text.AlignHCenter
        Layout.topMargin: 20
      }
    }
  }
}
