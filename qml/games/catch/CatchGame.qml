// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// "Acchiappa i conigli" - tocca solo i conigli 🐰 (gli altri animali no).
// Concetto: condizione "se è un coniglio -> prendilo".
MiniGame {
    id: g
    title: qsTr("Acchiappa i conigli")
    age: qsTr("3-5 anni")
    levelCount: 4

    readonly property int need: 6
    readonly property var distract: ["🐭", "🐹", "🐦", "🐷", "🐮", "🐔"]

    property int done: 0
    property var slots: []

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        done = 0
        var a = []
        for (var k = 0; k < 5; k++) a.push(makeSlot())
        slots = a
    }

    function makeSlot() {
        var rabbit = Math.random() < 0.6
        return {
            emoji: rabbit ? "🐰" : distract[Math.floor(Math.random() * distract.length)],
            rabbit: rabbit,
            fx: Math.random(),
            fy: Math.random()
        }
    }

    function respawn(i) {
        var a = slots.slice()
        a[i] = makeSlot()
        slots = a
    }

    function tapSlot(i) {
        if (won) return
        if (slots[i].rabbit) {
            snd.ok()
            done += 1
            if (done >= need) { snd.win(); win() }
            else respawn(i)
        } else {
            snd.nope()
            wrong()
        }
    }

    // ---------- contenuto ----------
    Item {
        id: area
        anchors.fill: parent

        // HUD in alto: cosa acchiappare + progresso
        Row {
            id: hud
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
            spacing: 18
            Text { text: "🐰"; font.pixelSize: 56; anchors.verticalCenter: parent.verticalCenter }
            Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: g.need
                    Rectangle {
                        width: 18; height: 18; radius: 9
                        color: index < g.done ? Theme.accent : Theme.boardLine
                    }
                }
            }
        }

        Text {   // cesto
            id: basket
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
            text: "🧺"
            font.pixelSize: 80
        }

        // campo di gioco: sta fra HUD e cesto, i conigli non escono da qui
        Item {
            id: field
            anchors {
                top: hud.bottom; topMargin: 14
                left: parent.left; right: parent.right
                bottom: basket.top; bottomMargin: 8
            }

            Repeater {
                model: g.slots

                Item {
                    id: cell
                    required property int index
                    required property var modelData
                    width: 128; height: 128
                    x: modelData.fx * Math.max(1, field.width  - width)
                    y: modelData.fy * Math.max(1, field.height - height)

                    Behavior on x { NumberAnimation { duration: 300 } }
                    Behavior on y { NumberAnimation { duration: 300 } }

                    Text {
                        id: face
                        anchors.centerIn: parent
                        text: cell.modelData.emoji
                        font.pixelSize: 96
                    }

                    SequentialAnimation on scale {
                        running: true
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 1.08; duration: 620 + cell.index * 80; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 1.08; to: 1.0; duration: 620 + cell.index * 80; easing.type: Easing.InOutSine }
                    }

                    SequentialAnimation {
                        id: nono
                        NumberAnimation { target: face; property: "rotation"; to: -14; duration: 55 }
                        NumberAnimation { target: face; property: "rotation"; to:  14; duration: 55 }
                        NumberAnimation { target: face; property: "rotation"; to:   0; duration: 55 }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -10
                        enabled: !g.won
                        onClicked: {
                            if (!cell.modelData.rabbit) nono.restart()
                            g.tapSlot(cell.index)
                        }
                    }
                }
            }
        }
    }
}
