// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Shapes
import Giochi

// "Disegna il percorso" - col dito si disegna una strada dal personaggio
// fino all'oggetto (fiore, pupazzo...). Poi il personaggio la percorre:
// se arriva sull'oggetto ha vinto.
MiniGame {
    id: g
    title: qsTr("Disegna il percorso")
    age: qsTr("3-5 anni")
    levelCount: 8

    // ogni livello: partenza, arrivo (in frazioni 0..1 dell'area) e oggetto
    readonly property var levels: [
        { sx: 0.15, sy: 0.5,  tx: 0.85, ty: 0.5,  goal: "🌷" },
        { sx: 0.15, sy: 0.8,  tx: 0.85, ty: 0.2,  goal: "🧸" },
        { sx: 0.5,  sy: 0.85, tx: 0.5,  ty: 0.15, goal: "🍎" },
        { sx: 0.12, sy: 0.2,  tx: 0.88, ty: 0.8,  goal: "⚽" },
        { sx: 0.85, sy: 0.5,  tx: 0.15, ty: 0.5,  goal: "🐶" },
        { sx: 0.2,  sy: 0.75, tx: 0.8,  ty: 0.75, goal: "🌼" },
        { sx: 0.15, sy: 0.15, tx: 0.85, ty: 0.15, goal: "🎈" },
        { sx: 0.5,  sy: 0.2,  tx: 0.2,  ty: 0.85, goal: "🐱" }
    ]

    property var  pts: []           // punti del tracciato disegnato
    property bool walking: false
    property int  walkIdx: 0
    property real heroX: 0
    property real heroY: 0

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        walking = false
        walkTimer.stop()
        pts = []
        heroX = area.width  * levels[i].sx
        heroY = area.height * levels[i].sy
    }

    function goalX() { return area.width  * levels[levelIndex].tx }
    function goalY() { return area.height * levels[levelIndex].ty }

    function homeHero() {
        heroX = area.width  * levels[levelIndex].sx
        heroY = area.height * levels[levelIndex].sy
    }

    function startWalk() {
        if (walking || won || pts.length < 2) return
        // il tracciato deve partire vicino al personaggio
        if (Math.hypot(pts[0].x - heroX, pts[0].y - heroY) > 100) {
            snd.nope(); wrong(); pts = []
            return
        }
        walking = true
        walkIdx = 0
        walkTimer.start()
    }

    Timer {
        id: walkTimer
        interval: 24
        repeat: true
        onTriggered: {
            if (!g.walking) { stop(); return }
            var p = g.pts[Math.min(g.walkIdx, g.pts.length - 1)]
            g.heroX = p.x
            g.heroY = p.y
            g.walkIdx += 2
            if (g.walkIdx >= g.pts.length) {
                stop()
                g.finishWalk()
            }
        }
    }

    function finishWalk() {
        walking = false
        var last = pts[pts.length - 1]
        if (Math.hypot(last.x - goalX(), last.y - goalY()) < 90) {
            snd.win(); win()
        } else {
            snd.nope(); wrong(); pts = []
            homeHero()
        }
    }

    // ---------- contenuto ----------
    Item {
        id: area
        anchors.fill: parent

        onWidthChanged:  if (!g.walking && !g.won) g.homeHero()
        onHeightChanged: if (!g.walking && !g.won) g.homeHero()

        // griglia leggera di sfondo, solo per orientarsi meglio
        readonly property real gridCell: 80
        Row {
            Repeater {
                model: Math.ceil(area.width / area.gridCell) + 1
                Rectangle {
                    width: area.gridCell; height: area.height
                    color: "transparent"
                    border.color: Theme.boardLine
                    border.width: 1
                    opacity: 0.5
                }
            }
        }
        Column {
            Repeater {
                model: Math.ceil(area.height / area.gridCell) + 1
                Rectangle {
                    width: area.width; height: area.gridCell
                    color: "transparent"
                    border.color: Theme.boardLine
                    border.width: 1
                    opacity: 0.5
                }
            }
        }

        // il tracciato disegnato
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeColor: Theme.dirRight
                strokeWidth: 12
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: g.pts }
            }
        }

        // oggetto da raggiungere
        Text {
            text: g.levels[g.levelIndex].goal
            font.pixelSize: 92
            x: g.goalX() - width / 2
            y: g.goalY() - height / 2
        }

        // personaggio
        Text {
            id: hero
            text: "🐢"
            font.pixelSize: 76
            x: g.heroX - width / 2
            y: g.heroY - height / 2
        }

        MouseArea {
            anchors.fill: parent
            enabled: !g.walking && !g.won
            onPressed: (m) => { g.pts = [Qt.point(m.x, m.y)] }
            onPositionChanged: (m) => {
                var a = g.pts.slice()
                a.push(Qt.point(m.x, m.y))
                g.pts = a
            }
            onReleased: g.startWalk()
        }

        // pulsante "cancella" quando c'è un tracciato e non sta camminando
        Rectangle {
            visible: g.pts.length > 1 && !g.walking && !g.won
            anchors { right: parent.right; top: parent.top }
            width: 76; height: 76; radius: 38
            color: Theme.danger
            Text { anchors.centerIn: parent; text: "🗑"; font.pixelSize: 34 }
            MouseArea { anchors.fill: parent; onClicked: { snd.tap(); g.pts = [] } }
        }
    }
}
