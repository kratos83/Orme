// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Tastierino numerico touch (0-9, cancella, conferma) usato dai giochi di
// matematica della Primaria per scrivere un numero come risposta.
Grid {
    id: pad
    columns: 3
    rowSpacing: 12
    columnSpacing: 12
    // "enabled" è già una proprietà di Item: la si può impostare da fuori
    // (NumberPad { enabled: false }) per disattivare temporaneamente il tastierino.

    signal keyPressed(string key)
    signal backspacePressed()
    signal enterPressed()

    component PadBtn: Rectangle {
        id: btn
        property alias glyph: t.text
        property color bg: Theme.panel
        signal clicked()
        width: 84; height: 66
        radius: 16
        color: bg
        border.color: Theme.boardLine
        border.width: 3
        opacity: pad.enabled ? 1 : 0.5
        scale: ma.pressed && pad.enabled ? 0.92 : 1
        Behavior on scale { NumberAnimation { duration: 80 } }
        Text { id: t; anchors.centerIn: parent; font.pixelSize: 28; font.bold: true; color: Theme.text }
        MouseArea { id: ma; anchors.fill: parent; enabled: pad.enabled; onClicked: btn.clicked() }
    }

    Repeater {
        model: ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
        PadBtn {
            required property string modelData
            glyph: modelData
            onClicked: pad.keyPressed(modelData)
        }
    }

    PadBtn {
        glyph: "⌫"
        bg: Theme.dirLeft
        onClicked: pad.backspacePressed()
    }
    PadBtn {
        glyph: "0"
        onClicked: pad.keyPressed("0")
    }
    PadBtn {
        glyph: "✓"
        bg: Theme.accent
        onClicked: pad.enterPressed()
    }
}
