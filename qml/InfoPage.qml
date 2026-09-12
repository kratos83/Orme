// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Giochi

// Pagina "Info": presentazione del programma + elenco di tutti i giochi
// (toccando una riga si apre quel gioco).
Item {
    id: root
    signal exitRequested()
    signal gameSelected(string id)

    Rectangle { anchors.fill: parent; color: Theme.background }

    Item {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 92

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 20
            width: 64; height: 64; radius: 32
            color: Theme.panel
            border.color: Theme.boardLine
            border.width: 3
            scale: backMa.pressed ? 0.9 : 1
            Behavior on scale { NumberAnimation { duration: 80 } }
            Text { anchors.centerIn: parent; text: "←"; font.pixelSize: 30; color: Theme.text }
            MouseArea { id: backMa; anchors.fill: parent; onClicked: root.exitRequested() }
        }

        Text {
            anchors.centerIn: parent
            text: qsTr("Info")
            font.pixelSize: 28
            font.bold: true
            color: Theme.text
        }
    }

    Flickable {
        anchors {
            top: header.bottom
            left: parent.left; right: parent.right
            bottom: parent.bottom
            margins: 22
        }
        contentWidth: width
        contentHeight: col.height + 30
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: parent.width
            spacing: 16

            // ----- blocco: cos'è il programma -----
            Rectangle {
                width: col.width
                radius: 20
                color: Theme.panel
                border.color: Theme.boardLine
                border.width: 3
                height: about.height + 36

                Column {
                    id: about
                    x: 22; y: 18
                    width: parent.width - 44
                    spacing: 8

                    Text { text: "Orme"; font.pixelSize: 34; font.bold: true; color: Theme.text }

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        font.pixelSize: 17
                        color: Theme.text
                        opacity: 0.85
                        text: qsTr("20 giochi touch per bambini di 3, 4 e 5 anni, ispirati ai concetti del coding: sequenze, cicli, pattern, classificazione, ordine. Niente testo da leggere: icone, colori e suoni. Bersagli grandi, nessuna schermata di sconfitta.")
                    }
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        font.pixelSize: 17
                        color: Theme.text
                        opacity: 0.85
                        text: qsTr("All'inizio di ogni gioco si può scrivere il nome del bambino oppure premere \"Salta\"; il nome si può cambiare durante il gioco con il tasto 👤. Ogni livello vinto dà da 1 a 3 faccine 😊 e si passa da soli al livello dopo.")
                    }
                    Text {
                        text: qsTr("Versione 0.2")
                        font.pixelSize: 14
                        color: Theme.text
                        opacity: 0.6
                    }
                    Text {
                        id: credit
                        width: parent.width
                        wrapMode: Text.WordWrap
                        textFormat: Text.RichText
                        text: "© 2026 Angelo Scarnà - software libero (GPLv3). " +
                              "<a href=\"mailto:angelo.scarna@primanotanet.it\">angelo.scarna@primanotanet.it</a>"
                        linkColor: Theme.accentDark
                        font.pixelSize: 15
                        color: Theme.text
                        opacity: 0.75
                        onLinkActivated: (l) => Qt.openUrlExternally(l)
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            property bool onLink: false
                            cursorShape: onLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onPositionChanged: (m) => onLink = credit.linkAt(m.x, m.y) !== ""
                            onExited: onLink = false
                            onClicked: (m) => {
                                var l = credit.linkAt(m.x, m.y)
                                if (l !== "") Qt.openUrlExternally(l)
                            }
                        }
                    }
                }
            }

            Text {
                text: qsTr("Tutti i giochi")
                font.pixelSize: 24
                font.bold: true
                color: Theme.text
            }

            // ----- elenco giochi -----
            Repeater {
                model: Catalog.games

                Rectangle {
                    id: card
                    required property var modelData
                    width: col.width
                    height: Math.max(100, body.implicitHeight + 26)
                    radius: 18
                    color: Theme.panel
                    border.color: Theme.boardLine
                    border.width: 2
                    scale: cardMa.pressed ? 0.99 : 1
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    Rectangle {
                        id: badge
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        width: 74; height: 74; radius: 18
                        color: card.modelData.c
                        Text {
                            anchors.centerIn: parent
                            text: card.modelData.e ? card.modelData.e : "➜"
                            font.pixelSize: 40
                            color: "white"
                        }
                    }

                    Rectangle {
                        id: ageChip
                        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                        width: chipT.implicitWidth + 16
                        height: 26
                        radius: 13
                        color: card.modelData.c
                        opacity: 0.9
                        Text {
                            id: chipT
                            anchors.centerIn: parent
                            text: card.modelData.age
                            font.pixelSize: 13
                            font.bold: true
                            color: "white"
                        }
                    }

                    Column {
                        id: body
                        anchors {
                            left: badge.right; leftMargin: 16
                            right: ageChip.left; rightMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 4
                        Text {
                            text: card.modelData.title
                            font.pixelSize: 20
                            font.bold: true
                            color: Theme.text
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: card.modelData.desc
                            font.pixelSize: 14
                            color: Theme.text
                            opacity: 0.75
                        }
                    }

                    MouseArea {
                        id: cardMa
                        anchors.fill: parent
                        onClicked: root.gameSelected(card.modelData.id)
                    }
                }
            }
        }
    }
}
