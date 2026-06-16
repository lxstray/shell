import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
  id: root

  property bool open: false

  signal appLaunched()
  signal canceled()

  LauncherData {
    id: launcherData
    onAppLaunched: root.appLaunched()
  }

  Rectangle {
    id: searchArea
    anchors.left: parent.left; anchors.leftMargin: 8
    anchors.right: parent.right; anchors.rightMargin: 8

    y: root.open ? -24 : -86
    height: 28
    opacity: root.open ? 1 : 0

    Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 200 } }

    color: "#1a1a1a"
    radius: 6
    border { color: "#333"; width: 1 }

    Text {
      anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
      text: "Search apps\u2026"
      color: "#555"
      font { pixelSize: 17; weight: Font.Medium }
      visible: searchInput.text.length === 0
    }

    TextInput {
      id: searchInput
      anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
      verticalAlignment: TextInput.AlignVCenter
      color: "#eee"
      font { pixelSize: 17; weight: Font.Medium }

      onTextChanged: launcherData.filterApps(text)
      Keys.onEscapePressed: root.canceled()
      Keys.onReturnPressed: selectLaunch()
      Keys.onDownPressed: selectNext()
      Keys.onUpPressed: selectPrev()
    }
  }

  Item {
    id: listArea
    anchors { left: parent.left; right: parent.right; top: parent.top }
    anchors.topMargin: 6
    height: root.open ? parent.height - anchors.topMargin : 0

    opacity: root.open ? 1 : 0

    Behavior on opacity { NumberAnimation { duration: 200 } }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 8
      spacing: 4

      Text {
        Layout.fillWidth: true
        height: 24
        visible: launcherData.filteredApps.length === 0 && searchInput.text.length > 0
        text: "No applications found"
        color: "#555"
        font { pixelSize: 13; italic: true }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }

      ListView {
        id: listView
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 1
        cacheBuffer: 200

        model: launcherData.filteredApps
        currentIndex: 0
        highlightFollowsCurrentItem: false

        highlight: Rectangle {
          radius: 6
          color: "#2a2a2a"
          y: listView.currentItem?.y ?? 0
          width: listView.width
          height: 36

          Behavior on y {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
          }
        }

        addDisplaced: Transition {
          NumberAnimation { properties: "y"; duration: 80; easing.type: Easing.OutCubic }
        }

        removeDisplaced: Transition {
          NumberAnimation { properties: "y"; duration: 80; easing.type: Easing.OutCubic }
        }

        delegate: Item {
          required property var modelData
          required property int index
          width: ListView.view.width
          height: 36

          RowLayout {
            anchors { left: parent.left; leftMargin: 8; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: 8

            IconImage {
              implicitSize: 24
              mipmap: true
              asynchronous: true
              source: Quickshell.iconPath(modelData.icon)
              Component.onCompleted: {
                backer.sourceSize.width = 48
                backer.sourceSize.height = 48
              }
            }

            Text {
              text: modelData.name
              color: "#eee"
              font.pixelSize: 17
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: listView.currentIndex = index
            onClicked: launchApp(modelData)
          }
        }
      }
    }
  }

  function focusSearch() {
    if (!launcherData.allApps.length) launcherData.loadApps()
    searchInput.forceActiveFocus()
    searchInput.text = ""
    launcherData.doFilter("")
  }

  function selectNext() {
    if (listView.currentIndex < listView.count - 1) {
      var next = listView.currentIndex + 1
      listView.positionViewAtIndex(next, ListView.Contain)
      listView.currentIndex = next
    }
  }

  function selectPrev() {
    if (listView.currentIndex > 0) {
      var prev = listView.currentIndex - 1
      listView.positionViewAtIndex(prev, ListView.Contain)
      listView.currentIndex = prev
    }
  }

  function selectLaunch() {
    if (listView.currentIndex >= 0 && listView.currentIndex < launcherData.filteredApps.length)
      launchApp(launcherData.filteredApps[listView.currentIndex])
  }

  function launchApp(app) {
    launcherData.launchApp(app)
    root.appLaunched()
  }
}
