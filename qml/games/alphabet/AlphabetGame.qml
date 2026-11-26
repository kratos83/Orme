// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// L'alfabeto: una figura con la parola sotto (es. un'ape: APE), tocca la lettera
// con cui inizia la parola fra due carte - la posizione di quella giusta
// cambia ad ogni livello, non è mai sempre nella stessa.
MiniGame {
    id: g
    title: qsTr("L'alfabeto")
    scenery: "scuola"
    age: qsTr("6-8 anni")
    levelCount: 12

    readonly property var items: [
        { word: qsTr("APE"), img: "bee", letter: "A" },
        { word: qsTr("BARCA"), img: "sailboat", letter: "B" },
        { word: qsTr("CASA"), img: "house", letter: "C" },
        { word: qsTr("DADO"), img: "die", letter: "D" },
        { word: qsTr("ELEFANTE"), img: "elephant", letter: "E" },
        { word: qsTr("FUNGO"), img: "mushroom", letter: "F" },
        { word: qsTr("GATTO"), img: "cat", letter: "G" },
        { word: qsTr("HOTEL"), img: "hotel", letter: "H" },
        { word: qsTr("ISOLA"), img: "island", letter: "I" },
        { word: qsTr("LUNA"), img: "moon", letter: "L" },
        { word: qsTr("MELA"), img: "apple", letter: "M" },
        { word: qsTr("NAVE"), img: "ship", letter: "N" },
        { word: qsTr("ORSO"), img: "bear", letter: "O" },
        { word: qsTr("PESCE"), img: "fish", letter: "P" },
        { word: qsTr("QUADRO"), img: "picture", letter: "Q" },
        { word: qsTr("RANA"), img: "frog", letter: "R" },
        { word: qsTr("SOLE"), img: "sun", letter: "S" },
        { word: qsTr("TIGRE"), img: "tiger", letter: "T" },
        { word: qsTr("UOVO"), img: "egg", letter: "U" },
        { word: qsTr("VOLPE"), img: "fox", letter: "V" },
        { word: qsTr("ZAINO"), img: "backpack", letter: "Z" }
    ]

    property var current: items[0]
    property var options: []       // due lettere, ordine casuale (posizione della giusta sempre a caso)
    property var cardColors: []
    property bool answered: false

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        answered = false
        current = items[Math.floor(Math.random() * items.length)]

        var wrongLetter
        do {
            wrongLetter = items[Math.floor(Math.random() * items.length)].letter
        } while (wrongLetter === current.letter)

        options = Math.random() < 0.5 ? [current.letter, wrongLetter] : [wrongLetter, current.letter]

        var palette = [Theme.dirUp, Theme.dirDown, Theme.dirLeft, Theme.dirRight, Theme.accent]
        var c1 = palette[Math.floor(Math.random() * palette.length)]
        var c2
        do {
            c2 = palette[Math.floor(Math.random() * palette.length)]
        } while (c2 === c1)
        cardColors = [c1, c2]
    }

    function pick(letter) {
        if (answered) return
        if (letter === current.letter) {
            answered = true
            snd.win(); win()
        } else {
            snd.nope(); wrong()
        }
    }

    // ---------- contenuto ----------
    Item {
        anchors.fill: parent

        Row {
            anchors.centerIn: parent
            spacing: 50

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                AppIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: g.current.img
                    size: 126
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: g.current.word
                    font.pixelSize: 30
                    font.bold: true
                    color: Theme.text
                }
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 24
                Repeater {
                    model: g.options
                    Rectangle {
                        id: card
                        Candy {}
                        required property string modelData
                        required property int index
                        width: 150; height: 190; radius: 22
                        color: g.cardColors[index]
                        opacity: g.answered && modelData !== g.current.letter ? 0.4 : 1
                        scale: cardMa.pressed ? 0.94 : 1
                        Behavior on scale { NumberAnimation { duration: 80 } }

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - 30
                            height: parent.height - 30
                            radius: 14
                            color: Theme.panel
                            Text {
                                anchors.centerIn: parent
                                text: card.modelData
                                font.pixelSize: 96
                                font.bold: true
                                color: card.color
                            }
                        }

                        MouseArea { id: cardMa; anchors.fill: parent; enabled: !g.won; onClicked: g.pick(card.modelData) }
                    }
                }
            }
        }
    }
}
