// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// La "linea dei tasti" fino a 20: due decine divise in cinquine, come quattro
// mani. Un tasto alzato mostra la sua pallina, cosi' la quantita' si legge a
// colpo d'occhio, senza contare uno per uno. Sotto ogni cinquina c'e' una
// mano: ogni dito si accende insieme al suo tasto.
//
// Su schermi stretti le due decine vanno una sotto l'altra. La linea non
// decide nulla: dice al gioco quale tasto si sta toccando (touched / released)
// e disegna quello che il gioco le chiede.
Item {
    id: line

    property int litFrom: 1          // tasti alzati da litFrom a litTo
    property int litTo: 0            // (nessuno se litTo < litFrom)
    property int splitAt: 20         // oltre questo numero le palline sono gialle (secondo addendo)
    property int ghostFrom: 21       // palline tolte (sottrazione), in trasparenza
    property int ghostTo: 0
    property int slotsTo: 0          // fino a qui i posti vuoti hanno un cerchietto
    property bool showDigits: false
    property bool covered: false     // quantita' nascosta (lettura "a colpo d'occhio")
    property bool interactive: false

    signal touched(int n, bool first)   // dito sul tasto n; first = appena appoggiato
    signal released(int n)
    signal peekRequested()

    function shake() { shakeAnim.restart() }

    // Una mano vista dal dorso, appoggiata come sulla tastiera: i pollici
    // stanno verso il centro. "fingers" dice quali dita sono accese, da
    // sinistra a destra; "dots" il colore della pallina di ciascuna.
    // Disegnata su 300 x 205 unita' (v = una unita' in px), col pollice a
    // sinistra; "leftHand" la specchia.
    component Hand: Item {
        id: hand
        property bool leftHand: false
        property var fingers: [false, false, false, false, false]
        property var dots: []
        readonly property real v: width / 300
        readonly property bool full: fingers.indexOf(false) < 0
        height: 205 * v

        Repeater {
            // [centro x, cima, lunghezza, larghezza, inclinazione]: pollice,
            // indice, medio, anulare, mignolo
            model: [[58, 70, 106, 48, -48], [108, 26, 120, 44, -5], [156, 6, 138, 45, 0],
                    [204, 22, 122, 44, 5], [249, 58, 92, 39, 11]]

            Rectangle {
                id: finger
                required property var modelData
                required property int index
                // nella mano sinistra il disegno e' specchiato: il pollice,
                // che e' a destra, e' l'ultimo da sinistra
                readonly property int place: hand.leftHand ? 4 - index : index
                readonly property bool lit: hand.fingers[place] === true
                objectName: "finger" + place

                width: modelData[3] * hand.v
                height: modelData[2] * hand.v
                x: (hand.leftHand ? 300 - modelData[0] : modelData[0]) * hand.v - width / 2
                y: modelData[1] * hand.v
                rotation: hand.leftHand ? -modelData[4] : modelData[4]
                radius: width / 2
                color: lit ? "#FFC83D" : "#FFF6E6"
                border.color: lit ? "#B86E00" : "#D9B98F"
                border.width: Math.max(1, 5 * hand.v)
                Behavior on color { ColorAnimation { duration: 140 } }

                Rectangle {   // sul polpastrello la pallina del tasto
                    visible: finger.lit
                    width: parent.width * 0.62; height: width; radius: width / 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.width * 0.19
                    color: hand.dots[finger.place] || "#EF5350"
                    border.color: Qt.darker(color, 1.25)
                    border.width: Math.max(1, 3 * hand.v)
                }
            }
        }

        Rectangle {   // il palmo, davanti all'attacco delle dita
            x: (hand.leftHand ? 300 - 272 : 80) * hand.v
            y: 108 * hand.v
            width: 192 * hand.v; height: 94 * hand.v
            radius: 42 * hand.v
            color: hand.full ? "#FFC83D" : "#FFE0A8"
            border.color: hand.full ? "#B86E00" : "#C9924E"
            border.width: Math.max(1, 5 * hand.v)
            Behavior on color { ColorAnimation { duration: 140 } }
        }
    }

    // ---------- misure: tutto in "u", la larghezza di un tasto ----------
    readonly property real rowUnits: 4.65      // tasto + alzata + mano
    readonly property real uOne: Math.min(width / 24.0, height / (rowUnits + 0.5), 90)
    readonly property real uTwo: Math.min(width / 11.85, height / (rowUnits * 2 + 0.5), 90)
    readonly property bool twoRows: uTwo > uOne * 1.25
    readonly property real u: Math.max(1, twoRows ? uTwo : uOne)
    readonly property int perRow: twoRows ? 10 : 20
    readonly property real boardW: u * (twoRows ? 11.85 : 24)
    readonly property real boardH: u * (rowUnits * (twoRows ? 2 : 1) + 0.4)

    // posizione orizzontale (in u) del tasto numero i della riga (0 = primo)
    function offsetU(i) {
        var x = 0.3
        for (var j = 0; j < i; j++)
            x += 1 + ((j + 1) % 10 === 0 ? 0.9 : ((j + 1) % 5 === 0 ? 0.45 : 0.1))
        return x
    }

    function keyAt(px, py) {
        var row = twoRows && py > boardH / 2 ? 1 : 0
        var best = 0
        var dist = 1e9
        for (var i = 0; i < perRow; i++) {
            var d = Math.abs(px - (offsetU(i) + 0.5) * u)
            if (d < dist) { dist = d; best = i }
        }
        return row * perRow + best + 1
    }

    Item {
        id: board
        width: line.boardW
        height: line.boardH
        anchors.centerIn: parent

        transform: Translate { id: nudge }
        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: nudge; property: "x"; to: -14; duration: 55 }
            NumberAnimation { target: nudge; property: "x"; to: 14; duration: 80 }
            NumberAnimation { target: nudge; property: "x"; to: -8; duration: 70 }
            NumberAnimation { target: nudge; property: "x"; to: 0; duration: 55 }
        }

        Rectangle {   // la base di legno
            anchors.fill: parent
            radius: line.u * 0.45
            color: "#FFE0B2"
            border.color: "#FFB74D"
            border.width: Math.max(2, line.u * 0.07)
            Candy {}
        }

        Repeater {
            model: 20

            Item {
                id: slot
                required property int index
                readonly property int n: index + 1
                readonly property bool raised: n >= line.litFrom && n <= line.litTo
                readonly property bool ghost: !raised && n >= line.ghostFrom && n <= line.ghostTo
                readonly property bool emptySlot: !raised && !ghost && n <= line.slotsTo
                readonly property color ballColor: n > line.splitAt ? "#FFB300" : "#EF5350"

                x: line.offsetU(index % line.perRow) * line.u
                y: (0.2 + Math.floor(index / line.perRow) * line.rowUnits) * line.u
                width: line.u
                height: line.u * 2.5

                Rectangle {
                    id: key
                    width: parent.width
                    height: line.u * 2.15
                    y: slot.raised ? 0 : line.u * 0.32
                    Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                    radius: line.u * 0.28
                    color: slot.raised ? "#FFFFFF" : (slot.n <= 10 ? "#42A5F5" : "#66BB6A")
                    border.color: slot.n <= 10 ? "#1E88E5" : "#43A047"
                    border.width: Math.max(1, line.u * 0.07)
                    Candy { depth: Math.max(2, line.u * 0.09) }

                    Rectangle {   // pallina (piena, in trasparenza o posto vuoto)
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: line.u * 0.2
                        width: line.u * 0.76
                        height: width
                        radius: width / 2
                        visible: slot.raised || slot.ghost || slot.emptySlot
                        opacity: slot.ghost ? 0.4 : 1
                        color: slot.emptySlot ? "#40FFFFFF" : slot.ballColor
                        border.color: slot.emptySlot ? "white" : Qt.darker(slot.ballColor, 1.25)
                        border.width: Math.max(1, line.u * 0.06)

                        Rectangle {   // riflesso
                            visible: !slot.emptySlot
                            x: parent.width * 0.18; y: parent.height * 0.14
                            width: parent.width * 0.32; height: parent.height * 0.2
                            radius: height / 2
                            rotation: -34
                            color: "#80FFFFFF"
                        }
                        Rectangle {   // barra sulle palline tolte
                            visible: slot.ghost
                            anchors.centerIn: parent
                            width: parent.width * 1.1; height: Math.max(2, line.u * 0.09)
                            radius: height / 2
                            rotation: -45
                            color: Theme.text
                        }
                    }

                    Text {
                        visible: line.showDigits
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: line.u * 0.16 }
                        text: slot.n
                        font.pixelSize: Math.max(8, line.u * 0.52)
                        font.bold: true
                        color: slot.raised ? Theme.text : "white"
                    }
                }
            }
        }

        // una mano sotto ogni cinquina: si accendono le dita dei tasti alzati
        Repeater {
            model: 4
            Hand {
                required property int index
                readonly property int first: index * 5 + 1
                objectName: "hand" + index
                leftHand: index % 2 === 0
                fingers: [0, 1, 2, 3, 4].map((k) => first + k >= line.litFrom && first + k <= line.litTo)
                dots: [0, 1, 2, 3, 4].map((k) => first + k > line.splitAt ? "#FFB300" : "#EF5350")
                width: line.u * 2.7
                x: (line.offsetU((index * 5) % line.perRow) + 2.7) * line.u - width / 2
                y: (2.76 + Math.floor(index * 5 / line.perRow) * line.rowUnits) * line.u
                scale: full ? 1.06 : 1
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: line.interactive && !line.covered
            preventStealing: true
            property int last: 0
            onPressed: (m) => { last = line.keyAt(m.x, m.y); line.touched(last, true) }
            onPositionChanged: (m) => {
                var n = line.keyAt(m.x, m.y)
                if (n !== last) { last = n; line.touched(n, false) }
            }
            onReleased: line.released(last)
        }

        Rectangle {   // la tendina che copre la quantita'
            anchors.fill: parent
            anchors.bottomMargin: -line.u * 0.1
            visible: line.covered
            radius: line.u * 0.45
            color: "#7E57C2"
            border.color: "white"
            border.width: 4

            MouseArea { anchors.fill: parent }   // sotto non si tocca
            CandyButton {
                anchors.centerIn: parent
                height: Math.min(76, parent.height * 0.6)
                textSize: Math.max(16, Math.min(28, parent.width / 18))
                icon: "eyes"
                text: qsTr("Guarda ancora")
                color: Theme.dirLeft
                onClicked: line.peekRequested()
            }
        }
    }
}
