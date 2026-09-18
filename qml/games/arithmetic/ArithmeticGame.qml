// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Addizioni, sottrazioni, moltiplicazioni o divisioni (con resto): un
// problema alla volta, risposta con il tastierino numerico. Lo stesso
// componente serve tutte e quattro le operazioni tramite "opMode".
MiniGame {
    id: g
    property string opMode: "add"   // "add" | "sub" | "mul" | "div"
    levelCount: 10

    readonly property var _titles: ({
        add: qsTr("Addizioni"), sub: qsTr("Sottrazioni"),
        mul: qsTr("Moltiplicazioni"), div: qsTr("Divisioni")
    })
    readonly property var _ages: ({
        add: qsTr("6-7 anni"), sub: qsTr("6-7 anni"),
        mul: qsTr("8-9 anni"), div: qsTr("8-9 anni")
    })
    readonly property var _symbols: ({ add: "+", sub: "−", mul: "×", div: ":" })

    title: _titles[opMode]
    age: _ages[opMode]

    property int numA: 0
    property int numB: 0
    property int answer: 0        // per add/sub/mul: il risultato; per div: il quoziente
    property int remainder: 0     // solo per div
    property bool isDiv: opMode === "div"
    property string enteredQ: ""
    property string enteredR: ""
    property string activeField: "q"   // "q" o "r" (solo per div)
    property bool answered: false

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function randInt(min, max) { return min + Math.floor(Math.random() * (max - min + 1)) }

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        answered = false
        enteredQ = ""
        enteredR = ""
        activeField = "q"
        switch (opMode) {
        case "add":
            numA = randInt(1, 50); numB = randInt(1, 50); answer = numA + numB
            break
        case "sub":
            numA = randInt(10, 60); numB = randInt(1, numA); answer = numA - numB
            break
        case "mul":
            numA = randInt(2, 10); numB = randInt(2, 10); answer = numA * numB
            break
        case "div": {
            var divisor = randInt(2, 9)
            var quotient = randInt(2, 12)
            var rest = randInt(0, divisor - 1)
            numB = divisor
            numA = quotient * divisor + rest
            answer = quotient
            remainder = rest
            break
        }
        }
    }

    function digit(d) {
        if (answered) return
        snd.tap()
        if (isDiv && activeField === "r") {
            if (enteredR.length < 2) enteredR += d
        } else {
            if (enteredQ.length < 3) enteredQ += d
        }
    }

    function backspace() {
        if (answered) return
        if (isDiv && activeField === "r") enteredR = enteredR.slice(0, -1)
        else enteredQ = enteredQ.slice(0, -1)
    }

    function submit() {
        if (answered) return
        if (enteredQ === "" || (isDiv && enteredR === "")) return
        var qOk = parseInt(enteredQ, 10) === answer
        var rOk = !isDiv || parseInt(enteredR, 10) === remainder
        if (qOk && rOk) {
            answered = true
            snd.win(); win()
        } else {
            snd.nope(); wrong()
            enteredQ = ""; enteredR = ""; activeField = "q"
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

                Text { text: g.numA; font.pixelSize: 58; font.bold: true; color: Theme.text }
                Text { text: g._symbols[g.opMode]; font.pixelSize: 58; font.bold: true; color: Theme.accent }
                Text { text: g.numB; font.pixelSize: 58; font.bold: true; color: Theme.text }
                Text { text: "="; font.pixelSize: 58; font.bold: true; color: Theme.text }

                Rectangle {
                    width: 110; height: 76; radius: 16
                    color: Theme.panel
                    border.width: 3
                    border.color: g.isDiv && g.activeField === "q" ? Theme.accent : Theme.boardLine
                    anchors.verticalCenter: parent.verticalCenter
                    Text { anchors.centerIn: parent; text: g.enteredQ; font.pixelSize: 38; font.bold: true; color: Theme.text }
                    MouseArea { anchors.fill: parent; enabled: g.isDiv; onClicked: g.activeField = "q" }
                }

                Text {
                    visible: g.isDiv
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("resto")
                    font.pixelSize: 20
                    color: Theme.text
                    opacity: 0.7
                }

                Rectangle {
                    visible: g.isDiv
                    width: 90; height: 76; radius: 16
                    color: Theme.panel
                    border.width: 3
                    border.color: g.activeField === "r" ? Theme.accent : Theme.boardLine
                    anchors.verticalCenter: parent.verticalCenter
                    Text { anchors.centerIn: parent; text: g.enteredR; font.pixelSize: 38; font.bold: true; color: Theme.text }
                    MouseArea { anchors.fill: parent; onClicked: g.activeField = "r" }
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
