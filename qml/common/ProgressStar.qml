// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Una tappa dell'avanzamento: dischetto bianco che, quando è conquistato,
// si riempie con una stella che spunta con un saltino.
Rectangle {
    id: root
    property bool filled: false

    width: 40; height: 40; radius: 20
    color: filled ? "#FFF3C4" : "#E6FFFFFF"
    border.color: "#FFCA28"
    border.width: 3

    AppIcon {
        anchors.centerIn: parent
        name: "star"
        size: 32
        scale: root.filled ? 1.15 : 0
        Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }
    }
}
