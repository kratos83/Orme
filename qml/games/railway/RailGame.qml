// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Il viaggio in treno comune al "Treno delle vocali" e al "Treno dei numeri".
// Ogni livello ha alcune stazioni e, prima di ciascuna, un segnale (in ordine
// casuale):
//   - semaforo: col rosso si preme STOP e si aspetta il verde, poi VIA;
//   - segnale di STOP: ci si ferma, si guarda, poi VIA;
//   - divieto di accesso: fra due binari si sceglie quello libero.
// Il treno rallenta e aspetta da solo: non c'e' fretta e non si perde mai.
//
// Il gioco che usa questo componente:
//   - riempie i vagoni (wagonColors, seats, plates);
//   - su levelStarted prepara il livello, su stationArrived mostra il suo
//     compito (un figlio, sopra la scena) e, finito, chiama taskDone();
//   - su departing prepara cio' che serve per la stazione successiva.
MiniGame {
    id: g
    contentMargins: 0
    levelCount: 6

    // ---------- da impostare nel gioco ----------
    property int wagonCount: 5
    property var wagonColors: []          // uno per vagone
    property var seats: []                // per vagone: [animale, animale] ai finestrini
    property var plates: []               // per vagone: scritta sul cartello ("" = niente)
    property string taskHint: ""          // consiglio mostrato in stazione
    property string taskIcon: "station"
    property real trackRatio: 0.34        // altezza del binario nella scena

    readonly property int stations: 3

    signal levelStarted(int level)
    signal stationArrived(int station)
    signal departing(int station)         // si riparte verso la stazione "station"
    signal wagonTapped(int wagon)

    // ---------- stato del viaggio ----------
    property var events: []               // "light" | "stop" | "noentry" | "station"
    property int step: 0
    property string kind: ""              // l'evento di adesso
    // approach: il treno arriva | halt: fermo davanti al segnale |
    // braked: STOP premuto | pass: riparte | task: in stazione | end: finito
    property string phase: "approach"
    property string lamp: "red"
    property bool   clear: false          // dopo lo STOP: strada libera
    property int    freeSide: 0           // al divieto: quale dei due binari e' libero
    property int    station: 0
    property real   scroll: 0
    property real   eventAt: 0
    property real   leaveAt: 0
    property real   speed: 0
    property real   wheelAngle: 0
    property int    shaken: -1            // vagone che scuote la testa

    readonly property bool moving: (phase === "approach" || phase === "pass") && speed > 1
    readonly property bool signalAhead: kind === "light" || kind === "stop"
    readonly property bool canDrive: signalAhead
        && (phase === "approach" || phase === "halt" || phase === "braked")

    // ---------- misure (condivise col gioco: stesse coordinate della scena) ----------
    readonly property int  carsTotal: wagonCount + 1          // locomotiva compresa
    readonly property real signRoom: Math.max(110, area.width * 0.14)
    readonly property real cw: Math.max(40, Math.min(150, (area.width - signRoom - 30) / (carsTotal * 1.1)))
    readonly property real ch: cw * 0.7
    readonly property real gap: cw * 0.1
    readonly property real trainW: carsTotal * cw + (carsTotal - 1) * gap
    readonly property real trainX: Math.max(8, (area.width - signRoom - trainW) / 2)
    readonly property bool hasPlates: plates.some((p) => p !== "")
    readonly property real trackY: Math.max(area.height * trackRatio - ch / 2,
                                            72 + (hasPlates ? cw * 0.5 : 6))
    readonly property real groundY: trackY + ch
    readonly property real passDistance: area.width * 1.1

    readonly property string art: "qrc:/qt/qml/Orme/assets/art/"

    SoundBank { id: snd }
    property alias sound: snd

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
        releaseTimer.stop()
        departTimer.stop()
        finishTimer.stop()
        levelIndex = i
        won = false
        mistakes = 0
        var signals_ = shuffle(["light", "stop", "noentry"])
        var list = []
        for (var s = 0; s < stations; s++) list.push(signals_[s % signals_.length], "station")
        events = list
        station = 0
        scroll = 0
        speed = 0
        shaken = -1
        levelStarted(i)
        begin(0)
    }

    // comincia ad avvicinarsi all'evento n
    function begin(n) {
        step = n
        kind = events[n]
        lamp = Math.random() < 0.7 ? "red" : "green"
        clear = false
        freeSide = Math.random() < 0.5 ? 0 : 1
        eventAt = scroll + area.width * 0.75
        phase = "approach"
    }

    // un passo di viaggio (dt in secondi)
    function advance(dt) {
        if (phase === "approach") {
            var left = eventAt - scroll
            var want = Math.min(230, Math.max(55, left * 1.1))
            speed = Math.min(want, speed + 320 * dt)
            var d = Math.min(left, speed * dt)
            scroll += d
            wheelAngle += d * 2.6
            if (eventAt - scroll <= 0.5) arrive()
        } else if (phase === "pass") {
            speed = Math.min(420, speed + 420 * dt)
            scroll += speed * dt
            wheelAngle += speed * dt * 2.6
            if (scroll >= leaveAt) {
                if (kind === "station") departing(station)
                begin(step + 1)
            }
        }
    }

    function arrive() {
        scroll = eventAt
        speed = 0
        if (kind === "station") {
            phase = "task"
            snd.ok()
            stationArrived(station)
        } else {
            phase = "halt"
        }
    }

    function leave() {
        leaveAt = Math.max(scroll, eventAt) + passDistance
        phase = "pass"
    }

    function mistake() {
        snd.nope()
        wrong()
        wobble.restart()
    }

    function pressStop() {
        if (!canDrive || phase === "braked") return
        if (kind === "light" && lamp === "green") { mistake(); return }   // col verde si va
        speed = 0
        phase = "braked"
        snd.tap()
        releaseTimer.interval = kind === "light" ? 2200 : 1500
        releaseTimer.restart()
    }

    function pressGo() {
        if (!canDrive) return
        if (kind === "light") {
            if (lamp !== "green") { mistake(); return }
        } else {
            if (phase !== "braked") { mistake(); return }    // allo STOP prima ci si ferma
            if (!clear) return                               // sta ancora guardando
        }
        releaseTimer.stop()
        snd.ok()
        leave()
    }

    // al divieto di accesso: si tocca uno dei due binari
    function choose(side) {
        if (kind !== "noentry" || phase !== "halt") return
        if (side !== freeSide) { mistake(); return }
        snd.ok()
        switchHop.restart()
        leave()
    }

    // il gioco ha finito il compito della stazione
    function taskDone() {
        if (phase !== "task") return
        if (step >= events.length - 1) {
            phase = "end"
            finishTimer.restart()
        } else {
            departTimer.restart()
        }
    }

    // centro del vagone n, nelle coordinate della scena
    function wagonX(n) { return trainX + n * (cw + gap) + cw / 2 }

    // il vagone sotto il punto (x, y), -1 se nessuno
    function wagonAt(x, y) {
        if (y < trackY - cw * 0.6 || y > groundY + 24) return -1
        for (var n = 0; n < wagonCount; n++)
            if (Math.abs(x - wagonX(n)) <= (cw + gap) / 2) return n
        return -1
    }

    function shake(n) { shaken = n; shakeOff.restart() }

    Timer { id: shakeOff; interval: 450; onTriggered: g.shaken = -1 }
    Timer {
        id: releaseTimer
        onTriggered: {
            if (g.kind === "light") g.lamp = "green"
            else g.clear = true
            snd.tap()
        }
    }
    Timer {
        id: departTimer
        interval: 900
        onTriggered: { g.station += 1; g.leave() }
    }
    Timer {
        id: finishTimer
        interval: 1200
        onTriggered: { snd.win(); g.win() }
    }
    Timer {
        interval: 16
        repeat: true
        running: g.phase === "approach" || g.phase === "pass"
        onTriggered: g.advance(0.016)
    }
    Timer {   // ciuf ciuf
        interval: 420
        repeat: true
        running: g.moving
        onTriggered: snd.tap()
    }

    readonly property string hint: {
        if (phase === "end") return qsTr("Siamo arrivati!")
        if (phase === "pass") return qsTr("In viaggio!")
        if (kind === "station") return phase === "task" ? taskHint : qsTr("Ecco la stazione...")
        if (kind === "noentry") return qsTr("Divieto di accesso: scegli l'altro binario!")
        if (kind === "light") {
            if (lamp === "green") return qsTr("Semaforo verde: premi VIA!")
            return phase === "braked" ? qsTr("Fermo! Aspetta il verde...")
                                      : qsTr("Semaforo rosso: premi STOP!")
        }
        if (phase !== "braked") return qsTr("Segnale di STOP: fermati!")
        return clear ? qsTr("Strada libera: premi VIA!") : qsTr("Guarda a destra e a sinistra...")
    }
    readonly property string hintIcon: kind === "station" ? taskIcon
        : (phase === "braked" && kind === "stop" && !clear ? "eyes"
        : (kind === "light" ? "traffic-light" : "locomotive"))

    // ---------- scena ----------
    Item {
        id: area
        anchors.fill: parent
        clip: true

        Rectangle {   // cielo
            width: parent.width; height: g.groundY
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#6EC6FF" }
                GradientStop { position: 1.0; color: "#E8F8FF" }
            }
        }
        Repeater {   // colline lontane
            model: Math.ceil(area.width / 300) + 3
            Rectangle {
                required property int index
                readonly property real span: (Math.ceil(area.width / 300) + 3) * 300
                width: 420; height: width; radius: width / 2
                x: (((index * 300 - g.scroll * 0.15) % span) + span) % span - 420
                y: g.groundY - 96 - (index % 2) * 30
                color: index % 2 ? "#8FD3A8" : "#AEE07F"
            }
        }
        Repeater {   // case e alberi
            model: Math.ceil(area.width / 150) + 3
            Image {
                required property int index
                readonly property real span: (Math.ceil(area.width / 150) + 3) * 150
                readonly property bool isTree: index % 3 !== 0
                width: isTree ? 68 + (index % 2) * 12 : 92
                height: isTree ? width * 1.25 : width
                x: (((index * 150 - g.scroll * 0.55) % span) + span) % span - 150
                y: g.groundY - height - 6
                source: g.art + (isTree ? "tree-" + (1 + index % 2) : "house-" + (1 + index % 3)) + ".png"
                mipmap: true
            }
        }
        Rectangle {   // prato
            y: g.groundY - 8; width: parent.width; height: parent.height - y
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#74C043" }
                GradientStop { position: 1.0; color: "#B5E36E" }
            }
        }
        Repeater {   // fiori
            model: 14
            AppIcon {
                required property int index
                readonly property real span: area.width + 120
                name: ["blossom", "tulip", "clover", "cherry-blossom", "mushroom"][index % 5]
                size: 24 + (index % 3) * 7
                x: (((index * 197 - g.scroll) % span) + span) % span - 60
                y: g.groundY + 30 + ((index * 71) % 100) / 100 * Math.max(0, area.height - g.groundY - 70)
            }
        }

        // la stazione, dietro il treno
        Image {
            visible: g.kind === "station"
            width: Math.max(180, Math.min(380, area.width * 0.45, (g.groundY - 20) * 1.55))
            height: width * 330 / 528
            x: g.trainX + g.trainW / 2 - width / 2 + (g.eventAt - g.scroll)
            y: g.groundY - height - 2
            source: g.art + "station.png"
        }

        // ===== binario =====
        Rectangle {
            width: parent.width; height: 34
            y: g.groundY - 20
            color: "#C2AD9E"
            border.color: "#8D7466"; border.width: 2
        }
        Repeater {   // traversine
            model: Math.ceil(area.width / 26) + 2
            Rectangle {
                required property int index
                x: index * 26 + 4 - (g.scroll % 26); y: g.groundY - 17
                width: 13; height: 28; radius: 4
                color: "#9C6B43"
                border.color: "#6D4527"; border.width: 2
            }
        }
        Rectangle { width: parent.width; height: 5; y: g.groundY - 14; color: "#90A4AE" }
        Rectangle { width: parent.width; height: 6; y: g.groundY - 2; color: "#78909C" }

        // ===== il segnale accanto al binario =====
        RoadSign {
            id: post
            visible: g.signalAhead
            width: Math.max(34, Math.min(92, g.signRoom * 0.72, (g.groundY - 40) / 2.5))
            x: g.trainX + g.trainW + g.cw * 0.12 + 4 + (g.eventAt - g.scroll)
            y: g.groundY + 8 - height
            kind: g.kind === "stop" ? "stop" : "light"
            lamp: g.lamp
            transformOrigin: Item.Bottom
            SequentialAnimation {
                id: wobble
                NumberAnimation { target: post; property: "rotation"; to: -8; duration: 70 }
                NumberAnimation { target: post; property: "rotation"; to: 8; duration: 110 }
                NumberAnimation { target: post; property: "rotation"; to: 0; duration: 90 }
            }
        }

        // ===== il treno =====
        Item {
            id: train
            x: g.trainX
            y: g.trackY + bob + hopY
            width: g.trainW; height: g.ch

            property real bob: 0
            property real hopY: 0
            SequentialAnimation on bob {
                running: g.moving
                loops: Animation.Infinite
                onRunningChanged: if (!running) train.bob = 0
                NumberAnimation { to: -3; duration: 130 }
                NumberAnimation { to: 0; duration: 130 }
            }
            SequentialAnimation {   // il saltino sullo scambio
                id: switchHop
                NumberAnimation { target: train; property: "hopY"; to: -22; duration: 220; easing.type: Easing.OutQuad }
                NumberAnimation { target: train; property: "hopY"; to: 0; duration: 420; easing.type: Easing.OutBounce }
            }

            Repeater {
                model: g.carsTotal
                TrainCar {
                    id: wagon
                    required property int index
                    readonly property bool engine: index === g.wagonCount
                    readonly property var sitting: g.seats[index] || ["", ""]
                    readonly property string plate: engine ? "" : (g.plates[index] || "")
                    x: index * (g.cw + g.gap)
                    width: g.cw
                    art: g.art
                    loco: engine
                    body: engine ? Theme.playColors[0] : (g.wagonColors[index] || "#bbbbbb")
                    rider: sitting[0] || ""
                    rider2: sitting[1] || ""
                    spin: g.wheelAngle
                    smoking: g.moving && engine
                    rotation: g.shaken === index ? shakeAngle : 0
                    transformOrigin: Item.Bottom
                    property real shakeAngle: 0
                    SequentialAnimation on shakeAngle {
                        running: g.shaken === wagon.index
                        NumberAnimation { to: -7; duration: 70 }
                        NumberAnimation { to: 7; duration: 110 }
                        NumberAnimation { to: -4; duration: 90 }
                        NumberAnimation { to: 0; duration: 70 }
                    }

                    Rectangle {   // il cartello sul tetto
                        visible: wagon.plate !== ""
                        width: g.cw * 0.48; height: width; radius: width / 2
                        x: (g.cw - width) / 2; y: -height * 0.94
                        color: "white"
                        border.color: wagon.body; border.width: Math.max(3, g.cw * 0.045)
                        Text {
                            anchors.centerIn: parent
                            text: wagon.plate
                            color: Qt.darker(wagon.body, 1.7)
                            font.bold: true
                            font.pixelSize: Math.max(1, parent.height * 0.66)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.topMargin: wagon.plate !== "" ? -g.cw * 0.46 : 0
                        onClicked: wagon.engine ? snd.win() : g.wagonTapped(wagon.index)
                    }
                }
            }
        }

        // ===== il consiglio in alto =====
        Rectangle {
            id: banner
            anchors.horizontalCenter: parent.horizontalCenter
            y: 6
            width: Math.min(parent.width - 24, bannerRow.implicitWidth + 36)
            height: 56; radius: 28
            color: "#F2FFFFFF"
            border.color: "#FFD54F"; border.width: 3
            Row {
                id: bannerRow
                anchors.centerIn: parent
                spacing: 10
                AppIcon { name: g.hintIcon; size: 38; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, banner.parent.width - 110)
                    text: g.hint
                    color: Theme.text
                    font.pixelSize: 24; font.bold: true
                    fontSizeMode: Text.Fit; minimumPixelSize: 12
                }
            }
        }

        // ===== i pulsanti STOP e VIA =====
        Row {
            id: drive
            visible: g.canDrive
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.max(0, Math.min(area.height - height - 24, g.groundY + 64))
            spacing: 48
            CandyButton {
                objectName: "stopButton"
                width: 176; height: 96
                text: qsTr("STOP"); icon: "ui/stop"; textSize: 38
                color: Theme.danger
                onClicked: g.pressStop()
            }
            CandyButton {
                objectName: "goButton"
                width: 176; height: 96
                text: qsTr("VIA"); icon: "ui/play"; textSize: 38
                color: Theme.accent
                onClicked: g.pressGo()
            }
        }

        // ===== il bivio: due binari, uno col divieto di accesso =====
        Row {
            id: fork
            visible: g.kind === "noentry" && g.phase === "halt"
            anchors.horizontalCenter: parent.horizontalCenter
            y: g.groundY + 28
            spacing: Math.max(24, area.width * 0.06)
            readonly property real cardH: Math.max(90, Math.min(230, area.height - g.groundY - 112))

            Repeater {
                model: 2
                Rectangle {
                    id: way
                    required property int index
                    objectName: "way" + index
                    readonly property bool free: index === g.freeSide
                    width: Math.max(110, fork.cardH * 0.78); height: fork.cardH
                    radius: 22
                    color: "#FFF8E1"
                    border.color: "white"; border.width: 5
                    scale: pick.pressed ? 0.95 : 1
                    Candy {}

                    // un pezzo di binario visto in prospettiva
                    Repeater {
                        model: 4
                        Rectangle {
                            required property int index
                            width: way.width * (0.5 + index * 0.1); height: 7; radius: 3
                            x: (way.width - width) / 2
                            y: way.height * (0.66 + index * 0.08)
                            color: "#9C6B43"
                        }
                    }
                    Repeater {
                        model: [-1, 1]
                        Rectangle {
                            required property int modelData
                            width: 6; height: way.height * 0.34; radius: 3
                            x: way.width / 2 + modelData * way.width * 0.24 - width / 2
                            y: way.height * 0.63
                            rotation: -modelData * 14
                            color: "#607D8B"
                        }
                    }
                    RoadSign {
                        width: way.height * 0.86 / 2.5
                        x: (way.width - width) / 2
                        y: way.height * 0.07
                        kind: way.free ? "straight" : "noentry"
                    }
                    MouseArea { id: pick; anchors.fill: parent; onClicked: g.choose(way.index) }
                }
            }
        }
    }
}
