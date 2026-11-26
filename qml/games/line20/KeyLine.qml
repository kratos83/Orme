// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// La "linea dei tasti" fino a 20: due decine divise in cinquine, come quattro
// mani. Un tasto alzato mostra la sua pallina, cosi' la quantita' si legge a
// colpo d'occhio, senza contare uno per uno.
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

    // ---------- misure: tutto in "u", la larghezza di un tasto ----------
    readonly property real rowUnits: 3.75      // tasto + alzata + manina
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

        // una manina sotto ogni cinquina, accesa quando la cinquina e' completa
        Repeater {
            model: 4
            AppIcon {
                required property int index
                readonly property int first: index * 5 + 1
                readonly property bool full: line.litFrom <= first && line.litTo >= first + 4
                name: "hand"
                size: line.u * 1.05
                x: (line.offsetU((index * 5) % line.perRow) + 2.7) * line.u - width / 2
                y: (2.72 + Math.floor(index * 5 / line.perRow) * line.rowUnits) * line.u
                opacity: full ? 1 : 0.35
                scale: full ? 1.12 : 1
                mirror: index % 2 === 1
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
