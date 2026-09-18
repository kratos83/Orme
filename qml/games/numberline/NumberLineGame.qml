// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// La linea dei numeri: si sceglie la lunghezza (5/10/20) e la modalità
// (conta, addizione, sottrazione), poi si tocca sulla linea la casella con
// il numero giusto.
MiniGame {
    id: g
    title: qsTr("La linea dei numeri")
    age: qsTr("6-8 anni")
    levelCount: 8

    property int maxN: 10
    property string mode: "count"   // "count" | "add" | "sub"
    property bool started: false
    property int target: 0
    property int opA: 0
    property int opB: 0
    property bool answered: false

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function randInt(min, max) { return min + Math.floor(Math.random() * (max - min + 1)) }

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        answered = false
        if (mode === "add") {
            opA = randInt(0, maxN)
            opB = randInt(0, maxN - opA)
            target = opA + opB
        } else if (mode === "sub") {
            opA = randInt(0, maxN)
            opB = randInt(0, opA)
            target = opA - opB
        } else {
            target = randInt(0, maxN)
        }
    }

    function tapNumber(n) {
        if (answered || !started) return
        if (n === target) {
            answered = true
            snd.win(); win()
        } else {
            snd.nope(); wrong()
        }
    }

    function promptText() {
        if (mode === "add") return opA + " + " + opB + " = ?"
        if (mode === "sub") return opA + " − " + opB + " = ?"
        return qsTr("Tocca il numero") + " " + target
    }

    // ---------- contenuto ----------
    Item {
        anchors.fill: parent
        visible: g.started

        Text {
            id: prompt
            anchors { top: parent.top; topMargin: 30; horizontalCenter: parent.horizontalCenter }
            text: g.promptText()
            font.pixelSize: 34
            font.bold: true
            color: Theme.text
        }

        Flickable {
            anchors { top: prompt.bottom; topMargin: 50; left: parent.left; right: parent.right; bottom: parent.bottom; margins: 20 }
            contentWidth: lineRow.width
            contentHeight: height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Row {
                id: lineRow
                spacing: 8

                Repeater {
                    model: g.maxN + 1
                    Rectangle {
                        id: cell
                        required property int index
                        width: 64; height: 64; radius: 32
                        color: Theme.playColors[index % Theme.playColors.length]
                        opacity: !g.answered || index === g.target ? 1 : 0.3
                        scale: cellMa.pressed && !g.answered ? 0.92 : 1
                        Behavior on scale { NumberAnimation { duration: 80 } }
                        border.width: g.answered && index === g.target ? 5 : 0
                        border.color: "white"
                        Text { anchors.centerIn: parent; text: cell.index; font.pixelSize: 22; font.bold: true; color: "white" }
                        MouseArea { id: cellMa; anchors.fill: parent; enabled: !g.answered; onClicked: g.tapNumber(cell.index) }
                    }
                }
            }
        }
    }

    // ---------- schermata di scelta lunghezza e modalità ----------
    Rectangle {
        anchors.fill: parent
        color: Theme.background
        visible: !g.started

        Column {
            anchors.centerIn: parent
            spacing: 30

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Quanto lunga?")
                font.pixelSize: 26
                font.bold: true
                color: Theme.text
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14
                Repeater {
                    model: [5, 10, 20]
                    Rectangle {
                        id: lenChip
                        required property int modelData
                        width: 84; height: 74; radius: 20
                        color: g.maxN === modelData ? Theme.accent : Theme.panel
                        border.color: Theme.boardLine
                        border.width: 3
                        scale: lenMa.pressed ? 0.92 : 1
                        Behavior on scale { NumberAnimation { duration: 80 } }
                        Text { anchors.centerIn: parent; text: lenChip.modelData; font.pixelSize: 28; font.bold: true; color: g.maxN === lenChip.modelData ? "white" : Theme.text }
                        MouseArea { id: lenMa; anchors.fill: parent; onClicked: g.maxN = lenChip.modelData }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Che gioco?")
                font.pixelSize: 26
                font.bold: true
                color: Theme.text
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14
                Repeater {
                    model: [
                        { m: "count", label: qsTr("Conta"), icon: "🔢" },
                        { m: "add", label: qsTr("Addizione"), icon: "➕" },
                        { m: "sub", label: qsTr("Sottrazione"), icon: "➖" }
                    ]
                    Rectangle {
                        id: modeChip
                        required property var modelData
                        width: 130; height: 100; radius: 20
                        color: g.mode === modelData.m ? Theme.accent : Theme.panel
                        border.color: Theme.boardLine
                        border.width: 3
                        scale: modeMa.pressed ? 0.92 : 1
                        Behavior on scale { NumberAnimation { duration: 80 } }
                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modeChip.modelData.icon; font.pixelSize: 34 }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modeChip.modelData.label; font.pixelSize: 16; font.bold: true; color: g.mode === modeChip.modelData.m ? "white" : Theme.text }
                        }
                        MouseArea { id: modeMa; anchors.fill: parent; onClicked: g.mode = modeChip.modelData.m }
                    }
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 200; height: 76; radius: 22
                color: Theme.dirUp
                scale: startMa.pressed ? 0.95 : 1
                Behavior on scale { NumberAnimation { duration: 80 } }
                Text { anchors.centerIn: parent; text: qsTr("Inizia"); font.pixelSize: 26; font.bold: true; color: "white" }
                MouseArea { id: startMa; anchors.fill: parent; onClicked: { g.started = true; g.buildLevel(0) } }
            }
        }
    }
}
