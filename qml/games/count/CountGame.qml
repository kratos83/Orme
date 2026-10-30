// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// "Conta" - quanti animali ci sono? Si tocca il numero giusto (1..5).
MiniGame {
    id: g
    title: qsTr("Conta")
    age: qsTr("4-5 anni")
    levelCount: 10

    readonly property var critters: ["🐶", "🐱", "🐰", "🐤", "🐸", "🐷", "🐨", "🦊"]

    property int  count: 3
    property string critter: "🐶"
    property var  options: [2, 3, 4]
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
        count = 1 + Math.floor(Math.random() * 5)
        critter = critters[Math.floor(Math.random() * critters.length)]
        var opts = [count]
        while (opts.length < 3) {
            var n = 1 + Math.floor(Math.random() * 5)
            if (opts.indexOf(n) === -1) opts.push(n)
        }
        options = shuffle(opts)
    }

    function pick(n) {
        if (answered) return
        if (n === count) {
            answered = true
            snd.win(); win()
        } else {
            snd.nope(); wrong()
        }
    }

    // ---------- contenuto ----------
    Item {
        anchors.fill: parent

        Flow {
            anchors {
                left: parent.left; right: parent.right
                top: parent.top; topMargin: 20
            }
            anchors.leftMargin: 40
            anchors.rightMargin: 40
            spacing: 24
            Repeater {
                model: g.count
                Text { text: g.critter; font.pixelSize: 110 }
            }
        }

        Row {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 40 }
            spacing: 34
            Repeater {
                model: g.options
                Rectangle {
                    required property var modelData
                    width: 128; height: 128; radius: 26
                    color: g.answered ? Theme.boardLine : Theme.dirUp
                    scale: nma.pressed && !g.answered ? 0.93 : 1
                    Behavior on scale { NumberAnimation { duration: 80 } }
                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData
                        font.pixelSize: 70
                        font.bold: true
                        color: "white"
                    }
                    MouseArea {
                        id: nma
                        anchors.fill: parent
                        enabled: !g.won
                        onClicked: g.pick(parent.modelData)
                    }
                }
            }
        }
    }
}
