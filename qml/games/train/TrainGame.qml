// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// "Il trenino" - prima si costruisce il treno, poi lo si fa partire.
// Sul binario ci sono le caselle vuote; i vagoni (e la locomotiva) stanno nel
// vassoio in basso e si trascinano al loro posto: la locomotiva davanti (a
// destra, il treno va verso destra), i vagoni dietro, nell'ordine che il
// bambino preferisce. Prima della partenza i vagoni agganciati si possono
// spostare, scambiare o rimettere nel vassoio. Dai livelli 3 in poi in alto
// c'e' il modellino: copiarlo e' una sfida in piu', non un obbligo (se i
// colori coincidono spunta una stella). Quando tutte le caselle sono piene
// compare il pulsante START: si tocca e il treno parte,
// fa fumo e viaggia verso la prossima stazione: lo scenario scorre, il
// bambino tocca il treno per farlo correre piu' forte (ciuf! e fischio) e
// il treno frena da solo arrivando in stazione, dove aspettano i passeggeri.
MiniGame {
    id: g
    title: qsTr("Il trenino")
    contentMargins: 0
    age: qsTr("3-4 anni")
    levelCount: 6

    readonly property var counts: [3, 3, 4, 4, 5, 5]   // locomotiva compresa

    property int  carCount: 3
    property bool showModel: false      // true: in alto c'e' il modellino
    property var  order: []             // colori del modellino (la locomotiva e' l'ultima)
    property var  slots: []             // per casella: { uid, loco, color } oppure null
    property var  trayCars: []          // pezzi ancora nel vassoio
    property int  dragFrom: -1          // casella del vagone che si sta spostando
    readonly property var filled: slots.map((c) => c !== null)
    readonly property bool likeModel: showModel && slots.length === order.length
        && slots.every((c, i) => c !== null && Qt.colorEqual(c.color, order[i]))
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
        showModel = i >= 2
        dragFrom = -1

        var wagons = shuffle(Theme.playColors.slice(1)).slice(0, carCount - 1)
        order = wagons.concat([locoColor])
        var empty = []
        for (var k = 0; k < carCount; k++) empty.push(null)
        slots = empty

        var tray = [{ uid: 0, loco: true, color: locoColor }]
        for (var w = 0; w < wagons.length; w++)
            tray.push({ uid: w + 1, loco: false, color: wagons[w] })
        trayCars = shuffle(tray)
    }

    readonly property bool building: phase === "build" || phase === "ready"

    function refreshPhase() { phase = trayCars.length === 0 ? "ready" : "build" }

    // Un pezzo del vassoio lasciato sulla casella "slot" (< 0: fuori dalle
    // caselle). Davanti va solo la locomotiva, dietro un vagone qualsiasi; se
    // la casella e' occupata, il vagone che c'era torna nel vassoio.
    // true = agganciato.
    function drop(car, slot) {
        if (slot < 0 || !building) return false
        if (car.loco !== (slot === carCount - 1)) {
            g.wrong()
            snd.nope()
            return false
        }
        var s = slots.slice()
        var old = s[slot]
        s[slot] = car
        var tray = trayCars.filter(function (c) { return c.uid !== car.uid })
        if (old !== null) tray.push(old)
        slots = s
        trayCars = tray
        snd.ok()
        refreshPhase()
        return true
    }

    // Un vagone gia' agganciato spostato dalla casella "from": su un'altra
    // casella ci va (scambiandosi con quello che c'e'), con to = -2 torna nel
    // vassoio, altrimenti resta dov'era.
    function move(from, to) {
        if (!building || slots[from] === null || slots[from].loco) return false
        var s = slots.slice()
        if (to === -2) {
            var back = s[from]
            s[from] = null
            slots = s
            trayCars = trayCars.concat([back])
        } else {
            if (to < 0 || to === from) return false
            if (to === carCount - 1) { snd.nope(); return false }   // li' va la locomotiva
            var other = s[to]
            s[to] = s[from]
            s[from] = other
            slots = s
        }
        snd.ok()
        refreshPhase()
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

    // cartella delle illustrazioni (disegnate da scripts/make_art.py)
    readonly property string art: "qrc:/qt/qml/Orme/assets/art/"
    // chi viaggia sul treno
    readonly property var riders: ["rabbit", "cat", "dog", "panda", "frog", "fox", "koala", "pig"]

    // il vagone (e la locomotiva) e' il disegno comune ai giochi col treno
    component Car: TrainCar {}

    // ---------- un passeggero che scende e cammina saltellando ----------
    component Person: Item {
        id: person
        property string animal: "rabbit"
        property bool walking: false
        property real bob: 0
        width: 40; height: 90

        SequentialAnimation on bob {
            running: person.walking
            loops: Animation.Infinite
            onRunningChanged: if (!running) person.bob = 0
            NumberAnimation { to: -12; duration: 170; easing.type: Easing.OutQuad }
            NumberAnimation { to: 0; duration: 170; easing.type: Easing.InQuad }
        }

        Rectangle {   // ombra
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - 8
            width: 40 + person.bob; height: 10; radius: 5
            color: "#40000000"
        }
        AppIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - height + person.bob
            name: person.animal
            size: 62
            rotation: person.bob * 0.7
        }
    }

    // ---------- scenario: casetta, stazione e albero ----------
    component House: Item {
        id: house
        property string art: ""
        property int  variant: 1
        property bool lit: false      // luci accese
        signal tapped()
        height: width
        transformOrigin: Item.Bottom
        readonly property real u: width / 200

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

        Image {
            anchors.fill: parent
            source: house.art + "house-" + house.variant + ".png"
            mipmap: true
        }
        Repeater {   // finestre illuminate
            model: house.lit ? [[36, 116, 36, 34], [130, 116, 36, 34], [86, 52, 28, 28]] : []
            Rectangle {
                required property var modelData
                x: modelData[0] * house.u; y: modelData[1] * house.u
                width: modelData[2] * house.u; height: modelData[3] * house.u
                radius: 8 * house.u
                color: "#B3FFD600"
            }
        }
        Repeater {   // fumo dal comignolo quando si tocca
            model: 3
            Image {
                id: hpuff
                required property int index
                width: 34 * house.u; height: width
                x: 154 * house.u - width / 2; y: 0
                source: house.art + "puff.png"
                opacity: 0
                Connections {
                    target: house
                    function onPoked() { hp.restart() }
                }
                SequentialAnimation {
                    id: hp
                    PauseAnimation { duration: hpuff.index * 160 }
                    ParallelAnimation {
                        NumberAnimation { target: hpuff; property: "y"; from: 0; to: -house.height * 0.55; duration: 900 }
                        NumberAnimation { target: hpuff; property: "x"; from: 154 * house.u - hpuff.width / 2; to: 120 * house.u - hpuff.width / 2; duration: 900 }
                        NumberAnimation { target: hpuff; property: "scale"; from: 0.6; to: 1.8; duration: 900 }
                        SequentialAnimation {
                            NumberAnimation { target: hpuff; property: "opacity"; to: 0.95; duration: 120 }
                            NumberAnimation { target: hpuff; property: "opacity"; to: 0; duration: 780 }
                        }
                    }
                }
            }
        }
    }

    component Station: Item {
        id: st
        property string art: ""
        height: width * 0.62
        property bool ringing: false     // campanella: insegna e porte si illuminano
        signal tapped()
        transformOrigin: Item.Bottom
        readonly property real u: width / 520

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
        Row {
            id: dingText
            x: st.width * 0.5 - width / 2; y: -st.height * 0.1
            spacing: 6
            opacity: 0; z: 11
            AppIcon { name: "bell"; size: st.height * 0.24; anchors.verticalCenter: parent.verticalCenter }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("DING DONG!")
                font.pixelSize: st.height * 0.2; font.bold: true
                color: "white"; style: Text.Outline; styleColor: "#1565C0"
            }
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

        Image {
            x: -4 * st.u; y: -4 * st.u
            width: 528 * st.u; height: 330 * st.u
            source: st.art + "station.png"
        }
        Rectangle {   // l'insegna si illumina quando suona
            x: 112 * st.u; y: 149 * st.u
            width: 296 * st.u; height: 44 * st.u; radius: 13 * st.u
            color: st.ringing ? "#FF8F00" : "transparent"
            Text {
                anchors.centerIn: parent
                text: qsTr("STAZIONE")
                color: "white"; font.bold: true
                font.pixelSize: parent.height * 0.72
            }
        }
        Repeater {   // porte illuminate quando suona
            model: st.ringing ? 3 : 0
            Rectangle {
                required property int index
                x: st.width * (0.12 + index * 0.3); y: st.height * 0.69
                width: st.width * 0.16; height: st.height * 0.285
                radius: width / 2
                color: "#B3FFE082"
            }
        }
    }

    component Tree: Item {
        id: tree
        property string art: ""
        property int variant: 1
        height: width * 1.25
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
        Image {
            anchors.fill: parent
            source: tree.art + "tree-" + tree.variant + ".png"
            mipmap: true
        }
        AppIcon {
            id: leafText
            name: "leaf-wind"; size: tree.width * 0.34
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
    }

    // ---------- contenuto ----------
    Item {
        id: area
        anchors.fill: parent
        clip: true

        // la casella del binario sotto il punto (x, y), -1 se nessuna
        function slotAt(x, y) {
            for (var v = 0; v < g.carCount; v++) {
                var sl = slotRep.itemAt(v)
                if (!sl) continue
                var p = sl.mapFromItem(area, x, y)
                if (p.x >= 0 && p.x <= sl.width && p.y >= 0 && p.y <= sl.height) return v
            }
            return -1
        }

        // ===== scenario: cielo, colline, case, alberi, prato =====
        Item {
            id: scene
            anchors.fill: parent
            z: -5

            readonly property real horizonY: g.trackY + g.ch * 0.3

            Rectangle {   // cielo
                x: 0; y: 0; width: parent.width; height: scene.horizonY + 2
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#6EC6FF" }
                    GradientStop { position: 1.0; color: "#E8F8FF" }
                }
            }
            AppIcon {   // sole
                x: parent.width - 150; y: 8
                name: "sun-face"
                size: 96
            }
            Repeater {   // nuvole che scorrono piano
                model: 3
                Item {
                    id: cloud
                    required property int index
                    y: 24 + index * 34
                    x: 0
                    width: 130; height: 58
                    NumberAnimation on x {
                        from: -150; to: area.width + 40
                        duration: 52000 + cloud.index * 17000
                        loops: Animation.Infinite
                    }
                    Rectangle { x: 0; y: 24; width: 130; height: 34; radius: 17; color: "white" }
                    Rectangle { x: 20; y: 8; width: 48; height: 48; radius: 24; color: "white" }
                    Rectangle { x: 54; y: 0; width: 56; height: 56; radius: 28; color: "white" }
                }
            }
            Repeater {   // colline lontane, tonde, in due tinte
                model: Math.ceil(area.width / 300) + 2
                Rectangle {
                    required property int index
                    width: 420; height: width; radius: width / 2
                    x: index * 300 - 180
                    y: scene.horizonY - 70 - (index % 2) * 34
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: index % 2 ? "#9FDCB4" : "#B8E58C" }
                        GradientStop { position: 0.35; color: index % 2 ? "#7FCB9C" : "#9BD56F" }
                    }
                }
            }

            // il prato davanti
            Rectangle {
                x: 0; y: scene.horizonY; width: parent.width; height: parent.height - scene.horizonY
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#74C043" }
                    GradientStop { position: 1.0; color: "#B5E36E" }
                }
            }
            Repeater {   // fiori nel prato: scorrono insieme alla strada
                model: 18
                AppIcon {
                    required property int index
                    readonly property real span: area.width + 120
                    name: ["blossom", "tulip", "clover", "cherry-blossom", "mushroom"][index % 5]
                    size: 28 + (index % 3) * 8
                    x: (((index * 197 - g.scroll) % span) + span) % span - 60
                    y: g.trackY + g.ch + 56 + ((index * 71) % 100) / 100
                       * Math.max(0, area.height - g.trackY - g.ch - 110)
                }
            }

            // case e alberi lungo l'orizzonte
            Repeater {
                model: Math.ceil((area.width + 720) / 120) + 1
                Item {
                    id: slot
                    required property int index
                    readonly property bool isTree: index % 3 === 1
                    readonly property real hh: Math.max(56, Math.min(116, g.trackY - 56))
                    x: index * 120 + 4 + (((index % 6) * 37) % 17) - (g.scroll % 720)
                    y: scene.horizonY
                    width: 110; height: 0

                    House {
                        art: g.art
                        visible: !slot.isTree
                        width: slot.hh * (0.9 + (slot.index % 3) * 0.08)
                        variant: 1 + slot.index % 3
                        y: -height + 8
                        onTapped: snd.tap()
                    }
                    Tree {
                        art: g.art
                        visible: slot.isTree
                        width: slot.hh * 0.78
                        x: 12
                        variant: 1 + slot.index % 2
                        y: -height + 8
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
                color: "#EFDDB5"
                border.color: "#C9A86A"; border.width: 3
                Repeater {
                    model: 5
                    Rectangle {
                        required property int index
                        x: 8; y: 10 + index * 13; width: parent.width - 16; height: 7; radius: 3
                        color: "white"
                    }
                }
            }
            Rectangle {
                id: walkAcross
                x: station.x - 76; width: station.width + 76 + 30
                y: station.y + station.height
                height: 34; radius: 8
                color: "#EFDDB5"
                border.color: "#C9A86A"; border.width: 3
                Repeater {   // ciottoli
                    model: Math.floor((parent.width - 30) / 40)
                    Rectangle { required property int index; x: 8 + index * 40; y: 12 + (index % 2) * 7; width: 20; height: 8; radius: 4; color: "#DCC391" }
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
                art: g.art
                width: Math.max(220, Math.min(340, g.trainW * 0.6))
                x: Math.max(10, g.trainX + g.trainW - width - 24) + (g.goal - g.scroll)
                y: Math.min(g.trackY + g.ch + 100, area.height - height - 44)
                onTapped: snd.ok()
            }
        }

        // ===== modellino da copiare (dai livelli 3 in poi) =====
        Rectangle {
            visible: g.showModel
            x: 8; y: 8
            width: modelRow.width + 20; height: modelRow.height + 14
            radius: 14
            color: "#CCFFFFFF"
        }
        Row {
            id: modelRow
            visible: g.showModel
            x: 18; y: 15
            spacing: 4
            Repeater {
                model: g.carCount
                Car {
                    required property int index
                    art: g.art
                    width: 54
                    loco: index === g.carCount - 1
                    body: g.order[index] || "#bbbbbb"
                }
            }
        }

        AppIcon {   // stella: il treno e' proprio come il modellino
            x: modelRow.x + modelRow.width - 6
            y: modelRow.y + modelRow.height - 12
            name: "star-glowing"
            size: 44
            scale: g.likeModel ? 1 : 0
            visible: scale > 0
            Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
        }

        // ===== binario: massicciata, traversine e due rotaie =====
        Rectangle {   // massicciata
            x: 0; width: parent.width
            y: g.trackY + g.ch - 32
            height: 48
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#D7C7BC" }
                GradientStop { position: 1.0; color: "#A89080" }
            }
            border.color: "#8D7466"; border.width: 2
        }
        Repeater {   // traversine
            model: Math.ceil(area.width / 26) + 2
            Rectangle {
                required property int index
                x: index * 26 + 4 - (g.scroll % 26); y: g.trackY + g.ch - 29
                width: 13; height: 42; radius: 4
                color: "#9C6B43"
                border.color: "#6D4527"; border.width: 2
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
                radius: 18
                color: "#59FFFFFF"
                border.color: "white"
                border.width: 4
                visible: g.building && (!g.filled[index] || g.dragFrom === index)
                Image {
                    readonly property real u: parent.width / 224
                    x: 0; y: parent.height - height
                    width: parent.width; height: 172 * u
                    source: g.art + (index === g.carCount - 1 ? "loco-grey" : "wagon-grey") + ".png"
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
            z: g.dragFrom >= 0 ? 20 : 0     // il vagone spostato passa sopra al resto

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
                    readonly property var car: g.slots[index] || null
                    readonly property bool full: car !== null
                    readonly property int uid: car ? car.uid : 0
                    readonly property bool held: grip.drag.active
                    // al suo posto, tranne mentre lo si trascina
                    Binding on x { when: !placed.held; value: placed.index * (g.cw + g.gap); restoreMode: Binding.RestoreNone }
                    Binding on y { when: !placed.held; value: 0; restoreMode: Binding.RestoreNone }
                    z: held ? 10 : 0
                    art: g.art
                    width: g.cw
                    visible: full
                    // all'arrivo il primo passeggero scende dal vagone
                    // i passeggeri viaggiano col loro vagone, anche se cambia posto
                    rider: g.phase === "arrived" || !uid ? "" : g.riders[(uid - 1) % g.riders.length]
                    rider2: uid ? g.riders[(uid + 3) % g.riders.length] : ""
                    loco: index === g.carCount - 1
                    body: car ? car.color : "#bbbbbb"
                    spin: g.wheelAngle
                    smoking: g.phase === "running" && loco
                    onUidChanged: if (full) hop.restart()
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
                    // prima della partenza i vagoni si spostano col dito
                    MouseArea {
                        id: grip
                        anchors.fill: parent
                        enabled: g.building && placed.full && !placed.loco
                        drag.target: placed
                        drag.minimumX: -train.x
                        drag.maximumX: area.width - train.x - placed.width
                        drag.minimumY: -train.y
                        drag.maximumY: area.height - train.y - placed.height
                        drag.onActiveChanged: if (drag.active) g.dragFrom = placed.index
                        onPressed: snd.tap()
                        onReleased: {
                            if (g.dragFrom !== placed.index) return
                            var c = placed.mapToItem(area, placed.width / 2, placed.height / 2)
                            var to = area.slotAt(c.x, c.y)
                            // lasciato in basso, verso il vassoio: si toglie dal treno
                            if (to < 0 && c.y > g.trackY + g.ch * 1.6) to = -2
                            // dopo il rilascio: cosi' il vagone torna da solo al suo posto
                            var from = placed.index
                            Qt.callLater(() => { g.move(from, to); g.dragFrom = -1 })
                        }
                        onCanceled: g.dragFrom = -1
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
            // al centro, ma sempre a destra del modellino da copiare
            x: Math.max(g.showModel ? modelRow.x + modelRow.width + 18 : 12, (parent.width - width) / 2)
            y: 10
            width: 280; height: 44
            Rectangle {
                x: 12; y: 21; width: parent.width - 24; height: 10; radius: 5
                color: "#CCFFFFFF"; border.color: "#90A4AE"; border.width: 2
                Rectangle {
                    width: parent.width * Math.min(1, g.scroll / g.goal); height: parent.height
                    radius: 5; color: "#43A047"
                }
            }
            AppIcon {
                x: 12 + (journey.width - 24) * Math.min(1, g.scroll / g.goal) - width / 2
                y: 0; name: "locomotive"; size: 34
            }
            AppIcon { x: parent.width - 28; y: 0; name: "station"; size: 34 }
        }

        // invito a toccare il treno
        Row {
            visible: g.phase === "running" && g.scroll < g.goal - 1100
            anchors.horizontalCenter: parent.horizontalCenter
            y: g.trackY + g.ch + 52
            spacing: 10
            AppIcon { name: "point-up"; size: 48; anchors.verticalCenter: parent.verticalCenter }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Tocca il treno!")
                font.pixelSize: 38; font.bold: true
                color: "white"; style: Text.Outline; styleColor: "#2E7D32"
            }
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
                // il passeggero del vagone che si trova in questa casella
                readonly property int uid: g.slots[index] && g.slots[index].uid ? g.slots[index].uid : 1
                animal: g.riders[(uid - 1) % g.riders.length]
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
            border.color: "white"; border.width: 5
            scale: startMa.pressed ? 0.94 : 1
            Candy { depth: 8 }

            SequentialAnimation on scale {
                running: startBtn.visible && !startMa.pressed
                loops: Animation.Infinite
                NumberAnimation { to: 1.08; duration: 450; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 450; easing.type: Easing.InOutSine }
            }

            Row {
                anchors.centerIn: parent
                spacing: 12
                AppIcon { name: "ui/play"; size: 46; anchors.verticalCenter: parent.verticalCenter }
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

                art: g.art
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
                    enabled: g.building
                    drag.target: piece
                    drag.minimumX: 0
                    drag.maximumX: area.width - piece.width
                    drag.minimumY: 0
                    drag.maximumY: area.height - piece.height

                    onPressed: snd.tap()
                    onReleased: {
                        var hit = area.slotAt(piece.x + piece.width / 2,
                                              piece.y + piece.height / 2)
                        if (!g.drop(piece.modelData, hit))
                            piece.goHome()
                    }
                }
            }
        }
    }
}
