// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Frazioni: tre tipi di domanda che si alternano di livello in livello -
// frazione di un intero (num/den esatto), frazione di un numero (es. "2/5
// di 20"), frazioni equivalenti (es. "3/10 = ?/100"). Risposta con tastierino.
MiniGame {
    id: g
    title: qsTr("Frazioni")
    age: qsTr("9-10 anni")
    levelCount: 9

    property int mode: 0          // 0 = frazione di un intero, 1 = frazione di un numero, 2 = equivalenti
    property int num: 1
    property int den: 2
    property int wholeNumber: 0   // usato solo per mode 1
    property int targetDen: 0     // usato solo per mode 2
    property int answer: 0
    property string entered: ""
    property bool answered: false

    SoundBank { id: snd }

    component FractionVisual: Column {
        property int numerator: 0
        property int denominator: 1
        spacing: 4
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: numerator; font.pixelSize: 40; font.bold: true; color: Theme.text }
        Rectangle { width: 46; height: 4; radius: 2; color: Theme.text; anchors.horizontalCenter: parent.horizontalCenter }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: denominator; font.pixelSize: 40; font.bold: true; color: Theme.text }
    }

    onBuildLevel: (i) => load(i)

    function randInt(min, max) { return min + Math.floor(Math.random() * (max - min + 1)) }

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        answered = false
        entered = ""
        mode = i % 3
        if (mode === 0) {
            den = randInt(2, 9)
            var q = randInt(2, 9)
            num = den * q
            answer = q
        } else if (mode === 1) {
            den = randInt(2, 6)
            num = randInt(1, den - 1)
            var factor = randInt(2, 8)
            wholeNumber = den * factor
            answer = num * factor
        } else {
            den = Math.random() < 0.5 ? 10 : 100
            targetDen = den * 10
            num = randInt(1, den - 1)
            answer = num * 10
        }
    }

    function digit(d) {
        if (answered) return
        snd.tap()
        if (entered.length < 4) entered += d
    }

    function backspace() {
        if (answered) return
        entered = entered.slice(0, -1)
    }

    function submit() {
        if (answered || entered === "") return
        if (parseInt(entered, 10) === answer) {
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

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 18

                FractionVisual { numerator: g.num; denominator: g.den; anchors.verticalCenter: parent.verticalCenter }

                Text {
                    visible: g.mode === 1
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("di") + " " + g.wholeNumber
                    font.pixelSize: 30
                    color: Theme.text
                }

                Text { anchors.verticalCenter: parent.verticalCenter; text: "="; font.pixelSize: 46; font.bold: true; color: Theme.text }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 100; height: 76; radius: 16
                    color: Theme.panel
                    border.width: 3
                    border.color: Theme.boardLine
                    Text { anchors.centerIn: parent; text: g.entered; font.pixelSize: 34; font.bold: true; color: Theme.text }
                }

                Text {
                    visible: g.mode === 2
                    anchors.verticalCenter: parent.verticalCenter
                    text: "/" + g.targetDen
                    font.pixelSize: 30
                    font.bold: true
                    color: Theme.text
                }
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
