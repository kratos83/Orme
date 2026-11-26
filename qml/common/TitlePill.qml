// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Targa bianca con il titolo (e un sottotitolo facoltativo): resta leggibile
// sopra qualsiasi sfondo. maxWidth limita la larghezza: il titolo si
// rimpicciolisce invece di finire sotto i pulsanti.
Rectangle {
    id: root
    property string title: ""
    property string subtitle: ""
    property int titleSize: 30
    property real maxWidth: 10000

    width: Math.min(maxWidth, Math.max(titleMetrics.advanceWidth, sub.implicitWidth) + 56)
    height: col.height + 14
    radius: Math.min(30, height / 2)
    color: "white"

    TextMetrics { id: titleMetrics; font: head.font; text: root.title }

    Candy { depth: 5 }
    Column {
        id: col
        anchors.centerIn: parent
        width: root.width - 32
        Text {
            id: head
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.title
            font.pixelSize: root.titleSize
            font.bold: true
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: 14
            color: Theme.title
        }
        Text {
            id: sub
            anchors.horizontalCenter: parent.horizontalCenter
            visible: text !== ""
            text: root.subtitle
            font.pixelSize: 17
            color: Theme.text
        }
    }
}
