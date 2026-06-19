import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs

Window {
  id: root

  property var settings: null

  title: "Settings"
  width: 600
  height: 400
  color: "transparent"
  flags: Qt.Window

  property var scr: Quickshell.screens[0] || null
  x: scr ? Math.round(scr.x + (scr.width - width) / 2) : 0
  y: scr ? Math.round(scr.y + (scr.height - height) / 2) : 0

  property string selectedSection: "Bar"

  Rectangle {
    anchors.fill: parent
    radius: 10
    color: "#1a1a1a"
    border { color: "#333"; width: 1 }
    clip: true

    RowLayout {
      anchors.fill: parent
      spacing: 0

      Rectangle {
        Layout.preferredWidth: 180
        Layout.fillHeight: true
        color: "#222"
        radius: 10

        Rectangle {
          anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 1 }
          height: 1
          color: "#333"
          visible: false
        }

        ColumnLayout {
          anchors { top: parent.top; topMargin: 16; left: parent.left; right: parent.right }
          spacing: 2

          Text {
            Layout.leftMargin: 16
            Layout.bottomMargin: 12
            text: "Settings"
            color: "#eee"
            font { pixelSize: 16; weight: Font.Bold }
          }

          Repeater {
            model: ["Bar", "Wallpaper"]

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 32
              color: root.selectedSection === modelData ? "#333" : "transparent"
              radius: 6

              Rectangle {
                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                width: 4; height: 18; radius: 2
                color: root.selectedSection === modelData ? "#eee" : "transparent"
              }

              Text {
                anchors { left: parent.left; leftMargin: 26; verticalCenter: parent.verticalCenter }
                text: modelData
                color: root.selectedSection === modelData ? "#eee" : "#999"
                font { pixelSize: 14 }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: parent.color = "#2a2a2a"
                onExited: parent.color = root.selectedSection === modelData ? "#333" : "transparent"
                onClicked: root.selectedSection = modelData
              }
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: "#1a1a1a"

        Item {
          anchors.fill: parent
          anchors.margins: 24
          visible: root.selectedSection === "Bar"

          ColumnLayout {
            anchors.fill: parent
            spacing: 20

            Text {
              text: "Bar"
            color: "#eee"
            font { pixelSize: 18; weight: Font.Bold }
          }

          ColumnLayout {
            spacing: 8
            Layout.fillWidth: true

            Text {
              text: "Position"
              color: "#999"
              font { pixelSize: 13 }
            }

            RowLayout {
              spacing: 8
              Layout.fillWidth: true

              Repeater {
                model: ["Top", "Left", "Bottom", "Right"]

                Rectangle {
                  Layout.preferredHeight: 32
                  Layout.fillWidth: true
                  radius: 8
                  color: root.settings && root.settings.barPosition === modelData.toLowerCase() ? "#eee" : "#2a2a2a"
                  border { color: root.settings && root.settings.barPosition === modelData.toLowerCase() ? "#eee" : "#444"; width: 1 }

                  Text {
                    anchors.centerIn: parent
                    text: modelData
                    color: root.settings && root.settings.barPosition === modelData.toLowerCase() ? "#111" : "#ccc"
                    font { pixelSize: 13; weight: Font.Medium }
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (root.settings) {
                        root.settings.barPosition = modelData.toLowerCase()
                        root.settings.save()
                      }
                    }
                  }
                }
              }
            }
          }

          ColumnLayout {
            spacing: 8
            Layout.fillWidth: true

            Text {
              text: "Style"
              color: "#999"
              font { pixelSize: 13 }
            }

            RowLayout {
              spacing: 8
              Layout.fillWidth: true

              Repeater {
                model: ["Island", "Integral"]

                Rectangle {
                  Layout.preferredHeight: 32
                  Layout.fillWidth: true
                  radius: 8
                  color: root.settings && root.settings.barStyle === modelData.toLowerCase() ? "#eee" : "#2a2a2a"
                  border { color: root.settings && root.settings.barStyle === modelData.toLowerCase() ? "#eee" : "#444"; width: 1 }

                  Text {
                    anchors.centerIn: parent
                    text: modelData
                    color: root.settings && root.settings.barStyle === modelData.toLowerCase() ? "#111" : "#ccc"
                    font { pixelSize: 13; weight: Font.Medium }
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (root.settings) {
                        root.settings.barStyle = modelData.toLowerCase()
                        root.settings.save()
                      }
                    }
                  }
                }
              }
            }
          }
          }
        }

        // Wallpaper page
        Item {
          anchors.fill: parent
          anchors.margins: 24
          visible: root.selectedSection === "Wallpaper"

          ColumnLayout {
            anchors.fill: parent
            spacing: 16

            Text {
              text: "Wallpaper"
              color: "#eee"
              font { pixelSize: 18; weight: Font.Bold }
            }

            FileDialog {
              id: wallpaperPicker
              title: "Choose Wallpaper"
              nameFilters: ["Images (*.jpg *.png *.jpeg *.webp)"]
              onAccepted: {
                if (root.settings) {
                  var urlStr = String(wallpaperPicker.selectedFile)
                  var path = urlStr.substring(7)
                  if (path.length > 0) {
                    root.settings.setWallpaper(path)
                  }
                }
              }
            }

            Rectangle {
              implicitHeight: 32
              implicitWidth: browseLabel.width + 24
              radius: 8
              color: "#2a2a2a"
              border { color: "#555"; width: 1 }

              Text {
                id: browseLabel
                anchors.centerIn: parent
                text: "Browse..."
                color: "#eee"
                font { pixelSize: 13 }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: wallpaperPicker.open()
              }
            }

            // Recent wallpapers
            ColumnLayout {
              spacing: 8

              Text {
                text: "Recent"
                color: "#999"
                font { pixelSize: 13 }
                visible: root.settings && root.settings.wallpaperHistory.length > 0
              }

              Flow {
                Layout.fillWidth: true
                spacing: 8
                visible: root.settings && root.settings.wallpaperHistory.length > 0

                Repeater {
                  model: root.settings ? root.settings.wallpaperHistory : []

                  Rectangle {
                    width: 80; height: 54; radius: 6
                    color: "#2a2a2a"
                    border { color: root.settings && root.settings.currentWallpaper === modelData ? "#4fc3f7" : "#444"; width: 2 }

                    Image {
                      anchors.fill: parent
                      source: "file://" + modelData
                      sourceSize { width: 160; height: 108 }
                      fillMode: Image.PreserveAspectCrop
                      asynchronous: true
                    }

                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: { if (root.settings) root.settings.setWallpaper(modelData) }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
