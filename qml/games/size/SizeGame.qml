// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// "Il più grande" - due o tre figure uguali di misura diversa: si tocca
// la più grande.
MiniGame {
    id: g
    title: qsTr("Il più grande")
    age: qsTr("3-4 anni")
    levelCount: 12

    readonly property var pool: ["🐘", "🐻", "🐰", "🐤", "🌳", "🍎", "⭐", "🚗", "🎈", "🐟"]

    property var  sizes: [90, 150, 60]
    property string critter: "🐰"
    property int  bigIndex: 1
    property bool answered: false

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        answered = false
        critter = pool[Math.floor(Math.random() * pool.length)]
        var n = 2 + Math.floor(Math.random() * 2)   // 2 o 3 figure
        var s = []
        var base = [70, 110, 150, 190]
        for (var k = 0; k < n; k++) s.push(base[k])
        for (var m = s.length - 1; m > 0; m--) {
            var j = Math.floor(Math.random() * (m + 1))
            var t = s[m]; s[m] = s[j]; s[j] = t
        }
        sizes = s
        bigIndex = 0
        for (var q = 1; q < s.length; q++) if (s[q] > s[bigIndex]) bigIndex = q
    }

    function pick(idx) {
        if (answered) return
        if (idx === bigIndex) {
            answered = true
            snd.win(); win()
        } else {
            snd.nope(); wrong()
        }
    }

    // ---------- contenuto ----------
    Row {
        anchors.centerIn: parent
        spacing: 50
        Repeater {
            model: g.sizes
            Item {
                required property int index
                required property var modelData
                width: 210; height: 210
                Text {
                    anchors.centerIn: parent
                    text: g.critter
                    font.pixelSize: parent.modelData
                    opacity: g.answered ? 0.4 : 1
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: !g.won
                    onClicked: g.pick(parent.index)
                }
            }
        }
    }
}
