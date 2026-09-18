import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
    id: root
    moduleName: "io.github.cohendy64yanis-crypto.music-widget"
    manageIpc: true

    property string currentTitle: "Aucune piste"
    property string currentArtist: "SoundCloud"

    Process {
        id: panelWatcher
        command: ["playerctl", "metadata", "--format", "{{artist}}|{{title}}"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split("|");
                if (parts.length >= 2) {
                    root.currentArtist = parts[0] || "SoundCloud";
                    root.currentTitle = parts[1] || "Inconnu";
                }
            }
        }
    }

    Process { id: mediaAction; running: false }

    KeyboardPanel {
        id: panel
        owner: root
        bar: root.bar
        open: root.opened

        contentWidth: Style.space(280)
        contentHeight: contentLayout.implicitHeight + Style.space(20)

        ColumnLayout {
            id: contentLayout
            width: parent.width
            spacing: Style.space(12)

            Text {
                text: "☁️ SoundCloud Player"
                color: root.barForeground
                font.bold: true
                font.pixelSize: Style.font.subtitle
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: root.currentTitle
                    color: root.barForeground
                    font.bold: true
                    font.pixelSize: Style.font.body
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: root.currentArtist
                    color: root.barForeground
                    opacity: 0.6
                    font.pixelSize: Style.font.body - 2
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 15

                Button {
                    text: "⏮️"
                    onClicked: {
                        mediaAction.command = ["playerctl", "previous"];
                        mediaAction.running = true;
                    }
                }
                Button {
                    text: "⏯️"
                    onClicked: {
                        mediaAction.command = ["playerctl", "play-pause"];
                        mediaAction.running = true;
                    }
                }
                Button {
                    text: "⏭️"
                    onClicked: {
                        mediaAction.command = ["playerctl", "next"];
                        mediaAction.running = true;
                    }
                }
            }
        }
    }
}
