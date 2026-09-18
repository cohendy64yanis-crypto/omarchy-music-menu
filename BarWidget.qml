import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "io.github.cohendy64yanis-crypto.music-widget"

    property string trackInfo: "SoundCloud : Pause"
    property bool isPlaying: false

    Process {
        id: playerWatcher
        command: ["playerctl", "--follow", "metadata", "--format", "{{status}}|{{artist}}|{{title}}"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split("|");
                if (parts.length >= 3) {
                    var status = parts[0];
                    var artist = parts[1] ? parts[1] : "";
                    var title = parts[2] ? parts[2] : "Lecture en cours";
                    root.isPlaying = (status === "Playing");
                    root.trackInfo = artist ? (artist + " - " + title) : title;
                }
            }
        }
    }

    Process { id: actionProcess; running: false }

    content: RowLayout {
        spacing: 6
        MouseArea {
            anchors.fill: parent
            onClicked: root.controller.toggle()
        }

        Text {
            text: root.isPlaying ? "🟠" : "⏸️"
            font.pixelSize: 13
        }

        Text {
            text: root.trackInfo
            color: root.barForeground
            font.pixelSize: Style.font.body
            elide: Text.ElideRight
            Layout.maximumWidth: 200
        }
    }
}
