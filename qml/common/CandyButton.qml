// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Grande pulsante a pillola con icona e scritta.
Rectangle {
    id: root
    property string text: ""
    property string icon: ""
    property int textSize: 32
    signal clicked()

    implicitWidth: row.implicitWidth + 56
    implicitHeight: 80
    radius: height / 2
    color: Theme.accent
    border.color: "white"
    border.width: 4
    scale: ma.pressed ? 0.93 : 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

    Candy {}
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 12
        AppIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            name: root.icon
            size: root.textSize * 1.25
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            font.pixelSize: root.textSize
            font.bold: true
            color: "white"
        }
    }
    MouseArea { id: ma; anchors.fill: parent; onClicked: root.clicked() }
}
