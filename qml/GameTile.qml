// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Un riquadro del menu: icona grande, titolo (va a capo se lungo) ed età.
Rectangle {
    id: tile

    property string title: ""
    property string age: ""
    property color  baseColor: Theme.dirUp
    property bool   locked: false
    property string iconKind: ""       // "path" = disegna le frecce
    property string image: ""          // altrimenti mostra questa icona
    signal clicked()

    width: 196
    height: 196
    radius: 34
    color: locked ? "#EFE7D3" : baseColor
    gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.lighter(tile.color, 1.22) }
        GradientStop { position: 0.7; color: tile.color }
    }
    border.color: "white"
    border.width: 4
    opacity: locked ? 0.55 : 1

    // entrata "a saltello", un riquadro dopo l'altro
    property int order: 0
    property real pop: 0.6
    transform: Scale { origin.x: tile.width / 2; origin.y: tile.height / 2; xScale: tile.pop; yScale: tile.pop }
    SequentialAnimation on pop {
        PauseAnimation { duration: Math.min(tile.order, 18) * 30 }
        NumberAnimation { to: 1; duration: 320; easing.type: Easing.OutBack }
    }

    scale: ma.pressed ? 0.94 : 1
    Behavior on scale { NumberAnimation { duration: 90 } }

    Candy { depth: 7 }

    Column {
        anchors.fill: parent
        anchors.margins: 9
        spacing: 3

        Item {   // icona
            width: parent.width
            height: 96

            Rectangle {   // disco chiaro: fa risaltare la figura
                anchors.centerIn: parent
                width: 96; height: 96; radius: 48
                color: "#F5FFFFFF"
            }

            Row {
                anchors.centerIn: parent
                spacing: 2
                visible: tile.iconKind === "path" && !tile.locked
                Arrow { width: 26; height: 26; direction: 3; color: tile.baseColor }
                Arrow { width: 26; height: 26; direction: 3; color: tile.baseColor }
                Arrow { width: 26; height: 26; direction: 1; color: tile.baseColor }
            }

            AppIcon {
                anchors.centerIn: parent
                visible: tile.locked || tile.iconKind !== "path"
                name: tile.locked ? "lock" : tile.image
                size: 78
                scale: ma.pressed ? 1.18 : 1
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
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
            font.pixelSize: 22
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
