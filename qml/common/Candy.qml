// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

// Effetto "caramella": si mette come PRIMO figlio di un Rectangle e gli dà
// spessore (bordo inferiore in rilievo) e un riflesso lucido.
//
//   Rectangle { width: 120; height: 120; radius: 24; color: "orange"
//       Candy {}
//       Text { ... }
//   }
//
// Usa solo rettangoli (niente ombre sfocate o shader): costa pochissima RAM e
// funziona anche con il renderer software.
Item {
    id: candy
    anchors.fill: parent

    property int depth: 6            // spessore del rilievo in px

    readonly property var  face: parent
    readonly property color base: face.color
    readonly property bool solid: base.a > 0.5
    readonly property bool pale: 0.299 * base.r + 0.587 * base.g + 0.114 * base.b > 0.82
    // cerchio vero: le "pillole" larghe usano il riflesso rettangolare
    readonly property bool round: face.radius >= Math.min(width, height) / 2 - 1
                                  && Math.max(width, height) < Math.min(width, height) * 1.25

    Rectangle {   // rilievo: disegnato DIETRO il rettangolo
        parent: candy.face
        z: -1
        visible: candy.solid
        y: candy.depth
        width: candy.face.width
        height: candy.face.height
        radius: candy.face.radius
        color: candy.pale ? "#DCC391" : Qt.darker(candy.base, 1.4)
    }

    Rectangle {   // riflesso sui rettangoli colorati
        visible: candy.solid && !candy.pale && !candy.round
        readonly property real inset: candy.face.border.width + 3
        x: inset; y: inset
        width: candy.width - inset * 2
        height: candy.height * 0.38
        radius: Math.max(4, candy.face.radius - inset)
        color: "#38FFFFFF"
    }

    Rectangle {   // riflesso a "pallina" su cerchi
        visible: candy.solid && !candy.pale && candy.round
        x: candy.width * 0.16; y: candy.height * 0.13
        width: candy.width * 0.34; height: candy.height * 0.2
        radius: height / 2
        rotation: -34
        color: "#70FFFFFF"
    }
}
