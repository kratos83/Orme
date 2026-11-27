// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Un segnale col suo palo: semaforo, STOP, divieto di accesso o direzione
// obbligatoria (disegnati da scripts/make_art.py su 120 x 300 unita').
Item {
    id: sign
    property string kind: "light"   // light | stop | noentry | straight
    property string lamp: "red"     // luce accesa del semaforo: red | green | ""
    height: width * 2.5

    readonly property real u: width / 120

    Image {
        anchors.fill: parent
        source: "qrc:/qt/qml/Orme/assets/art/sign-" + sign.kind + ".png"
        mipmap: sign.width < 90
    }

    // la luce accesa, con il suo alone
    Rectangle {
        visible: sign.kind === "light" && sign.lamp !== ""
        width: 58 * sign.u; height: width; radius: width / 2
        x: 60 * sign.u - width / 2
        y: (sign.lamp === "red" ? 42 : 150) * sign.u - height / 2
        color: sign.lamp === "red" ? "#55FF1744" : "#5500E676"
        Rectangle {
            anchors.centerIn: parent
            width: 42 * sign.u; height: width; radius: width / 2
            color: sign.lamp === "red" ? "#FF1F1F" : "#17E86B"
            Rectangle {
                x: parent.width * 0.2; y: parent.height * 0.16
                width: parent.width * 0.3; height: width; radius: width / 2
                color: "#B3FFFFFF"
            }
        }
    }

    Text {
        visible: sign.kind === "stop"
        x: 0; y: 66 * sign.u - height / 2
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: "STOP"
        color: "white"
        font.bold: true
        font.pixelSize: Math.max(1, 34 * sign.u)
    }
}
