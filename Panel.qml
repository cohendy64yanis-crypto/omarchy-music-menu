import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
    id: root
    moduleName: "io.github.cohendy64yanis-crypto.french-go-menu"
    manageIpc: true

    property var anchorItem: null
    property var hostWidget: null
    
    // Variables pour gérer l'état des menus
    property string activeMenu: "main" // Peut être "main", "apps", ou "system"
    property int savedMainIndex: 0

    function open() { 
        activeMenu = "main"; // Toujours ouvrir sur le menu principal
        root.controller.show(); 
        menuListView.forceActiveFocus();
    }
    function close() { 
        root.controller.hide(); 
    }

    Process { id: actionProcess; running: false }

    // --- MODELES DE DONNÉES ---

    ListModel {
        id: mainMenuModel
        ListElement { icon: "⣿"; label: "Applications"; hasSubmenu: true; submenuId: "apps"; cmd: "" }
        ListElement { icon: "🎓"; label: "Apprendre"; hasSubmenu: false; submenuId: ""; cmd: "omarchy-launch learn" }
        ListElement { icon: "🚀"; label: "Déclencheurs"; hasSubmenu: false; submenuId: ""; cmd: "omarchy-launch trigger" }
        ListElement { icon: "🎨"; label: "Style & Thèmes"; hasSubmenu: false; submenuId: ""; cmd: "omarchy-launch style" }
        ListElement { icon: "⚙️"; label: "Configuration"; hasSubmenu: false; submenuId: ""; cmd: "omarchy-launch setup" }
        ListElement { icon: "📦"; label: "Installer"; hasSubmenu: false; submenuId: ""; cmd: "omarchy-launch install" }
        ListElement { icon: "🗑️"; label: "Supprimer"; hasSubmenu: false; submenuId: ""; cmd: "omarchy-launch remove" }
        ListElement { icon: "🔄"; label: "Mise à jour"; hasSubmenu: false; submenuId: ""; cmd: "omarchy-launch update" }
        ListElement { icon: "ℹ️"; label: "À propos"; hasSubmenu: false; submenuId: ""; cmd: "omarchy-launch about" }
        ListElement { icon: "⚡"; label: "Système"; hasSubmenu: true; submenuId: "system"; cmd: "" }
    }

    ListModel { id: appsModel }

    ListModel {
        id: systemModel
        ListElement { icon: "🔒"; label: "Verrouiller"; hasSubmenu: false; submenuId: ""; cmd: "loginctl lock-session" }
        ListElement { icon: "🚪"; label: "Déconnexion"; hasSubmenu: false; submenuId: ""; cmd: "hyprctl dispatch exit" }
        ListElement { icon: "🔄"; label: "Redémarrer"; hasSubmenu: false; submenuId: ""; cmd: "systemctl reboot" }
        ListElement { icon: "⏻"; label: "Éteindre"; hasSubmenu: false; submenuId: ""; cmd: "systemctl poweroff" }
    }

    // --- CHARGEMENT DYNAMIQUE DES APPS (Repris de ton ancien script) ---
    Process {
        id: loadAllApps
        command: ["python3", "-c", "
import glob, configparser, os, json
apps = []
seen = set()
paths = ['/usr/share/applications/*.desktop', os.path.expanduser('~/.local/share/applications/*.desktop')]
for p in paths:
    for f in glob.glob(p):
        config = configparser.ConfigParser(interpolation=None)
        try:
            config.read(f, encoding='utf-8')
            if 'Desktop Entry' in config:
                de = config['Desktop Entry']
                if de.get('Type') == 'Application' and not de.get('NoDisplay') == 'true':
                    name = de.get('Name', '')
                    exec_cmd = de.get('Exec', '')
                    if name and exec_cmd and name not in seen:
                        seen.add(name)
                        apps.append({'label': name, 'cmd': exec_cmd, 'icon': '🔹', 'hasSubmenu': False, 'submenuId': ''})
        except: pass
apps.sort(key=lambda x: x['label'].lower())
print(json.dumps(apps))
"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    var list = JSON.parse(data.trim());
                    appsModel.clear();
                    for (var i = 0; i < list.length; i++) {
                        appsModel.append(list[i]);
                    }
                } catch(e) {}
            }
        }
    }

    // --- INTERFACE PRINCIPALE ---
    KeyboardPanel {
        id: panel
        anchorItem: root.anchorItem
        owner: root.hostWidget || root
        bar: root.bar
        open: root.opened
        focusTarget: keyCatcher

        contentWidth: panel.fittedContentWidth(Style.space(280))
        contentHeight: panel.fittedContentHeight(content.implicitHeight)

        PanelKeyCatcher {
            id: keyCatcher
            anchors.fill: parent
            focus: true
            onCloseRequested: root.close()

            // GESTION DU CLAVIER
            Keys.onPressed: function(event) {
                var count = menuListView.count;
                if (count === 0) return;

                if (event.key === Qt.Key_Down) {
                    // Boucle de bas en haut
                    menuListView.currentIndex = (menuListView.currentIndex + 1) % count;
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    // Boucle de haut en bas
                    menuListView.currentIndex = (menuListView.currentIndex - 1 + count) % count;
                    event.accepted = true;
                } else if (event.key === Qt.Key_Right) {
                    // Entrer dans un sous-menu
                    var rightItem = menuListView.model.get(menuListView.currentIndex);
                    if (activeMenu === "main" && rightItem && rightItem.hasSubmenu) {
                        savedMainIndex = menuListView.currentIndex;
                        activeMenu = rightItem.submenuId;
                        menuListView.currentIndex = 0;
                    } else if (activeMenu === "main" && rightItem && !rightItem.hasSubmenu) {
                        // Si c'est un menu sans sous-menu (ex: Style), on l'ouvre direct
                        actionProcess.command = ["sh", "-c", rightItem.cmd];
                        actionProcess.running = true;
                        root.close();
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Left) {
                    // Revenir en arrière
                    if (activeMenu !== "main") {
                        activeMenu = "main";
                        menuListView.currentIndex = savedMainIndex;
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    // Valider l'action
                    var enterItem = menuListView.model.get(menuListView.currentIndex);
                    if (enterItem) {
                        if (activeMenu === "main" && enterItem.hasSubmenu) {
                            savedMainIndex = menuListView.currentIndex;
                            activeMenu = enterItem.submenuId;
                            menuListView.currentIndex = 0;
                        } else {
                            var finalCmd = enterItem.cmd;
                            if (activeMenu === "apps") {
                                // Nettoyage de la commande exec pour les apps
                                finalCmd = "nohup " + finalCmd.replace(/%[a-zA-Z]/g, "").trim() + " >/dev/null 2>&1 &";
                            }
                            actionProcess.command = ["sh", "-c", finalCmd];
                            actionProcess.running = true;
                            root.close();
                        }
                    }
                    event.accepted = true;
                }
            }

            ColumnLayout {
                id: content
                width: parent.width
                spacing: Style.space(8)

                RowLayout {
                    Layout.fillWidth: true
                    
                    Text {
                        text: {
                            if (activeMenu === "main") return "Aller à...";
                            if (activeMenu === "apps") return "◀ Applications";
                            if (activeMenu === "system") return "◀ Système";
                            return "";
                        }
                        color: root.barForeground
                        opacity: 0.6
                        font.pixelSize: Style.font.caption
                        Layout.fillWidth: true
                    }
                }

                ListView {
                    id: menuListView
                    Layout.fillWidth: true
                    Layout.preferredHeight: 340
                    clip: true
                    focus: true
                    
                    // On change le modèle en fonction du menu actif
                    model: {
                        if (activeMenu === "main") return mainMenuModel;
                        if (activeMenu === "apps") return appsModel;
                        if (activeMenu === "system") return systemModel;
                        return mainMenuModel;
                    }

                    highlight: Rectangle {
                        color: root.barForeground
                        opacity: 0.15
                        radius: 4
                    }
                    highlightFollowsCurrentItem: true

                    delegate: Rectangle {
                        width: menuListView.width
                        height: 34
                        color: "transparent"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                menuListView.currentIndex = index;
                                if (model.hasSubmenu) {
                                    savedMainIndex = index;
                                    activeMenu = model.submenuId;
                                    menuListView.currentIndex = 0;
                                } else {
                                    var runCmd = model.cmd;
                                    if (activeMenu === "apps") {
                                        runCmd = "nohup " + runCmd.replace(/%[a-zA-Z]/g, "").trim() + " >/dev/null 2>&1 &";
                                    }
                                    actionProcess.command = ["sh", "-c", runCmd];
                                    actionProcess.running = true;
                                    root.close();
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 10

                                Text {
                                    text: model.icon
                                    font.pixelSize: Style.font.body
                                }
                                Text {
                                    text: model.label
                                    color: root.barForeground
                                    font.pixelSize: Style.font.body
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    // Affiche une flèche si c'est un sous-menu
                                    text: model.hasSubmenu ? "›" : ""
                                    color: root.barForeground
                                    opacity: 0.4
                                    font.pixelSize: Style.font.body
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
