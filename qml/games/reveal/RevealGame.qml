// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Giochi

// "Scopri chi è" - dietro le mattonelle c'è un animale. Si toccano le
// mattonelle per toglierle: quando è tutto scoperto, hai vinto.
MiniGame {
    id: g
    title: qsTr("Scopri chi è")
    age: qsTr("3-4 anni")
    levelCount: 8

    readonly property var animalsList: ["🐶", "🐱", "🐰", "🦊", "🐻", "🐸", "🐵", "🦁", "🐼", "🐷"]
    readonly property int cols: 4
    readonly property int rows: 3

    property string animal: "🐶"
    property var gone: []

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        animal = animalsList[i % animalsList.length]
        var n = cols * rows
        var arr = []
        for (var k = 0; k < n; k++) arr.push(false)
        gone = arr
    }

    function tapTile(idx) {
        if (won || gone[idx]) return
        var a = gone.slice()
        a[idx] = true
        gone = a
        snd.tap()
        if (a.indexOf(false) === -1) { snd.win(); win() }
    }

    // ---------- contenuto ----------
    Item {
        anchors.fill: parent

        Rectangle {
            id: pane
            anchors.centerIn: parent
            width: Math.min(parent.width - 60, 720)
            height: width * g.rows / g.cols
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: g.animal
                font.pixelSize: pane.height * 0.7
            }

            Grid {
                anchors.fill: parent
                columns: g.cols
                Repeater {
                    model: g.cols * g.rows
                    Item {
                        required property int index
                        width: pane.width / g.cols
                        height: pane.height / g.rows
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 12
                            color: Theme.playColors[parent.index % 6]
                            visible: !g.gone[parent.index]
                            scale: tma.pressed ? 0.9 : 1
                            Behavior on scale { NumberAnimation { duration: 70 } }
                        }
                        MouseArea {
                            id: tma
                            anchors.fill: parent
                            enabled: !g.won && !g.gone[parent.index]
                            onClicked: g.tapTile(parent.index)
                        }
                    }
                }
            }
        }
    }
}
