// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Shapes
import Orme

// "Unisci i puntini" - si toccano i puntini in ordine da 1 a 5. A ogni
// tocco giusto si disegna un pezzo di linea.
MiniGame {
    id: g
    title: qsTr("Unisci i puntini")
    age: qsTr("4-5 anni")
    levelCount: 6

    // posizioni dei 5 puntini per livello (frazioni 0..1 dell'area)
    readonly property var layouts: [
        [{x:0.15,y:0.5},{x:0.35,y:0.2},{x:0.55,y:0.6},{x:0.72,y:0.25},{x:0.88,y:0.6}],
        [{x:0.2,y:0.22},{x:0.8,y:0.22},{x:0.8,y:0.8},{x:0.2,y:0.8},{x:0.5,y:0.5}],
        [{x:0.5,y:0.18},{x:0.85,y:0.5},{x:0.68,y:0.85},{x:0.32,y:0.85},{x:0.15,y:0.5}],
        [{x:0.15,y:0.8},{x:0.32,y:0.28},{x:0.5,y:0.72},{x:0.68,y:0.28},{x:0.85,y:0.8}],
        [{x:0.18,y:0.5},{x:0.4,y:0.24},{x:0.6,y:0.24},{x:0.82,y:0.5},{x:0.5,y:0.82}],
        [{x:0.5,y:0.2},{x:0.24,y:0.44},{x:0.35,y:0.82},{x:0.66,y:0.82},{x:0.76,y:0.44}]
    ]

    property int  next: 0           // prossimo numero da toccare (0 -> "1")
    property var  line: []          // punti gia' uniti (in pixel)

    SoundBank { id: snd }

    // Trasformano la frazione 0..1 in pixel dentro una zona "sicura": mai
    // sotto l'icona in alto, mai dietro la targhetta del punteggio o il
    // pulsante "avanti" in basso (altrimenti un puntino puo' restare coperto).
    function cxFor(fx) { return 60 + fx * Math.max(1, area.width - 120) }
    function cyFor(fy) { return 70 + fy * Math.max(1, area.height - 230) }

    // percorso completo (1-2-3-4-5) in pixel, usato come guida tratteggiata
    readonly property var guidePoints: {
        var lv = layouts[levelIndex]
        var pts = []
        for (var i = 0; i < lv.length; i++)
            pts.push(Qt.point(cxFor(lv[i].x), cyFor(lv[i].y)))
        return pts
    }

    onBuildLevel: (i) => load(i)

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        next = 0
        line = []
    }

    function tapDot(k, px, py) {
        if (won) return
        if (k === next) {
            snd.ok()
            line = line.concat([Qt.point(px, py)])
            next += 1
            if (next >= 5) { snd.win(); win() }
        } else {
            snd.nope(); wrong()
        }
    }

    // ---------- contenuto ----------
    Item {
        id: area
        anchors.fill: parent

        // guida tratteggiata leggera: mostra tutto il percorso da un
        // numero all'altro, cosi' i bambini capiscono dove andare
        Shape {
            anchors.fill: parent
            opacity: 0.4
            ShapePath {
                strokeColor: Theme.boardLine
                strokeWidth: 6
                strokeStyle: ShapePath.DashLine
                dashPattern: [3, 3]
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: g.guidePoints }
            }
        }

        Shape {
            anchors.fill: parent
            ShapePath {
                strokeColor: Theme.dirRight
                strokeWidth: 12
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: g.line }
            }
        }

        Repeater {
            model: 5
            Rectangle {
                id: dot
                required property int index
                readonly property var d: g.layouts[g.levelIndex][index]
                readonly property real cx: g.cxFor(d.x)
                readonly property real cy: g.cyFor(d.y)

                width: 100; height: 100; radius: 50
                x: cx - width / 2
                y: cy - height / 2

                color: index < g.next ? Theme.accent
                     : index === g.next ? Theme.dirUp
                     : Theme.dirDown
                border.color: index === g.next ? "#FFEB3B" : "white"
                border.width: index === g.next ? 8 : 4

                scale: index === g.next ? 1.14 : 1
                Behavior on scale { NumberAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: dot.index + 1
                    font.pixelSize: 48
                    font.bold: true
                    color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    enabled: !g.won
                    onClicked: g.tapDot(dot.index, dot.cx, dot.cy)
                }
            }
        }
    }
}
