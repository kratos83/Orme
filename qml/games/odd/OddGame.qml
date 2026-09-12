// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Giochi

// "Trova l'intruso" - quattro figure, tre uguali e una diversa: si tocca
// quella diversa.
MiniGame {
    id: g
    title: qsTr("Trova l'intruso")
    age: qsTr("3-5 anni")
    levelCount: 12

    readonly property var pool: ["🍎", "🍌", "🐶", "🐱", "⭐", "🌸", "🚗", "🐟", "🎈", "🍄"]

    property var  cards: ["🍎", "🍎", "🍌", "🍎"]
    property int  oddIndex: 2
    property bool answered: false

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        answered = false
        var a = pool.slice()
        for (var k = a.length - 1; k > 0; k--) {
            var j = Math.floor(Math.random() * (k + 1))
            var t = a[k]; a[k] = a[j]; a[j] = t
        }
        var same = a[0], diff = a[1]
        oddIndex = Math.floor(Math.random() * 4)
        var c = []
        for (var n = 0; n < 4; n++) c.push(n === oddIndex ? diff : same)
        cards = c
    }

    function pick(idx) {
        if (answered) return
        if (idx === oddIndex) {
            answered = true
            snd.win(); win()
        } else {
            snd.nope(); wrong()
        }
    }

    // ---------- contenuto ----------
    Grid {
        anchors.centerIn: parent
        columns: 2
        rowSpacing: 30
        columnSpacing: 30
        Repeater {
            model: g.cards
            Rectangle {
                id: card
                required property int index
                required property var modelData
                width: 190; height: 190; radius: 28
                color: Theme.panel
                border.color: Theme.boardLine
                border.width: 3
                opacity: g.answered ? 0.4 : 1
                scale: oma.pressed && !g.answered ? 0.93 : 1
                Behavior on scale { NumberAnimation { duration: 80 } }

                Text { anchors.centerIn: parent; text: card.modelData; font.pixelSize: 110 }

                SequentialAnimation {
                    id: nono
                    NumberAnimation { target: card; property: "rotation"; to: -10; duration: 55 }
                    NumberAnimation { target: card; property: "rotation"; to:  10; duration: 55 }
                    NumberAnimation { target: card; property: "rotation"; to:   0; duration: 55 }
                }

                MouseArea {
                    id: oma
                    anchors.fill: parent
                    enabled: !g.won
                    onClicked: {
                        if (card.index !== g.oddIndex) nono.restart()
                        g.pick(card.index)
                    }
                }
            }
        }
    }
}
