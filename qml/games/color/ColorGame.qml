// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Giochi

// "Tocca il colore" - in alto una macchia di colore da cercare, sotto
// quattro cerchi: si tocca quello dello stesso colore.
MiniGame {
    id: g
    title: qsTr("Tocca il colore")
    age: qsTr("3-4 anni")
    levelCount: 12

    property int  target: 0
    property var  choices: [0, 1, 2, 3]
    property bool answered: false

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function shuffle(a) {
        var r = a.slice()
        for (var k = r.length - 1; k > 0; k--) {
            var j = Math.floor(Math.random() * (k + 1))
            var t = r[k]; r[k] = r[j]; r[j] = t
        }
        return r
    }

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        answered = false
        var all = shuffle([0, 1, 2, 3, 4, 5])
        choices = all.slice(0, 4)
        target = choices[Math.floor(Math.random() * choices.length)]
    }

    function pick(c) {
        if (answered) return
        if (c === target) {
            answered = true
            snd.win(); win()
        } else {
            snd.nope(); wrong()
        }
    }

    // ---------- contenuto ----------
    Item {
        anchors.fill: parent

        Rectangle {   // colore da cercare
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 24 }
            width: 150; height: 150; radius: 32
            color: Theme.playColors[g.target]
            border.color: Theme.boardLine
            border.width: 4
        }

        Grid {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 60
            columns: 2
            rowSpacing: 30
            columnSpacing: 30
            Repeater {
                model: g.choices
                Rectangle {
                    required property var modelData
                    width: 150; height: 150; radius: 75
                    color: Theme.playColors[modelData]
                    opacity: g.answered ? 0.4 : 1
                    scale: cma.pressed && !g.answered ? 0.92 : 1
                    Behavior on scale { NumberAnimation { duration: 80 } }
                    MouseArea {
                        id: cma
                        anchors.fill: parent
                        enabled: !g.won
                        onClicked: g.pick(parent.modelData)
                    }
                }
            }
        }
    }
}
