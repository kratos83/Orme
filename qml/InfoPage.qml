// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

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
                        text: qsTr("45 giochi touch per bambini della scuola dell'infanzia e della primaria: dai concetti del coding (sequenze, cicli, pattern, classificazione, ordine) fino a numeri, operazioni, tabelline, grammatica e geografia. Bersagli grandi, nessuna schermata di sconfitta.")
                    }
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        font.pixelSize: 17
                        color: Theme.text
                        opacity: 0.85
                        text: qsTr("All'inizio di ogni gioco si può scrivere il nome del bambino oppure premere \"Salta\"; il nome si può cambiare durante il gioco con il tasto 👤. Ogni livello vinto dà da 1 a 3 faccine 😊 e si passa da soli al livello dopo.")
                    }
                    Row {
                        spacing: 14
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Versione %1").arg(Updater.currentVersion)
                            font.pixelSize: 14
                            color: Theme.text
                            opacity: 0.6
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: checkText.implicitWidth + 24; height: 34; radius: 17
                            color: Theme.panel
                            border.color: Theme.boardLine
                            border.width: 2
                            scale: checkMa.pressed ? 0.95 : 1
                            Behavior on scale { NumberAnimation { duration: 80 } }
                            Text {
                                id: checkText
                                anchors.centerIn: parent
                                text: Updater.checking ? qsTr("Verifica in corso...") : qsTr("Cerca aggiornamenti")
                                font.pixelSize: 13
                                font.bold: true
                                color: Theme.text
                            }
                            MouseArea { id: checkMa; anchors.fill: parent; enabled: !Updater.checking; onClicked: Updater.checkForUpdates() }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !Updater.checking && !Updater.updateAvailable && Updater.latestVersion !== ""
                            text: qsTr("Hai già l'ultima versione")
                            font.pixelSize: 13
                            color: Theme.accentDark
                        }
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
                text: qsTr("Giochi per l'infanzia")
                font.pixelSize: 24
                font.bold: true
                color: Theme.text
            }

            // ----- elenco giochi Infanzia -----
            Repeater {
                model: Catalog.games.filter((g) => g.cat === "infanzia")

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
                            text: card.modelData.e ? card.modelData.e : "▶"
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

            Text {
                text: qsTr("Giochi per la primaria")
                font.pixelSize: 24
                font.bold: true
                color: Theme.text
            }

            // ----- elenco giochi Primaria -----
            Repeater {
                model: Catalog.games.filter((g) => g.cat === "primaria")

                Rectangle {
                    id: card2
                    required property var modelData
                    width: col.width
                    height: Math.max(100, body2.implicitHeight + 26)
                    radius: 18
                    color: Theme.panel
                    border.color: Theme.boardLine
                    border.width: 2
                    scale: card2Ma.pressed ? 0.99 : 1
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    Rectangle {
                        id: badge2
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        width: 74; height: 74; radius: 18
                        color: card2.modelData.c
                        Text {
                            anchors.centerIn: parent
                            text: card2.modelData.e ? card2.modelData.e : "▶"
                            font.pixelSize: 40
                            color: "white"
                        }
                    }

                    Rectangle {
                        id: ageChip2
                        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                        width: chipT2.implicitWidth + 16
                        height: 26
                        radius: 13
                        color: card2.modelData.c
                        opacity: 0.9
                        Text {
                            id: chipT2
                            anchors.centerIn: parent
                            text: card2.modelData.age
                            font.pixelSize: 13
                            font.bold: true
                            color: "white"
                        }
                    }

                    Column {
                        id: body2
                        anchors {
                            left: badge2.right; leftMargin: 16
                            right: ageChip2.left; rightMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 4
                        Text {
                            text: card2.modelData.title
                            font.pixelSize: 20
                            font.bold: true
                            color: Theme.text
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: card2.modelData.desc
                            font.pixelSize: 14
                            color: Theme.text
                            opacity: 0.75
                        }
                    }

                    MouseArea {
                        id: card2Ma
                        anchors.fill: parent
                        onClicked: root.gameSelected(card2.modelData.id)
                    }
                }
            }
        }
    }
}
