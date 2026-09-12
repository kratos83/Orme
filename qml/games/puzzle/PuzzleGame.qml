// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Giochi

// "Puzzle" - quattro pezzi da trascinare nella loro casella (2x2). Ogni
// casella mostra in trasparenza il pezzo che ci va.
MiniGame {
    id: g
    title: qsTr("Puzzle")
    age: qsTr("3-5 anni")
    levelCount: 5

    readonly property var scenes: [
        ["🌳", "🏠", "☀️", "☁️"],
        ["🐶", "🦴", "🐱", "🧶"],
        ["🚗", "🛣️", "🌈", "⛽"],
        ["🐝", "🌼", "🦋", "🍀"],
        ["🐟", "🌊", "🐚", "⛵"]
    ]

    property var pieces: ["🌳", "🏠", "☀️", "☁️"]
    property var placed: [false, false, false, false]
    property var order: [0, 1, 2, 3]   // ordine sparso dei pezzi in basso

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        placed = [false, false, false, false]
        pieces = scenes[i]
        var o = [0, 1, 2, 3]
        for (var k = o.length - 1; k > 0; k--) {
            var j = Math.floor(Math.random() * (k + 1))
            var t = o[k]; o[k] = o[j]; o[j] = t
        }
        order = o
    }

    function slotX(idx) { return frame.x + (idx % 2) * 170 + 10 }
    function slotY(idx) { return frame.y + Math.floor(idx / 2) * 170 + 10 }

    function tryPlace(idx, cx, cy) {
        var sx = slotX(idx) + 75, sy = slotY(idx) + 75
        if (Math.hypot(cx - sx, cy - sy) < 95) {
            var p = placed.slice()
            p[idx] = true
            placed = p
            snd.ok()
            if (p.indexOf(false) === -1) { snd.win(); win() }
            return true
        }
        return false
    }

    // ---------- contenuto ----------
    Item {
        id: area
        anchors.fill: parent

        // cornice 2x2
        Rectangle {
            id: frame
            width: 340; height: 340
            radius: 20
            color: "transparent"
            border.color: Theme.boardLine
            border.width: 4
            anchors.horizontalCenter: parent.horizontalCenter
            y: 20

            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    x: (index % 2) * 170 + 10
                    y: Math.floor(index / 2) * 170 + 10
                    width: 150; height: 150; radius: 16
                    color: Theme.boardFill
                    Text {
                        anchors.centerIn: parent
                        text: g.pieces[parent.index]
                        font.pixelSize: 96
                        opacity: g.placed[parent.index] ? 0 : 0.25
                    }
                }
            }
        }

        // pezzi già sistemati (fermi nella cornice)
        Repeater {
            model: 4
            Text {
                required property int index
                visible: g.placed[index]
                text: g.pieces[index]
                font.pixelSize: 96
                x: g.slotX(index) + 75 - width / 2
                y: g.slotY(index) + 75 - height / 2
            }
        }

        // pezzi da trascinare
        Repeater {
            model: 4
            Item {
                id: piece
                required property int index          // posizione in "order"
                property int pid: g.order[index]     // quale pezzo è
                width: 150; height: 150
                visible: !g.placed[piece.pid]

                property real homeX: 40 + index * ((area.width - 260) / 3)
                property real homeY: area.height - 190

                function home() { x = homeX; y = homeY }
                onHomeXChanged: if (!dragMA.drag.active) x = homeX
                onHomeYChanged: if (!dragMA.drag.active) y = homeY
                Component.onCompleted: home()

                Behavior on x { enabled: !dragMA.drag.active; NumberAnimation { duration: 180 } }
                Behavior on y { enabled: !dragMA.drag.active; NumberAnimation { duration: 180 } }

                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: Theme.panel
                    border.color: Theme.boardLine
                    border.width: 3
                    Text { anchors.centerIn: parent; text: g.pieces[piece.pid]; font.pixelSize: 96 }
                }

                MouseArea {
                    id: dragMA
                    anchors.fill: parent
                    enabled: !g.won && !g.placed[piece.pid]
                    drag.target: piece
                    drag.minimumX: 0; drag.maximumX: area.width - piece.width
                    drag.minimumY: 0; drag.maximumY: area.height - piece.height
                    onReleased: {
                        var cx = piece.x + piece.width / 2
                        var cy = piece.y + piece.height / 2
                        if (!g.tryPlace(piece.pid, cx, cy))
                            piece.home()
                    }
                }
            }
        }
    }
}
