// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Menu iniziale: 20 riquadri da toccare, in una griglia che si adatta alla
// larghezza (fino a 6 per riga) e scorre in verticale.
Item {
    id: root
    property string category: "infanzia"   // "infanzia" o "primaria"
    signal gameSelected(string game)
    signal infoRequested()
    signal backRequested()
    signal quitRequested()

    Scenery { theme: root.category === "primaria" ? "scuola" : "prato" }

    TitlePill {
        id: heading
        anchors { top: parent.top; topMargin: 14; horizontalCenter: parent.horizontalCenter }
        maxWidth: root.width - 400
        title: root.category === "primaria" ? qsTr("Giochi per la primaria") : qsTr("Giochi per l'infanzia")
        titleSize: 38
    }

    CircleButton {   // indietro (torna alla scelta Infanzia/Primaria), in alto a sinistra
        anchors { top: parent.top; left: parent.left; margins: 18 }
        icon: "ui/back"
        color: Theme.dirLeft
        onClicked: root.backRequested()
    }

    CircleButton {   // Info, in alto a destra
        id: infoBtn
        anchors { top: parent.top; right: parent.right; margins: 18 }
        label: "i"
        color: Theme.dirUp
        onClicked: root.infoRequested()
    }

    CandyButton {   // Esci, a sinistra di Info
        anchors { verticalCenter: infoBtn.verticalCenter; right: infoBtn.left; rightMargin: 14 }
        height: 62
        text: qsTr("Esci")
        icon: "door"
        textSize: 26
        color: Theme.danger
        onClicked: root.quitRequested()   // prima chiede conferma
    }

    Flickable {
        id: flick
        anchors {
            top: heading.bottom; topMargin: 18
            left: parent.left; right: parent.right
            bottom: footer.top
        }
        contentWidth: width
        contentHeight: grid.height + 30
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Grid {
            id: grid
            anchors.horizontalCenter: parent.horizontalCenter
            y: 8
            columns: Math.max(3, Math.min(6, Math.floor((flick.width - 40) / 214)))
            rowSpacing: 18
            columnSpacing: 18

            Repeater {
                model: Catalog.games.filter((g) => g.cat === root.category)
                GameTile {
                    required property var modelData
                    required property int index
                    order: index
                    title: modelData.title
                    age: modelData.age
                    baseColor: modelData.c
                    iconKind: modelData.icon ? modelData.icon : ""
                    image: modelData.img
                    onClicked: root.gameSelected(modelData.id)
                }
            }
        }
    }

    Rectangle {   // fondo chiaro dietro la riga in basso
        anchors.centerIn: footer
        width: Math.min(footer.width, footer.implicitWidth + 36)
        height: footer.height + 8
        radius: height / 2
        color: "#E6FFFFFF"
    }

    Text {
        id: footer
        width: parent.width - 40
        anchors { bottom: parent.bottom; bottomMargin: 10; horizontalCenter: parent.horizontalCenter }
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        textFormat: Text.RichText
        text: "© 2026 Angelo Scarnà - software libero (GPLv3). Per info contattare: " +
              "<a href=\"mailto:angelo.scarna@primanotanet.it\">angelo.scarna@primanotanet.it</a>"
        linkColor: Theme.accentDark
        font.pixelSize: 15
        color: Theme.text
        opacity: 1
        onLinkActivated: (link) => Qt.openUrlExternally(link)

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            property bool onLink: false
            cursorShape: onLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPositionChanged: (m) => onLink = footer.linkAt(m.x, m.y) !== ""
            onExited: onLink = false
            onClicked: (m) => {
                var l = footer.linkAt(m.x, m.y)
                if (l !== "") Qt.openUrlExternally(l)
            }
        }
    }
}
