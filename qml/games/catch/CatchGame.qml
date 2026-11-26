// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// "Acchiappa i conigli" - tocca solo i conigli (gli altri animali no).
// Concetto: condizione "se è un coniglio -> prendilo".
MiniGame {
    id: g
    title: qsTr("Acchiappa i conigli")
    age: qsTr("3-5 anni")
    levelCount: 4

    readonly property int need: 6
    readonly property int total: 5        // animali in campo
    readonly property int minRabbits: 2   // conigli sempre presenti
    readonly property int spots: 12       // posti in cui puo' comparire un animale
    readonly property var distract: ["mouse", "hamster", "bird", "pig", "cow", "chicken"]

    property int done: 0
    property var slots: []                // { icon, rabbit, spot, fx, fy }

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        done = 0
        var a = []
        for (var k = 0; k < total; k++)
            a.push(makeSlot(a, k < minRabbits || Math.random() < 0.5))
        slots = a
    }

    // un animale nuovo in un posto libero: due animali non si coprono mai
    function makeSlot(others, rabbit, avoid) {
        var free = []
        for (var s = 0; s < spots; s++)
            if (s !== avoid && !others.some((o) => o.spot === s)) free.push(s)
        return {
            icon: rabbit ? "rabbit" : distract[Math.floor(Math.random() * distract.length)],
            rabbit: rabbit,
            spot: free[Math.floor(Math.random() * free.length)],
            fx: Math.random(),
            fy: Math.random()
        }
    }

    // sostituisce l'animale i; se i conigli rimasti sono pochi ne arriva uno
    function respawn(i) {
        var a = slots.slice()
        var others = a.filter((o, k) => k !== i)
        var rabbits = others.filter((o) => o.rabbit).length
        a[i] = makeSlot(others, rabbits < minRabbits || Math.random() < 0.6, a[i].spot)
        slots = a
    }

    function tapSlot(i) {
        if (won) return
        if (slots[i].rabbit) {
            snd.ok()
            done += 1
            if (done >= need) { snd.win(); win() }
            else {
                respawn(i)
                // cambia anche uno degli altri animali: il campo resta vivo
                var others = []
                for (var k = 0; k < slots.length; k++)
                    if (k !== i && !slots[k].rabbit) others.push(k)
                if (others.length > 0 && Math.random() < 0.5)
                    respawn(others[Math.floor(Math.random() * others.length)])
            }
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
            AppIcon { name: "rabbit"; size: 64; anchors.verticalCenter: parent.verticalCenter }
            Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: g.need
                    ProgressStar {
                        filled: index < g.done
                    }
                }
            }
        }

        AppIcon {   // cesto
            id: basket
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
            name: "basket"
            size: 92
        }

        // campo di gioco: sta fra HUD e cesto, i conigli non escono da qui
        Item {
            id: field
            anchors {
                top: hud.bottom; topMargin: 14
                left: parent.left; right: parent.right
                bottom: basket.top; bottomMargin: 8
            }

            // il campo e' una griglia: ogni animale sta nel suo riquadro
            readonly property int cols: width >= height ? (height < 390 ? 6 : 4) : 3
            readonly property int rows: g.spots / cols
            readonly property real cellW: width / cols
            readonly property real cellH: height / rows

            Repeater {
                model: g.total

                Item {
                    id: cell
                    required property int index
                    readonly property var info: g.slots[index] || null
                    readonly property int spot: info ? info.spot : -1

                    visible: info !== null
                    // un po' di margine, cosi' anche ondeggiando non si toccano
                    width: Math.max(40, Math.min(128, field.cellW / 1.1, field.cellH / 1.1))
                    height: width
                    x: info ? (spot % field.cols) * field.cellW
                              + info.fx * Math.max(0, field.cellW - width) : 0
                    y: info ? Math.floor(spot / field.cols) * field.cellH
                              + info.fy * Math.max(0, field.cellH - height) : 0
                    onSpotChanged: appear.restart()

                    AppIcon {
                        id: face
                        anchors.centerIn: parent
                        name: cell.info ? cell.info.icon : ""
                        size: cell.width * 0.86
                    }
                    NumberAnimation {   // spunta con un saltino
                        id: appear
                        target: face; property: "scale"
                        from: 0; to: 1; duration: 260
                        easing.type: Easing.OutBack
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
                        enabled: !g.won
                        onClicked: {
                            if (!cell.info.rabbit) nono.restart()
                            g.tapSlot(cell.index)
                        }
                    }
                }
            }
        }
    }
}
