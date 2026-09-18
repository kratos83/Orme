// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Conta le lettere: mostra una parola, scrivi con il tastierino quante
// lettere ha.
MiniGame {
    id: g
    title: qsTr("Conta le lettere")
    age: qsTr("6-7 anni")
    levelCount: 10

    readonly property var words: [
        "CASA", "GATTO", "SOLE", "SCUOLA", "QUADERNO", "FARFALLA", "ELEFANTE",
        "BICICLETTA", "MATITA", "FINESTRA", "ALBERO", "LIBRO", "OROLOGIO",
        "COMPUTER", "MONTAGNA", "CANE", "PANE", "TRENO", "NUVOLA", "ARCOBALENO"
    ]

    property string word: ""
    property string entered: ""
    property bool answered: false

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        answered = false
        entered = ""
        word = words[Math.floor(Math.random() * words.length)]
    }

    function digit(d) {
        if (answered) return
        snd.tap()
        if (entered.length < 2) entered += d
    }

    function backspace() {
        if (answered) return
        entered = entered.slice(0, -1)
    }

    function submit() {
        if (answered || entered === "") return
        if (parseInt(entered, 10) === word.length) {
            answered = true
            snd.win(); win()
        } else {
            snd.nope(); wrong()
            entered = ""
        }
    }

    // ---------- contenuto ----------
    Item {
        anchors.fill: parent

        Column {
            anchors.centerIn: parent
            spacing: 36

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Quante lettere ha questa parola?")
                font.pixelSize: 22
                color: Theme.text
                opacity: 0.75
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: wordText.implicitWidth + 48
                height: 100
                radius: 20
                color: Theme.panel
                border.color: Theme.boardLine
                border.width: 3
                Text { id: wordText; anchors.centerIn: parent; text: g.word; font.pixelSize: 44; font.bold: true; color: Theme.text }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 110; height: 76; radius: 16
                color: Theme.panel
                border.color: Theme.boardLine
                border.width: 3
                Text { anchors.centerIn: parent; text: g.entered; font.pixelSize: 38; font.bold: true; color: Theme.text }
            }

            NumberPad {
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: !g.answered
                onKeyPressed: (k) => g.digit(k)
                onBackspacePressed: g.backspace()
                onEnterPressed: g.submit()
            }
        }
    }
}
