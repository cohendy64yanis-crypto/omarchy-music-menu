import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "io.github.cohendy64yanis-crypto.music-widget"

    property string trackInfo: "SoundCloud : En pause"
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

    MouseArea {
        anchors.fill: parent
        onClicked: {
            actionProcess.command = ["playerctl", "play-pause"];
            actionProcess.running = true;
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            // Icône circulaire propre avec play/pause
            Rectangle {
                width: 18
                height: 18
                radius: 9
                color: "transparent"
                border.color: "white"
                border.width: 1.5
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: root.isPlaying ? "❚❚" : "▶"
                    color: "white"
                    font.pixelSize: 8
                    leftPadding: root.isPlaying ? 0 : 1
                }
            }

            Text {
                text: root.trackInfo
                color: "white"
                font.pixelSize: 12
                elide: Text.ElideRight
                Layout.maximumWidth: 180
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
