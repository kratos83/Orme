// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Pulsante tondo colorato con un simbolo (o una lettera) al centro.
Rectangle {
    id: root
    property string icon: ""           // es. "ui/back"
    property string label: ""          // in alternativa all'icona
    signal clicked()

    width: 66; height: 66; radius: width / 2
    color: Theme.dirUp
    border.color: "white"
    border.width: 4
    scale: ma.pressed ? 0.9 : 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

    Candy { depth: 5 }
    AppIcon { anchors.centerIn: parent; name: root.icon; size: root.width * 0.52; visible: root.icon !== "" }
    Text {
        anchors.centerIn: parent
        text: root.label
        font.pixelSize: root.width * 0.55
        font.bold: true
        color: "white"
    }
    MouseArea { id: ma; anchors.fill: parent; onClicked: root.clicked() }
}
