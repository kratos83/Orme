// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Giochi

// "Sveglia gli animali" - ogni animale dorme (💤). Toccandolo si sveglia e
// fa un saltino. Quando sono tutti svegli, hai vinto.
MiniGame {
    id: g
    title: qsTr("Sveglia gli animali")
    age: qsTr("3-4 anni")
    levelCount: 3

    readonly property var sets: [
        ["🐶", "🐱", "🐰", "🐻", "🦊", "🐸"],
        ["🐷", "🐮", "🐔", "🐴", "🐑", "🐹"],
        ["🦁", "🐨", "🐼", "🐵", "🐯", "🦉"]
    ]

    property var awake: [false, false, false, false, false, false]

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        awake = [false, false, false, false, false, false]
    }

    function wake(idx) {
        if (won || awake[idx]) return
        var a = awake.slice()
        a[idx] = true
        awake = a
        snd.ok()
        if (a.indexOf(false) === -1) { snd.win(); win() }
    }

    // ---------- contenuto ----------
    Grid {
        anchors.centerIn: parent
        columns: 3
        rowSpacing: 30
        columnSpacing: 40
        Repeater {
            model: g.sets[g.levelIndex]
            Item {
                id: pen
                required property int index
                required property var modelData
                width: 190; height: 190

                Text {
                    id: animal
                    anchors.centerIn: parent
                    text: pen.modelData
                    font.pixelSize: 110
                    opacity: g.awake[pen.index] ? 1 : 0.5
                }
                Text {
                    visible: !g.awake[pen.index]
                    anchors { right: parent.right; top: parent.top }
                    text: "💤"
                    font.pixelSize: 44
                }

                SequentialAnimation {
                    id: jump
                    NumberAnimation { target: animal; property: "anchors.verticalCenterOffset"; to: -30; duration: 140; easing.type: Easing.OutQuad }
                    NumberAnimation { target: animal; property: "anchors.verticalCenterOffset"; to: 0;   duration: 200; easing.type: Easing.OutBounce }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !g.won && !g.awake[pen.index]
                    onClicked: { jump.restart(); g.wake(pen.index) }
                }
            }
        }
    }
}
