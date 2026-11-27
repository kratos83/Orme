// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// "Puzzle dei trenini" - puzzle a incastro: i pezzi sono sparsi ai lati (o sotto)
// e si trascinano sul disegno, che si intravede nella cornice. Livello dopo
// livello i pezzi aumentano: 4, 6, 9, 12. Finiti i quattro livelli si passa a
// un disegno nuovo (i trenini, il mare, la notte, il passaggio a livello) e
// dopo l'ultimo si ricomincia dal primo.
//
// I disegni e i pezzi si preparano con scripts/make_scene.py e
// make_puzzle.py: nomi e misure qui sotto devono coincidere con quelli degli
// script.
MiniGame {
    id: g
    title: qsTr("Puzzle dei trenini")
    scenery: "cameretta"
    age: qsTr("3-5 anni")
    levelCount: pictures.length * grids.length

    readonly property var pictures: ["trenini", "mare", "notte", "segnali"]
    property string picture: pictures[0]
    readonly property string folder: "qrc:/qt/qml/Orme/assets/puzzle/" + picture + "/"
    readonly property int imageW: 600
    readonly property int imageH: 840
    readonly property var grids: [[2, 2], [2, 3], [3, 3], [3, 4]]

    property int cols: 2
    property int rows: 2
    readonly property real cellW: imageW / cols
    readonly property real cellH: imageH / rows
    readonly property real pad: Math.round(Math.min(cellW, cellH) * 0.25)

    property var pieceList: []   // [{ n: numero del pezzo, spot: posto in cui parte }]
    property var placed: []

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function load(i) {
        pieceList = []            // via i pezzi del livello prima
        levelIndex = i
        won = false
        mistakes = 0
        picture = pictures[Math.floor(i / grids.length) % pictures.length]
        cols = grids[i % grids.length][0]
        rows = grids[i % grids.length][1]
        var count = cols * rows
        var spots = []
        for (var k = 0; k < count; k++) spots.push(k)
        for (var m = count - 1; m > 0; m--) {
            var j = Math.floor(Math.random() * (m + 1))
            var t = spots[m]; spots[m] = spots[j]; spots[j] = t
        }
        var no = [], list = []
        for (var n = 0; n < count; n++) { no.push(false); list.push({ n: n, spot: spots[n] }) }
        placed = no
        pieceList = list
    }

    // Il pezzo n lasciato col centro in (x, y), misurati sul disegno a grandezza
    // piena. true se e' al suo posto.
    function drop(n, x, y) {
        if (won || placed[n]) return false
        var cx = (n % cols + 0.5) * cellW
        var cy = (Math.floor(n / cols) + 0.5) * cellH
        if (Math.hypot(x - cx, y - cy) < Math.min(cellW, cellH) * 0.38) {
            var p = placed.slice()
            p[n] = true
            placed = p
            snd.ok()
            if (p.indexOf(false) < 0) { snd.win(); win() }
            return true
        }
        // sbagliato solo se lasciato in pieno su un'altra casella ancora vuota
        if (x > 0 && y > 0 && x < imageW && y < imageH) {
            var other = Math.floor(y / cellH) * cols + Math.floor(x / cellW)
            if (other !== n && !placed[other]) { snd.nope(); wrong() }
        }
        return false
    }

    // ---------- contenuto ----------
    Item {
        id: area
        anchors.fill: parent

        // schermi larghi: pezzi a destra e a sinistra; stretti: sotto
        readonly property bool wide: width > height * 1.05
        // in basso restano liberi il punteggio e il pulsante "avanti"
        readonly property real usableH: height - 84

        // quanto e' grande il disegno a schermo
        readonly property real s: wide
            ? Math.max(0.1, Math.min((height - 16) / g.imageH, width * 0.46 / g.imageW))
            : Math.max(0.1, Math.min((width - 24) / g.imageW, usableH * 0.56 / g.imageH))

        // ===== la cornice col disegno da completare =====
        Rectangle {
            id: board
            width: g.imageW * area.s
            height: g.imageH * area.s
            x: (area.width - width) / 2
            y: area.wide ? (area.height - height) / 2 : 4
            color: "white"

            Rectangle {   // cornice di legno
                anchors { fill: parent; margins: -8 }
                z: -1
                radius: 14
                color: "#FFB74D"
                Candy {}
            }

            Image {   // il disegno in trasparenza fa da guida
                anchors.fill: parent
                source: g.folder + "full.png"
                sourceSize: Qt.size(g.imageW, g.imageH)
                opacity: g.won ? 1 : 0.28
                Behavior on opacity { NumberAnimation { duration: 500 } }
            }

            Repeater {   // le caselle
                model: g.cols * g.rows
                Rectangle {
                    required property int index
                    visible: !g.won && !g.placed[index]
                    x: (index % g.cols) * width
                    y: Math.floor(index / g.cols) * height
                    width: board.width / g.cols
                    height: board.height / g.rows
                    color: "transparent"
                    border.color: "#80795548"
                    border.width: 2
                }
            }
        }

        // ===== i pezzi =====
        Repeater {
            model: g.pieceList

            Item {
                id: piece
                required property var modelData
                readonly property int n: modelData.n
                readonly property int spot: modelData.spot
                readonly property bool done: g.placed[n] === true
                readonly property bool held: grip.drag.active
                property bool glide: false   // si scivola solo dopo il primo posizionamento

                // dimensioni piene del pezzo (linguette comprese)
                readonly property real fullW: (g.cellW + 2 * g.pad) * area.s
                readonly property real fullH: (g.cellH + 2 * g.pad) * area.s

                // ----- posto di partenza -----
                readonly property int count: g.cols * g.rows
                readonly property int perSide: Math.ceil(count / 2)
                readonly property real sideW: Math.max(1, board.x - 20)
                readonly property int trayCols: area.wide
                    ? Math.max(1, Math.min(perSide, Math.round(Math.sqrt(perSide * sideW / area.usableH * 1.1))))
                    : Math.ceil(count / (count > 6 ? 3 : 2))
                readonly property int trayRows: Math.ceil((area.wide ? perSide : count) / trayCols)
                readonly property bool onRight: area.wide && spot >= perSide
                readonly property int local: onRight ? spot - perSide : spot
                readonly property real trayTop: area.wide ? 0 : board.y + board.height + 16
                readonly property real slotW: (area.wide ? sideW : area.width) / trayCols
                readonly property real slotH: Math.max(1, area.usableH - trayTop) / trayRows
                // nel vassoio il pezzo si rimpicciolisce quanto serve
                readonly property real small: Math.min(1, slotW / (fullW * 0.86), slotH / (fullH * 0.86))

                readonly property real homeX: (onRight ? board.x + board.width + 20 : 0)
                                              + (local % trayCols + 0.5) * slotW - width / 2
                readonly property real homeY: trayTop + (Math.floor(local / trayCols) + 0.5) * slotH - height / 2
                readonly property real boardX: board.x + (n % g.cols + 0.5) * g.cellW * area.s - width / 2
                readonly property real boardY: board.y + (Math.floor(n / g.cols) + 0.5) * g.cellH * area.s - height / 2

                width: fullW
                height: fullH
                z: held ? 100 : (done ? 1 : 10)
                scale: done || held ? 1 : small
                Behavior on scale { NumberAnimation { duration: 160 } }

                // Il pezzo va dove dice lo stato (vassoio o cornice); mentre lo
                // si trascina comanda il dito.
                Binding on x { when: !piece.held; value: piece.done ? piece.boardX : piece.homeX; restoreMode: Binding.RestoreNone }
                Binding on y { when: !piece.held; value: piece.done ? piece.boardY : piece.homeY; restoreMode: Binding.RestoreNone }
                Behavior on x { enabled: piece.glide && !piece.held; NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                Behavior on y { enabled: piece.glide && !piece.held; NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                Timer { interval: 60; running: true; onTriggered: piece.glide = true }

                Image {
                    anchors.fill: parent
                    source: g.folder + g.cols + "x" + g.rows + "-" + piece.n + ".png"
                    sourceSize: Qt.size(g.cellW + 2 * g.pad, g.cellH + 2 * g.pad)
                }

                Item {   // si prende solo il corpo del pezzo, non il margine vuoto
                    anchors { fill: parent; margins: g.pad * area.s * 0.5 }

                    MouseArea {
                        id: grip
                        anchors.fill: parent
                        enabled: !g.won && !piece.done
                        drag.target: piece
                        drag.threshold: 2
                        drag.minimumX: -piece.width * 0.25
                        drag.maximumX: area.width - piece.width * 0.75
                        drag.minimumY: -piece.height * 0.25
                        drag.maximumY: area.height - piece.height * 0.75
                        onPressed: snd.tap()
                        // a drop() serve il centro del pezzo, misurato sul disegno
                        onReleased: g.drop(piece.n,
                                           (piece.x + piece.width / 2 - board.x) / area.s,
                                           (piece.y + piece.height / 2 - board.y) / area.s)
                    }
                }
            }
        }
    }
}
