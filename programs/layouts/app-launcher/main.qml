import QtQml
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Qt5Compat.GraphicalEffects

Scope {
  id: root

  property var av_apps: []
  property bool dataReady: false
  property bool terminate: false
  property int total: 0

  Process {
    id: getApps

    command: ["./scripts/getApps.sh", 10, 0]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        var jsonData = JSON.parse(text);
        root.av_apps = jsonData['apps'];
        root.total = jsonData['total'];
      }
    }

    // qmllint disable signal-handler-parameters
    onExited: exitCode => {
      if (exitCode === 0) {
        root.dataReady = true;
      }
    }
    onStarted: () => {
      root.dataReady = false;
    }
  }

  // qmllint disable uncreatable-type
  PanelWindow {
    anchors.right: true
    color: 'transparent'
    implicitHeight: 400
    implicitWidth: 600
    visible: true

    mask: Region {
      intersection: Intersection.Subtract
      item: maskCanvas
    }

    Canvas {
        id: maskCanvas
        width: 250
        height: 250
        
        onPaint: {
            var ctx = getContext("2d")
            // Красим всё белым (непрозрачным)
            ctx.fillStyle = "white"
            ctx.fillRect(0, 0, width, height)
            
            // "Стираем" треугольник из маски (делаем его прозрачным)
            ctx.globalCompositeOperation = "destination-out"
            ctx.fillStyle = "black"
            ctx.beginPath()
            ctx.moveTo(150, 50)
            ctx.lineTo(-250, 250)
            ctx.lineTo(50, 250)
            ctx.closePath()
            ctx.fill()
        }
    }

    OpacityMask {
        anchors.fill: lv
        source: lv
        maskSource: maskCanvas
        invert: true // Инвертируем: то, что было прозрачным в маске, станет "дыркой"
    }

    ListView {
      id: lv

      anchors.fill: parent
      model: root.av_apps
      spacing: 5

      delegate: Rectangle {
        id: itm

        required property var modelData

        border.color: 'black'
        border.width: 2
        implicitHeight: row.implicitHeight
        implicitWidth: row.implicitWidth

        DesktopAction {
          id: ra
          property string path

          command: ["./scripts/runApp.sh", path]
        }

        Process {
          id: runApp

          property string path

          command: ["./scripts/runApp.sh", path]
          running: false

          onExited: exitCode => {
            if (exitCode === 0) {}
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          hoverEnabled: true

          onClicked: () => {
            ra.path = itm.modelData['path'];
            ra.execute()
          }
        }

        RowLayout {
          id: row

          Image {
            Layout.preferredHeight: 42
            Layout.preferredWidth: 42
            source: itm.modelData['icon']
          }

          Text {
            text: itm.modelData['name']
          }
        }
      }
    }
  }
}
