// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Shapes
import Orme

// "Il trenino" - prima si costruisce il treno, poi lo si fa partire.
// Sul binario ci sono le caselle vuote; i vagoni (e la locomotiva) stanno nel
// vassoio in basso e si trascinano al loro posto: la locomotiva davanti (a
// destra, il treno va verso destra), i vagoni dietro. Dai livelli 3 in poi
// in alto c'e' il modellino da copiare, colore per colore. Quando tutte le
// caselle sono piene compare il pulsante START: si tocca e il treno parte,
// fa fumo e viaggia verso la prossima stazione: lo scenario scorre, il
// bambino tocca il treno per farlo correre piu' forte (ciuf! e fischio) e
// il treno frena da solo arrivando in stazione, dove aspettano i passeggeri.
MiniGame {
    id: g
    title: qsTr("Il trenino")
    age: qsTr("3-4 anni")
    levelCount: 6

    readonly property var counts: [3, 3, 4, 4, 5, 5]   // locomotiva compresa

    property int  carCount: 3
    property bool matchModel: false     // true: i vagoni devono avere i colori del modellino
    property var  order: []             // colore atteso per casella (la locomotiva e' l'ultima)
    property var  filled: []            // bool per casella
    property var  placedColor: []       // colore messo in ogni casella
    property var  trayCars: []          // { uid, loco, color } ancora nel vassoio
    property string phase: "build"      // build | ready | running | arrived
    property real  scroll: 0            // strada percorsa (px di scenario scorso)
    property real  boost: 0             // spinta extra data dai tocchi, decade da sola
    readonly property real goal: 2200 + (levelIndex % 6) * 300
    property real  wheelAngle: 0

    readonly property real gap: 16
    readonly property real cw: Math.max(60, Math.min(150, (area.width - 60 - (carCount - 1) * gap) / carCount))
    readonly property real ch: cw * 0.7
    readonly property real trainW: carCount * cw + (carCount - 1) * gap
    readonly property real trainX: (area.width - trainW) / 2
    readonly property real trackY: area.height * 0.36 - ch / 2

    readonly property color locoColor: Theme.playColors[0]

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function shuffle(a) {
        var r = a.slice()
        for (var i = r.length - 1; i > 0; i--) {
            var j = Math.floor(Math.random() * (i + 1))
            var t = r[i]; r[i] = r[j]; r[j] = t
        }
        return r
    }

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        phase = "build"
        scroll = 0
        boost = 0
        carCount = counts[i % counts.length]
        matchModel = i >= 2

        var wagons = shuffle(Theme.playColors.slice(1)).slice(0, carCount - 1)
        order = wagons.concat([locoColor])
        var f = [], pc = []
        for (var k = 0; k < carCount; k++) { f.push(false); pc.push(locoColor) }
        filled = f
        placedColor = pc

        var tray = [{ uid: 0, loco: true, color: locoColor }]
        for (var w = 0; w < wagons.length; w++)
            tray.push({ uid: w + 1, loco: false, color: wagons[w] })
        trayCars = shuffle(tray)
    }

    // slot < 0: pezzo rilasciato fuori dalle caselle. true = agganciato.
    function drop(car, slot) {
        if (slot < 0 || phase !== "build" || filled[slot]) return false
        var isLocoSlot = slot === carCount - 1
        var ok = car.loco === isLocoSlot
        if (ok && !car.loco && matchModel) ok = order[slot] === car.color
        if (!ok) {
            g.wrong()
            snd.nope()
            return false
        }
        var f = filled.slice(); f[slot] = true; filled = f
        var pc = placedColor.slice(); pc[slot] = car.color; placedColor = pc
        trayCars = trayCars.filter(function (c) { return c.uid !== car.uid })
        snd.ok()
        if (trayCars.length === 0) phase = "ready"
        return true
    }

    function start() {
        if (phase !== "ready") return
        phase = "running"
        snd.win()
    }

    // un passo di viaggio: velocita' di crociera + spinta dei tocchi, e frenata
    // dolce negli ultimi 500 px prima della stazione
    function advance(dt) {
        var remaining = goal - scroll
        var v = 150 + boost
        boost *= 0.95
        if (remaining < 500) v = Math.min(v, Math.max(40, remaining * 0.7))
        scroll += v * dt
        wheelAngle += v * dt * 2.6
        if (goal - scroll <= 1.5) {
            scroll = goal
            phase = "arrived"
            snd.win()
            station.poke()
            winTimer.start()
        }
    }

    function push() {
        if (phase !== "running") return
        boost = Math.min(450, boost + 220)
        snd.tap()
        chuff.restart()
    }

    // ---------- il vagone (disegnato con rettangoli) ----------
    // Tutte le misure sono frazioni di width/height: lo stesso componente serve
    // per il treno, il vassoio e il modellino in miniatura.
    component Car: Item {
        id: car
        property bool loco: false
        property color body: "red"
        property real spin: 0
        property bool smoking: false
        height: width * 0.7

        readonly property color dark: Qt.darker(body, 1.45)
        readonly property color gold: "#FFCA28"

        // collegamento al vagone dietro
        Rectangle { visible: !car.loco; x: car.width - 3; y: car.height * 0.38; width: 22; height: car.height * 0.07; radius: 2; color: "#37474F" }
        Rectangle { visible: !car.loco; x: car.width + 4; y: car.height * 0.355; width: car.height * 0.12; height: car.height * 0.12; radius: car.height * 0.06; color: "#78909C" }

        // ruote: 4 per vagone (due carrelli da 2), 6 per la locomotiva, su
        // entrambe le rotaie: la fila davanti poggia sulla rotaia vicina, quella
        // dietro (piu' scura e un po' piu' in alto, nascosta dal corpo) sull'altra
        Repeater {
            model: (car.loco ? 6 : 4) * 2
            Rectangle {
                required property int index
                readonly property int perSide: car.loco ? 6 : 4
                readonly property bool back: index >= perSide
                readonly property int pos: index % perSide
                readonly property real d: car.height * 0.2
                width: d; height: d; radius: d / 2
                x: car.loco ? car.width * (0.06 + pos * 0.15)
                            : car.width * [0.08, 0.24, 0.62, 0.78][pos]
                y: car.height - d - (back ? car.height * 0.2 : 0)
                z: back ? -1 : 0
                color: back ? "#546E7A" : "#37474F"
                border.color: back ? "#78909C" : "#B0BEC5"
                border.width: 2
                Rectangle {   // raggi: si vedono girare
                    anchors.centerIn: parent
                    width: parent.width * 0.78; height: 3; radius: 1.5
                    color: "#CFD8DC"
                    rotation: car.spin
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.78; height: 3; radius: 1.5
                    color: "#CFD8DC"
                    rotation: car.spin + 90
                }
                Rectangle {   // mozzo dorato
                    anchors.centerIn: parent
                    width: parent.width * 0.3; height: width; radius: width / 2
                    color: car.gold
                }
            }
        }

        // ----- vagone -----
        Item {
            visible: !car.loco
            anchors.fill: parent

            Rectangle {   // telaio sotto la cassa
                x: 2; y: car.height * 0.54
                width: car.width - 7; height: car.height * 0.07
                radius: 3; color: "#455A64"
            }
            Repeater {   // respingenti
                model: 2
                Rectangle {
                    required property int index
                    x: index === 0 ? -4 : car.width - 5
                    y: car.height * 0.34
                    width: 6; height: car.height * 0.13; radius: 2
                    color: "#B0BEC5"
                }
            }
            Rectangle {   // cassa
                id: wagonBody
                x: 0; y: car.height * 0.02
                width: car.width - 3; height: car.height * 0.54
                radius: car.height * 0.09
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.lighter(car.body, 1.25) }
                    GradientStop { position: 1.0; color: car.body }
                }
                border.color: car.dark
                border.width: 3

                Rectangle {   // tetto
                    x: 3; y: 3
                    width: parent.width - 6; height: parent.height * 0.14
                    radius: height / 2
                    color: Qt.darker(car.body, 1.25)
                }
                Rectangle {   // fascia dorata
                    x: 3; y: parent.height * 0.76
                    width: parent.width - 6; height: parent.height * 0.08
                    color: car.gold
                }
                Row {   // finestrini con tendina
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * 0.26
                    spacing: car.width * 0.06
                    Repeater {
                        model: 3
                        Rectangle {
                            width: car.width * 0.2; height: car.height * 0.2
                            radius: 4; color: "#E1F5FE"
                            border.color: car.dark; border.width: 2
                            Rectangle {   // tendina
                                x: 2; y: 2; width: parent.width - 4; height: parent.height * 0.32
                                radius: 2; color: "#FFF59D"
                            }
                            Rectangle {   // riflesso
                                x: parent.width * 0.62; y: parent.height * 0.4
                                width: 3; height: parent.height * 0.4
                                radius: 1.5; color: "white"; opacity: 0.8
                            }
                        }
                    }
                }
            }
        }

        // ----- locomotiva: cabina a sinistra, caldaia a destra, ciminiera -----
        Item {
            visible: car.loco
            anchors.fill: parent

            Rectangle {   // telaio
                x: 2; y: car.height * 0.56
                width: car.width - 5; height: car.height * 0.08
                radius: 3; color: "#37474F"
            }
            Shape {   // cacciapietre davanti
                x: car.width - 4; y: car.height * 0.38
                width: car.width * 0.1; height: car.height * 0.28
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: "#546E7A"; strokeColor: "#263238"; strokeWidth: 2
                    startX: 0; startY: 0
                    PathLine { x: car.width * 0.09; y: car.height * 0.26 }
                    PathLine { x: 0; y: car.height * 0.26 }
                    PathLine { x: 0; y: 0 }
                }
            }

            Rectangle {   // caldaia
                x: car.width * 0.36; y: car.height * 0.16
                width: car.width * 0.64 - 3; height: car.height * 0.42
                radius: car.height * 0.12
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.lighter(car.body, 1.3) }
                    GradientStop { position: 1.0; color: car.body }
                }
                border.color: car.dark; border.width: 3

                Repeater {   // fasce dorate
                    model: 2
                    Rectangle {
                        required property int index
                        x: parent.width * (0.3 + index * 0.32); y: 0
                        width: parent.width * 0.07; height: parent.height
                        color: car.gold; opacity: 0.95
                    }
                }
                // il visetto sorridente
                Row {
                    x: parent.width * 0.58; y: parent.height * 0.22
                    spacing: parent.width * 0.06
                    Repeater {
                        model: 2
                        Rectangle {
                            width: car.height * 0.13; height: width; radius: width / 2
                            color: "white"; border.color: car.dark; border.width: 1
                            Rectangle { x: parent.width * 0.38; y: parent.height * 0.3; width: parent.width * 0.4; height: width; radius: width / 2; color: "#263238" }
                        }
                    }
                }
                Rectangle {   // bocca
                    x: parent.width * 0.62; y: parent.height * 0.64
                    width: parent.width * 0.22; height: car.height * 0.06
                    radius: height / 2; color: "#5D1A1A"
                }
            }

            Rectangle {   // duomo del vapore
                x: car.width * 0.5; y: car.height * 0.08
                width: car.width * 0.11; height: car.height * 0.1
                radius: car.height * 0.04; color: car.gold
                border.color: "#F9A825"; border.width: 2
            }

            Rectangle {   // cabina
                x: 0; y: car.height * 0.02
                width: car.width * 0.4; height: car.height * 0.56
                radius: car.height * 0.07
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.lighter(car.body, 1.1) }
                    GradientStop { position: 1.0; color: Qt.darker(car.body, 1.15) }
                }
                border.color: car.dark; border.width: 3
                Rectangle {   // finestra
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * 0.24
                    width: parent.width * 0.56; height: parent.height * 0.32
                    radius: 5; color: "#E1F5FE"
                    border.color: car.dark; border.width: 2
                    Rectangle { x: parent.width * 0.6; y: parent.height * 0.25; width: 3; height: parent.height * 0.5; radius: 1.5; color: "white"; opacity: 0.8 }
                }
                Rectangle {   // targhetta col numero
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * 0.72
                    width: parent.width * 0.4; height: parent.height * 0.14
                    radius: 3; color: car.gold
                }
            }
            Rectangle {   // tetto della cabina, sporgente
                x: -car.width * 0.02; y: -car.height * 0.04
                width: car.width * 0.44; height: car.height * 0.08
                radius: height / 2; color: car.dark
            }

            Rectangle {   // ciminiera con bordo svasato
                x: car.width * 0.75; y: -car.height * 0.02
                width: car.width * 0.12; height: car.height * 0.2
                color: "#37474F"
            }
            Rectangle {
                x: car.width * 0.725; y: -car.height * 0.08
                width: car.width * 0.17; height: car.height * 0.07
                radius: 3; color: "#263238"
            }

            Rectangle {   // alone del fanale
                x: car.width - 3 - car.height * 0.12; y: car.height * 0.265
                width: car.height * 0.2; height: width; radius: width / 2
                color: "#FFF59D"; opacity: 0.55
            }
            Rectangle {   // fanale
                x: car.width - 3 - car.height * 0.09; y: car.height * 0.295
                width: car.height * 0.14; height: width; radius: width / 2
                color: "#FFEB3B"
                border.color: "#F9A825"; border.width: 2
            }

            // biella laterale fra le ruote davanti: va avanti e indietro mentre girano
            Rectangle {
                x: car.width * 0.06 + car.height * 0.1
                y: car.height - car.height * 0.1 - 2 + Math.sin(car.spin * Math.PI / 180) * car.height * 0.04
                width: car.width * 0.15 * 5; height: 4; radius: 2
                color: car.gold
                z: 1
            }
        }

        // fumo dalla ciminiera
        Repeater {
            model: car.loco ? 3 : 0
            Rectangle {
                id: puff
                required property int index
                width: car.height * 0.2; height: width; radius: width / 2
                color: "white"
                x: car.width * 0.81 - width / 2
                y: -car.height * 0.1
                opacity: 0
                SequentialAnimation {
                    running: car.smoking
                    loops: Animation.Infinite
                    PauseAnimation { duration: puff.index * 330 }
                    ParallelAnimation {
                        NumberAnimation { target: puff; property: "y"; from: -car.height * 0.1; to: -car.height * 0.85; duration: 1000 }
                        NumberAnimation { target: puff; property: "x"; from: car.width * 0.81 - puff.width / 2; to: car.width * 0.81 - puff.width / 2 - car.width * 0.25; duration: 1000 }
                        NumberAnimation { target: puff; property: "scale"; from: 0.5; to: 1.8; duration: 1000 }
                        SequentialAnimation {
                            NumberAnimation { target: puff; property: "opacity"; to: 0.85; duration: 150 }
                            NumberAnimation { target: puff; property: "opacity"; to: 0; duration: 850 }
                        }
                    }
                }
            }
        }
    }

    // ---------- un passeggero in piedi, intero (testa, busto, braccia, gambe) ----------
    component Person: Item {
        id: person
        property color shirt: "#42A5F5"
        property color hair: "#5D4037"
        property bool girl: false
        property bool walking: false
        property real swing: 0
        width: 40; height: 90

        SequentialAnimation on swing {
            running: person.walking
            loops: Animation.Infinite
            onRunningChanged: if (!running) person.swing = 0
            NumberAnimation { to: 28; duration: 190; easing.type: Easing.InOutSine }
            NumberAnimation { to: -28; duration: 380; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0; duration: 190; easing.type: Easing.InOutSine }
        }

        Repeater {   // gambe
            model: 2
            Rectangle {
                required property int index
                x: 9 + index * 14; y: 60; width: 9; height: 28; radius: 4
                color: "#37474F"
                transformOrigin: Item.Top
                rotation: index === 0 ? person.swing : -person.swing
                Rectangle { x: -2; y: parent.height - 7; width: 14; height: 8; radius: 4; color: "#263238" }   // scarpa
            }
        }
        Rectangle {   // gonna per le bambine
            visible: person.girl
            x: 2; y: 48; width: 36; height: 22; radius: 8
            color: Qt.darker(person.shirt, 1.2)
        }
        Repeater {   // braccia
            model: 2
            Rectangle {
                required property int index
                x: index === 0 ? -4 : 33; y: 28; width: 8; height: 28; radius: 4
                color: person.shirt
                transformOrigin: Item.Top
                rotation: index === 0 ? -person.swing : person.swing
                Rectangle { y: parent.height - 5; width: 8; height: 8; radius: 4; color: "#FFCCBC" }   // mano
            }
        }
        Rectangle {   // busto
            x: 5; y: 25; width: 30; height: 38; radius: 10
            color: person.shirt
        }
        Rectangle {   // testa
            x: 8; y: 0; width: 24; height: 24; radius: 12
            color: "#FFCCBC"
            Rectangle {   // capelli
                x: -1; y: -2; width: parent.width + 2; height: 13; radius: 8
                color: person.hair
            }
            Rectangle { x: 6; y: 11; width: 3; height: 3; radius: 1.5; color: "#263238" }
            Rectangle { x: 15; y: 11; width: 3; height: 3; radius: 1.5; color: "#263238" }
            Rectangle { x: 8; y: 17; width: 8; height: 3; radius: 1.5; color: "#C62828" }
        }
    }

    // ---------- scenario: casetta e albero (proporzionali alla larghezza) ----------
    component House: Item {
        id: house
        property color wall: "#FFCC80"
        property color roof: "#E57373"
        property bool lit: false      // luci accese
        signal tapped()
        height: width * 0.95
        transformOrigin: Item.Bottom

        // un tocco: accende/spegne le luci, la casetta saltella, esce il fumo
        signal poked()
        function poke() { lit = !lit; poked(); hop.restart() }
        SequentialAnimation {
            id: hop
            NumberAnimation { target: house; property: "scale"; to: 1.1; duration: 110; easing.type: Easing.OutQuad }
            NumberAnimation { target: house; property: "scale"; to: 0.96; duration: 100 }
            NumberAnimation { target: house; property: "scale"; to: 1.0; duration: 100 }
        }
        MouseArea {
            anchors.fill: parent
            z: 10
            onClicked: { house.poke(); house.tapped() }
        }

        Rectangle {   // muro
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: house.height * 0.62
            color: house.wall
            border.color: Qt.darker(house.wall, 1.25); border.width: 2
        }
        Shape {   // tetto
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: house.height * 0.42
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: house.roof
                strokeColor: Qt.darker(house.roof, 1.3); strokeWidth: 2
                startX: -4; startY: house.height * 0.42
                PathLine { x: house.width / 2; y: 0 }
                PathLine { x: house.width + 4; y: house.height * 0.42 }
                PathLine { x: -4; y: house.height * 0.42 }
            }
        }
        Rectangle {   // comignolo
            x: house.width * 0.72; y: house.height * 0.06
            width: house.width * 0.12; height: house.height * 0.18
            color: Qt.darker(house.roof, 1.4)
        }
        Rectangle {   // porta
            x: house.width * 0.40; y: house.height * 0.72
            width: house.width * 0.2; height: house.height * 0.28
            radius: 3; color: house.lit ? "#FFB74D" : "#8D6E63"
        }
        Repeater {   // fumo dal comignolo quando si tocca
            model: 3
            Rectangle {
                id: hpuff
                required property int index
                width: house.width * 0.1; height: width; radius: width / 2
                color: "white"; opacity: 0
                x: house.width * 0.78 - width / 2; y: house.height * 0.04
                Connections {
                    target: house
                    function onPoked() { hp.restart() }
                }
                SequentialAnimation {
                    id: hp
                    PauseAnimation { duration: hpuff.index * 160 }
                    ParallelAnimation {
                        NumberAnimation { target: hpuff; property: "y"; from: house.height * 0.04; to: -house.height * 0.5; duration: 900 }
                        NumberAnimation { target: hpuff; property: "x"; from: house.width * 0.78 - hpuff.width / 2; to: house.width * 0.78 - hpuff.width / 2 - house.width * 0.2; duration: 900 }
                        NumberAnimation { target: hpuff; property: "scale"; from: 0.6; to: 1.8; duration: 900 }
                        SequentialAnimation {
                            NumberAnimation { target: hpuff; property: "opacity"; to: 0.85; duration: 120 }
                            NumberAnimation { target: hpuff; property: "opacity"; to: 0; duration: 780 }
                        }
                    }
                }
            }
        }
        Repeater {   // finestre
            model: 2
            Rectangle {
                required property int index
                x: house.width * (index === 0 ? 0.12 : 0.68)
                y: house.height * 0.5
                width: house.width * 0.2; height: house.width * 0.2
                color: house.lit ? "#FFF176" : "#E1F5FE"
                border.color: house.lit ? "#FFB300" : "#8D6E63"; border.width: 2
            }
        }
    }

    component Station: Item {
        id: st
        height: width * 0.62
        property bool ringing: false     // campanella: cartello e porte si illuminano
        signal tapped()
        transformOrigin: Item.Bottom

        function poke() { ringing = true; ringOff.restart(); bump.restart(); ding.restart() }
        Timer { id: ringOff; interval: 1600; onTriggered: st.ringing = false }
        SequentialAnimation {
            id: bump
            NumberAnimation { target: st; property: "scale"; to: 1.05; duration: 110; easing.type: Easing.OutQuad }
            NumberAnimation { target: st; property: "scale"; to: 0.98; duration: 100 }
            NumberAnimation { target: st; property: "scale"; to: 1.0; duration: 100 }
        }
        MouseArea {
            anchors.fill: parent
            z: 10
            onClicked: { st.poke(); st.tapped() }
        }
        Text {
            id: dingText
            x: st.width * 0.5 - width / 2; y: -st.height * 0.1
            text: "🔔 " + qsTr("DING DONG!")
            font.pixelSize: st.height * 0.2; font.bold: true
            color: "white"; style: Text.Outline; styleColor: "#1565C0"
            opacity: 0; z: 11
            ParallelAnimation {
                id: ding
                NumberAnimation { target: dingText; property: "y"; from: -st.height * 0.05; to: -st.height * 0.3; duration: 900 }
                SequentialAnimation {
                    NumberAnimation { target: dingText; property: "opacity"; to: 1; duration: 100 }
                    PauseAnimation { duration: 500 }
                    NumberAnimation { target: dingText; property: "opacity"; to: 0; duration: 300 }
                }
            }
        }

        Rectangle {   // edificio
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: st.height * 0.62
            color: "#FFE0B2"
            border.color: "#BCAAA4"; border.width: 3
        }
        Rectangle {   // tettoia lunga
            x: -8; y: st.height * 0.34
            width: st.width + 16; height: st.height * 0.1
            radius: 4; color: "#C62828"
        }
        Rectangle {   // torre dell'orologio
            x: st.width * 0.4; y: 0
            width: st.width * 0.2; height: st.height * 0.4
            color: "#FFCC80"; border.color: "#BCAAA4"; border.width: 3
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.12
                width: parent.width * 0.7; height: width; radius: width / 2
                color: "white"; border.color: "#5D4037"; border.width: 2
                Rectangle { x: parent.width / 2 - 1; y: parent.height * 0.18; width: 2; height: parent.height * 0.34; color: "#5D4037" }
                Rectangle { x: parent.width / 2 - 1; y: parent.height / 2 - 1; width: parent.width * 0.26; height: 2; color: "#5D4037" }
            }
        }
        Rectangle {   // cartello
            anchors.horizontalCenter: parent.horizontalCenter
            y: st.height * 0.47
            width: st.width * 0.56; height: st.height * 0.16
            radius: 5; color: st.ringing ? "#FFB300" : "#1565C0"
            Text {
                anchors.centerIn: parent
                text: qsTr("STAZIONE")
                color: "white"; font.bold: true
                font.pixelSize: parent.height * 0.62
            }
        }
        Repeater {   // porte ad arco
            model: 3
            Rectangle {
                required property int index
                x: st.width * (0.12 + index * 0.3); y: st.height * 0.7
                width: st.width * 0.16; height: st.height * 0.3
                radius: width / 2
                color: st.ringing ? "#FFE082" : "#8D6E63"
            }
        }
    }

    component Tree: Item {
        id: tree
        property color leaf: "#43A047"
        height: width * 1.5
        transformOrigin: Item.Bottom
        signal tapped()
        // un tocco scuote l'albero e fa cadere una foglia
        SequentialAnimation {
            id: shakeTree
            NumberAnimation { target: tree; property: "rotation"; to: -6; duration: 80 }
            NumberAnimation { target: tree; property: "rotation"; to: 6; duration: 120 }
            NumberAnimation { target: tree; property: "rotation"; to: -3; duration: 100 }
            NumberAnimation { target: tree; property: "rotation"; to: 0; duration: 80 }
        }
        Text {
            id: leafText
            text: "🍃"; font.pixelSize: tree.width * 0.3
            x: tree.width * 0.5; y: tree.width * 0.5; opacity: 0; z: 5
            ParallelAnimation {
                id: leafFall
                NumberAnimation { target: leafText; property: "y"; from: tree.width * 0.5; to: tree.height; duration: 1100 }
                NumberAnimation { target: leafText; property: "x"; from: tree.width * 0.5; to: tree.width * 0.9; duration: 1100; easing.type: Easing.InOutSine }
                NumberAnimation { target: leafText; property: "rotation"; from: 0; to: 200; duration: 1100 }
                SequentialAnimation {
                    NumberAnimation { target: leafText; property: "opacity"; to: 1; duration: 80 }
                    PauseAnimation { duration: 700 }
                    NumberAnimation { target: leafText; property: "opacity"; to: 0; duration: 320 }
                }
            }
        }
        MouseArea { anchors.fill: parent; z: 10; onClicked: { shakeTree.restart(); leafFall.restart(); tree.tapped() } }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: tree.width * 0.18; height: tree.height * 0.4
            color: "#8D6E63"
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            width: tree.width; height: tree.width; radius: tree.width / 2
            color: tree.leaf
        }
        Rectangle {
            x: tree.width * 0.1; y: tree.width * 0.45
            width: tree.width * 0.8; height: tree.width * 0.8; radius: tree.width * 0.4
            color: Qt.darker(tree.leaf, 1.1)
        }
    }

    // ---------- contenuto ----------
    Item {
        id: area
        anchors.fill: parent
        clip: true

        // ===== scenario: cielo, colline, case, alberi, prato =====
        Item {
            id: scene
            anchors.fill: parent
            z: -5

            readonly property real horizonY: g.trackY + g.ch * 0.3

            Rectangle {   // cielo
                x: 0; y: 0; width: parent.width; height: scene.horizonY + 2
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#8FD3FF" }
                    GradientStop { position: 1.0; color: "#E3F6FF" }
                }
            }
            Rectangle {   // sole
                x: parent.width - 150; y: 18
                width: 64; height: 64; radius: 32
                color: "#FFE066"; border.color: "#FFD23F"; border.width: 4
            }
            Repeater {   // nuvole che scorrono piano
                model: 3
                Item {
                    id: cloud
                    required property int index
                    y: 24 + index * 34
                    x: 0
                    width: 110; height: 44
                    NumberAnimation on x {
                        from: -140; to: area.width + 40
                        duration: 52000 + cloud.index * 17000
                        loops: Animation.Infinite
                    }
                    Rectangle { x: 0; y: 14; width: 70; height: 30; radius: 15; color: "white"; opacity: 0.9 }
                    Rectangle { x: 28; y: 0; width: 56; height: 40; radius: 20; color: "white"; opacity: 0.9 }
                    Rectangle { x: 52; y: 14; width: 58; height: 30; radius: 15; color: "white"; opacity: 0.9 }
                }
            }
            Rectangle {   // colline lontane
                x: -80; y: scene.horizonY - 44; width: parent.width * 0.55; height: 140; radius: 70
                color: "#A5D6A7"
            }
            Rectangle {
                x: parent.width * 0.4; y: scene.horizonY - 30; width: parent.width * 0.7; height: 140; radius: 70
                color: "#9CCC65"
            }

            // il prato davanti
            Rectangle {
                x: 0; y: scene.horizonY; width: parent.width; height: parent.height - scene.horizonY
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#8BC34A" }
                    GradientStop { position: 1.0; color: "#AED581" }
                }
            }

            // case e alberi lungo l'orizzonte
            Repeater {
                model: Math.ceil((area.width + 720) / 120) + 1
                Item {
                    id: slot
                    required property int index
                    readonly property var wallColors: ["#FFCC80", "#FFF59D", "#F8BBD0", "#B3E5FC", "#C5E1A5", "#FFAB91"]
                    readonly property var roofColors: ["#E57373", "#8D6E63", "#7986CB", "#EF5350", "#BA68C8", "#FF8A65"]
                    readonly property bool isTree: index % 3 === 1
                    readonly property real hh: Math.max(46, Math.min(96, g.trackY - 72))
                    x: index * 120 + 6 + (((index % 6) * 37) % 23) - (g.scroll % 720)
                    y: scene.horizonY
                    width: 110; height: 0

                    House {
                        visible: !slot.isTree
                        width: slot.hh * (0.9 + (slot.index % 3) * 0.1)
                        wall: slot.wallColors[slot.index % slot.wallColors.length]
                        roof: slot.roofColors[(slot.index * 5) % slot.roofColors.length]
                        y: -height + 4
                        onTapped: snd.tap()
                    }
                    Tree {
                        visible: slot.isTree
                        width: slot.hh * 0.62
                        x: 20
                        leaf: slot.index % 2 ? "#388E3C" : "#4CAF50"
                        y: -height + 4
                        onTapped: snd.tap()
                    }
                }
            }

            // strada pedonale: scende dalla banchina a sinistra della stazione, poi
            // corre davanti alla facciata fino alle porte; strisce pedonali all'inizio
            Rectangle {
                id: walkDown
                x: station.x - 76; width: 64
                y: g.trackY + g.ch + 46
                height: station.y + station.height + 34 - y
                color: "#B0BEC5"
                border.color: "#90A4AE"; border.width: 2
                Repeater {
                    model: 5
                    Rectangle {
                        required property int index
                        x: 8; y: 10 + index * 13; width: parent.width - 16; height: 7
                        color: "white"
                    }
                }
            }
            Rectangle {
                id: walkAcross
                x: station.x - 76; width: station.width + 76 + 30
                y: station.y + station.height
                height: 34
                color: "#B0BEC5"
                border.color: "#90A4AE"; border.width: 2
                Repeater {   // tratteggio centrale
                    model: Math.floor((parent.width - 30) / 40)
                    Rectangle { required property int index; x: 8 + index * 40; y: 16; width: 22; height: 3; color: "white" }
                }
            }
            // lampione davanti alla strada
            Rectangle { x: station.x - 90; y: station.y + station.height - 70; width: 6; height: 76; color: "#455A64" }
            Rectangle { x: station.x - 100; y: station.y + station.height - 86; width: 26; height: 26; radius: 13; color: g.phase === "arrived" ? "#FFF176" : "#FFF9C4"; border.color: "#F9A825"; border.width: 2 }

            // banchina lungo i binari, davanti alla stazione
            Rectangle {
                x: station.x - 420; width: station.width + 840
                y: g.trackY + g.ch + 24; height: 22
                color: "#CFD8DC"
                Rectangle { width: parent.width; height: 4; color: "#FFEB3B" }
            }

            // la stazione: arriva da destra e si ferma davanti ai vagoni, sotto i binari
            Station {
                id: station
                width: Math.min(260, g.trainW * 0.5)
                x: Math.max(10, g.trainX + g.trainW - width - 24) + (g.goal - g.scroll)
                y: Math.min(g.trackY + g.ch + 100, area.height - height - 44)
                onTapped: snd.ok()
            }
        }

        // ===== modellino da copiare (dai livelli 3 in poi) =====
        Rectangle {
            visible: g.matchModel
            x: 8; y: 8
            width: modelRow.width + 20; height: modelRow.height + 14
            radius: 14
            color: "#CCFFFFFF"
        }
        Row {
            id: modelRow
            visible: g.matchModel
            x: 18; y: 15
            spacing: 4
            Repeater {
                model: g.carCount
                Car {
                    required property int index
                    width: 54
                    loco: index === g.carCount - 1
                    body: g.order[index] || "#bbbbbb"
                }
            }
        }

        // ===== binario: massicciata, traversine e due rotaie =====
        Rectangle {   // massicciata
            x: 0; width: parent.width
            y: g.trackY + g.ch - 32
            height: 48
            color: "#BCAAA4"
            border.color: "#A1887F"; border.width: 2
        }
        Repeater {   // traversine
            model: Math.ceil(area.width / 26) + 2
            Rectangle {
                required property int index
                x: index * 26 + 4 - (g.scroll % 26); y: g.trackY + g.ch - 29
                width: 12; height: 42; radius: 2
                color: "#8D6E63"
            }
        }
        Rectangle {   // rotaia dietro (le ruote poggiano su quella davanti)
            x: 0; width: parent.width
            y: g.trackY + g.ch - 23
            height: 7; color: "#90A4AE"
        }
        Rectangle {
            x: 0; width: parent.width
            y: g.trackY + g.ch - 2
            height: 7; color: "#78909C"
            Rectangle { x: 0; y: 0; width: parent.width; height: 2; color: "#CFD8DC" }   // riflesso
        }

        // ===== caselle vuote =====
        Repeater {
            id: slotRep
            model: g.carCount
            Rectangle {
                required property int index
                x: g.trainX + index * (g.cw + g.gap)
                y: g.trackY
                width: g.cw; height: g.ch
                radius: 14
                color: "#66FFFFFF"
                border.color: "white"
                border.width: 4
                visible: !g.filled[index] && g.phase === "build"
                Text {
                    anchors.centerIn: parent
                    visible: index === g.carCount - 1
                    text: "🚂"
                    font.pixelSize: g.ch * 0.5
                    opacity: 0.5
                }
            }
        }

        // ===== il treno montato (parte tutto insieme) =====
        Item {
            id: train
            x: g.trainX
            y: g.trackY + bob
            width: g.trainW; height: g.ch

            // sobbalzi mentre viaggia
            property real bob: 0
            SequentialAnimation on bob {
                running: g.phase === "running"
                loops: Animation.Infinite
                onRunningChanged: if (!running) train.bob = 0
                NumberAnimation { to: -3; duration: 130 }
                NumberAnimation { to: 0; duration: 130 }
            }

            // durante il viaggio ogni tocco sul treno lo fa correre piu' forte
            MouseArea {
                anchors.fill: parent
                z: 5
                enabled: g.phase === "running"
                onClicked: g.push()
            }

            // piccolo saltello a ogni vagone agganciato
            Repeater {
                model: g.carCount
                Car {
                    id: placed
                    required property int index
                    readonly property bool full: g.filled[index] === true
                    x: index * (g.cw + g.gap)
                    width: g.cw
                    visible: full
                    loco: index === g.carCount - 1
                    body: g.placedColor[index] || "#bbbbbb"
                    spin: g.wheelAngle
                    smoking: g.phase === "running" && loco
                    onFullChanged: if (full) hop.restart()
                    transformOrigin: Item.Bottom
                    SequentialAnimation {
                        id: hop
                        NumberAnimation { target: placed; property: "scale"; from: 0.8; to: 1.1; duration: 140; easing.type: Easing.OutBack }
                        NumberAnimation { target: placed; property: "scale"; to: 1.0; duration: 120 }
                    }
                    // toccando la locomotiva suona il fischio
                    MouseArea {
                        anchors.fill: parent
                        enabled: placed.loco && placed.full
                        onClicked: snd.win()
                    }
                }
            }
        }

        // ===== il viaggio =====
        Timer {
            interval: 16
            repeat: true
            running: g.phase === "running"
            onTriggered: g.advance(0.016)
        }
        Timer {
            id: winTimer
            interval: 6200
            onTriggered: g.win()
        }

        // ciuf ciuf: piu' veloce, piu' spesso
        Timer {
            interval: Math.max(160, 520 - (g.boost + 150) * 0.8)
            repeat: true
            running: g.phase === "running"
            onTriggered: snd.tap()
        }

        // "ciuf!" che sale dalla ciminiera a ogni tocco
        Text {
            id: chuffText
            x: g.trainX + g.trainW - 70
            y: g.trackY - 40
            text: qsTr("CIUF!")
            font.pixelSize: 34; font.bold: true
            color: "#FFFFFF"; style: Text.Outline; styleColor: "#607D8B"
            opacity: 0
            z: 6
            ParallelAnimation {
                id: chuff
                NumberAnimation { target: chuffText; property: "y"; from: g.trackY - 20; to: g.trackY - 80; duration: 600 }
                SequentialAnimation {
                    NumberAnimation { target: chuffText; property: "opacity"; to: 1; duration: 80 }
                    NumberAnimation { target: chuffText; property: "opacity"; to: 0; duration: 520 }
                }
            }
        }

        // barra del viaggio: dal treno alla stazione
        Item {
            id: journey
            visible: g.phase === "running" || g.phase === "arrived"
            x: 290; y: 10
            width: 280; height: 44
            Rectangle {
                x: 12; y: 21; width: parent.width - 24; height: 10; radius: 5
                color: "#CCFFFFFF"; border.color: "#90A4AE"; border.width: 2
                Rectangle {
                    width: parent.width * Math.min(1, g.scroll / g.goal); height: parent.height
                    radius: 5; color: "#43A047"
                }
            }
            Text {
                x: 12 + (journey.width - 24) * Math.min(1, g.scroll / g.goal) - width / 2
                y: 0; text: "🚂"; font.pixelSize: 30
            }
            Text { x: parent.width - 28; y: 0; text: "🚉"; font.pixelSize: 30 }
        }

        // invito a toccare il treno
        Text {
            visible: g.phase === "running" && g.scroll < g.goal - 1100
            anchors.horizontalCenter: parent.horizontalCenter
            y: g.trackY + g.ch + 52
            text: "👆 " + qsTr("Tocca il treno!")
            font.pixelSize: 38; font.bold: true
            color: "white"; style: Text.Outline; styleColor: "#2E7D32"
            SequentialAnimation on scale {
                running: g.phase === "running"
                loops: Animation.Infinite
                NumberAnimation { to: 1.1; duration: 500; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 500; easing.type: Easing.InOutSine }
            }
        }

        // i passeggeri scendono da ogni vagone, attraversano la banchina e
        // entrano nella stazione da una delle sue porte
        Repeater {
            model: Math.max(0, g.carCount - 1)
            Person {
                id: pax
                required property int index
                readonly property real startX: g.trainX + index * (g.cw + g.gap) + g.cw / 2 - 20
                readonly property real doorY: g.trackY + g.ch * 0.1
                readonly property real platformY: g.trackY + g.ch + 28 - 90 + 28   // piedi sulla banchina
                // la strada: scende dalla banchina a sinistra della stazione e poi
                // costeggia la facciata fino alla porta scelta (una delle tre)
                readonly property real roadX: station.x - 76 + 12
                readonly property real roadFeetY: station.y + station.height + 22 - 90
                readonly property real doorX: station.x + station.width * (0.12 + (index % 3) * 0.3 + 0.08) - 20
                readonly property real doorFeetY: station.y + station.height - 90
                visible: g.phase === "arrived"
                x: startX; y: doorY
                opacity: 0
                z: 8
                shirt: ["#42A5F5", "#EF5350", "#66BB6A", "#AB47BC"][index % 4]
                hair: ["#5D4037", "#FDD835", "#212121", "#BDBDBD"][index % 4]
                girl: index % 2 === 0
                walking: g.phase === "arrived"

                SequentialAnimation {
                    running: g.phase === "arrived"
                    PropertyAction { target: pax; property: "opacity"; value: 0 }
                    PropertyAction { target: pax; property: "scale"; value: 1 }
                    PropertyAction { target: pax; property: "x"; value: pax.startX }
                    PropertyAction { target: pax; property: "y"; value: pax.doorY }
                    PauseAnimation { duration: pax.index * 450 }
                    // compare alla porta del vagone
                    NumberAnimation { target: pax; property: "opacity"; to: 1; duration: 200 }
                    // scende dal treno sulla banchina
                    NumberAnimation { target: pax; property: "y"; to: pax.platformY; duration: 450; easing.type: Easing.OutBounce }
                    // cammina lungo la banchina fino alla strada pedonale
                    NumberAnimation { target: pax; property: "x"; to: pax.roadX; duration: 700; easing.type: Easing.InOutQuad }
                    // scende sulle strisce pedonali fino davanti alla stazione
                    NumberAnimation { target: pax; property: "y"; to: pax.roadFeetY; duration: 1000; easing.type: Easing.InOutQuad }
                    // costeggia la facciata fino alla porta
                    NumberAnimation { target: pax; property: "x"; to: pax.doorX; duration: 900; easing.type: Easing.InOutQuad }
                    // sale i gradini ed entra dalla porta
                    NumberAnimation { target: pax; property: "y"; to: pax.doorFeetY; duration: 300 }
                    // ed entra
                    ParallelAnimation {
                        NumberAnimation { target: pax; property: "opacity"; to: 0; duration: 350 }
                        NumberAnimation { target: pax; property: "scale"; to: 0.85; duration: 350 }
                    }
                }
            }
        }

        // ===== pulsante START =====
        Rectangle {
            id: startBtn
            visible: g.phase === "ready"
            anchors.horizontalCenter: parent.horizontalCenter
            y: g.trackY + g.ch + 44
            width: 220; height: 84; radius: 42
            color: "#43A047"
            border.color: "#2E7D32"; border.width: 5
            scale: startMa.pressed ? 0.94 : 1

            SequentialAnimation on scale {
                running: startBtn.visible && !startMa.pressed
                loops: Animation.Infinite
                NumberAnimation { to: 1.08; duration: 450; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 450; easing.type: Easing.InOutSine }
            }

            Row {
                anchors.centerIn: parent
                spacing: 12
                Text { text: "▶"; font.pixelSize: 40; color: "white"; anchors.verticalCenter: parent.verticalCenter }
                Text { text: qsTr("START"); font.pixelSize: 40; font.bold: true; color: "white"; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea { id: startMa; anchors.fill: parent; onClicked: g.start() }
        }

        // ===== vassoio dei pezzi =====
        Repeater {
            model: g.trayCars

            Car {
                id: piece
                required property int index
                required property var modelData

                width: g.cw
                loco: modelData.loco
                body: modelData.color

                readonly property int trayCount: g.trayCars.length
                readonly property real rowW: trayCount * g.cw + (trayCount - 1) * g.gap
                readonly property real homeX: (area.width - rowW) / 2 + index * (g.cw + g.gap)
                readonly property real homeY: area.height - g.ch - 24

                z: dragArea.drag.active ? 10 : 1

                function goHome() { x = homeX; y = homeY }

                onHomeXChanged: if (!dragArea.drag.active) goHome()
                onHomeYChanged: if (!dragArea.drag.active) goHome()

                Behavior on x { enabled: !dragArea.drag.active; NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }
                Behavior on y { enabled: !dragArea.drag.active; NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }

                Component.onCompleted: goHome()

                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    enabled: g.phase === "build"
                    drag.target: piece
                    drag.minimumX: 0
                    drag.maximumX: area.width - piece.width
                    drag.minimumY: 0
                    drag.maximumY: area.height - piece.height

                    onPressed: snd.tap()
                    onReleased: {
                        var cx = piece.x + piece.width / 2
                        var cy = piece.y + piece.height / 2
                        var hit = -1
                        for (var v = 0; v < g.carCount; v++) {
                            var sl = slotRep.itemAt(v)
                            if (!sl) continue
                            var p = sl.mapFromItem(area, cx, cy)
                            if (p.x >= 0 && p.x <= sl.width && p.y >= 0 && p.y <= sl.height) {
                                hit = v
                                break
                            }
                        }
                        if (!g.drop(piece.modelData, hit))
                            piece.goHome()
                    }
                }
            }
        }
    }
}
