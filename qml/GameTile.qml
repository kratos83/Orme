// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Giochi

// Un riquadro del menu: icona grande, titolo (va a capo se lungo) ed età.
Rectangle {
    id: tile

    property string title: ""
    property string age: ""
    property color  baseColor: Theme.dirUp
    property bool   locked: false
    property string iconKind: ""       // "path" = disegna le frecce
    property string emoji: ""          // altrimenti mostra questa emoji
    signal clicked()

    width: 196
    height: 196
    radius: 26
    color: locked ? "#EFE7D3" : baseColor
    opacity: locked ? 0.55 : 1

    scale: ma.pressed ? 0.94 : 1
    Behavior on scale { NumberAnimation { duration: 90 } }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        Item {   // icona
            width: parent.width
            height: 86

            Row {
                anchors.centerIn: parent
                spacing: 6
                visible: tile.iconKind === "path" && !tile.locked
                Arrow { width: 30; height: 30; direction: 3; color: "white" }
                Arrow { width: 30; height: 30; direction: 3; color: "white" }
                Arrow { width: 30; height: 30; direction: 1; color: "white" }
            }

            Text {
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                visible: tile.emoji !== "" && tile.iconKind !== "path" && !tile.locked
                text: tile.emoji
                fontSizeMode: Text.Fit
                font.pixelSize: 68
                minimumPixelSize: 20
            }

            Text {
                anchors.centerIn: parent
                visible: tile.locked
                text: "🔒"
                font.pixelSize: 52
            }
        }

        Text {   // titolo (va a capo, si rimpicciolisce se serve)
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: tile.title
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            fontSizeMode: Text.Fit
            font.pixelSize: 21
            minimumPixelSize: 12
            font.bold: true
            color: tile.locked ? Theme.text : "white"
        }

        Rectangle {   // targhetta età
            anchors.horizontalCenter: parent.horizontalCenter
            visible: tile.age !== "" && !tile.locked
            width: ageText.implicitWidth + 16
            height: 24
            radius: 12
            color: "#FFFFFF"
            opacity: 0.88
            Text {
                id: ageText
                anchors.centerIn: parent
                text: tile.age
                font.pixelSize: 13
                font.bold: true
                color: tile.baseColor
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: !tile.locked
        onClicked: tile.clicked()
    }
}
