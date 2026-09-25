import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    // Définit une taille correcte pour le panneau
    Layout.minimumWidth: PlasmaCore.Units.gridUnit * 2
    Layout.minimumHeight: PlasmaCore.Units.gridUnit * 2

    // Vue compacte pour la barre des tâches
    compactRepresentation: PlasmaComponents.ToolButton {
        // Utilise une icône multimédia standard du thème si l'icône Spotify n'existe pas
        icon.name: "media-playback-start"
        text: "Spotify"
        display: PlasmaComponents.AbstractButton.IconOnly

        onClicked: {
            executable.exec("/home/yanis/.local/bin/launch_spotify_favorites.sh")
        }
    }

    // Moteur d'exécution de commande
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => disconnectSource(sourceName)

        function exec(cmd) {
            connectSource(cmd)
        }
    }
}
