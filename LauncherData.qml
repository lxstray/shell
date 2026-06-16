import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.LocalStorage 2.0

Item {
  id: root

  property var allApps: []
  property var filteredApps: []
  property string pendingQuery: ""

  signal appLaunched(var app)
  signal specialLaunch(string id)

  Timer {
    id: filterTimer
    interval: 30
    repeat: false
    onTriggered: root.doFilter(pendingQuery)
  }

  property var db: null
  property var counts: ({})

  function initDb() {
    if (db) return
    db = LocalStorage.openDatabaseSync("SimpleShellLauncher", "1.0", "App launch counts", 100000)
    db.transaction(function(tx) {
      tx.executeSql("CREATE TABLE IF NOT EXISTS launch_counts(id TEXT PRIMARY KEY, count INT NOT NULL DEFAULT 0)")
    })
    loadCounts()
  }

  function loadCounts() {
    db.transaction(function(tx) {
      var rs = tx.executeSql("SELECT id, count FROM launch_counts")
      for (var i = 0; i < rs.rows.length; i++) {
        counts[rs.rows.item(i).id] = rs.rows.item(i).count
      }
    })
  }

  function getCount(id) {
    return counts[id] || 0
  }

  function incrementCount(id) {
    counts[id] = (counts[id] || 0) + 1
    db.transaction(function(tx) {
      tx.executeSql("INSERT OR REPLACE INTO launch_counts(id, count) VALUES(?, ?)", [id, counts[id]])
    })
  }

  function loadApps() {
    var entries = DesktopEntries.applications ? DesktopEntries.applications.values : []
    if (!entries || !entries.length) return false
    var apps = []
    for (var i = 0; i < entries.length; i++) {
      if (!entries[i].noDisplay) apps.push(entries[i])
    }
    if (apps.length) {
      apps.unshift({
        name: "Settings",
        id: "_settings",
        icon: "file:///usr/share/icons/AdwaitaLegacy/48x48/legacy/emblem-system.png",
        genericName: "",
        noDisplay: false,
        execute: function() {}
      })
      allApps = apps
      doFilter("")
      return true
    }
    return false
  }

  function filterApps(query) {
    pendingQuery = query
    filterTimer.restart()
  }

  function doFilter(query) {
    if (!allApps.length) return
    var q = query.toLowerCase()
    var filtered = []
    for (var i = 0; i < allApps.length; i++) {
      var app = allApps[i]
      if (!q || app.name.toLowerCase().indexOf(q) !== -1 ||
          (app.genericName && app.genericName.toLowerCase().indexOf(q) !== -1)) {
        filtered.push(app)
      }
    }
    filtered.sort(function(a, b) {
      var ca = getCount(a.id)
      var cb = getCount(b.id)
      if (ca !== cb) return cb - ca
      if (a.name < b.name) return -1
      if (a.name > b.name) return 1
      return 0
    })
    filteredApps = filtered
  }

  function launchApp(app) {
    incrementCount(app.id)
    if (app.id === "_settings") {
      root.specialLaunch("settings")
      root.appLaunched(app)
      return
    }
    app.execute()
    root.appLaunched(app)
  }

  Component.onCompleted: {
    initDb()
    loadApps()
    DesktopEntries.applicationsChanged.connect(function() {
      if (!allApps.length) loadApps()
    })
  }
}
