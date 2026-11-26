// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Lo sfondo illustrato di menu e giochi, disegnato con sole forme (nessuna
// immagine a tutto schermo, per non sprecare RAM). I colori restano chiari
// perché i testi scuri si leggano bene.
//
//   theme: "prato" | "mare" | "tramonto" | "cameretta" | "scuola"
Item {
    id: root
    anchors.fill: parent
    clip: true

    property string theme: "prato"

    readonly property var themes: ({
        prato:     { sky: "#AEE0FF", low: "#FFF7E4", far: "#C6EA8E", near: "#A6D96A",
                     light: "sun-face",  deco: ["tree", "tulip", "blossom", "tree"] },
        mare:      { sky: "#A9E4FA", low: "#F1FCFF", far: "#86D3EA", near: "#F8DF9E",
                     light: "sun-face",  deco: ["shell", "island", "shell", "sailboat"] },
        tramonto:  { sky: "#C3BDF4", low: "#FFE6D2", far: "#CDB4EC", near: "#AF98DD",
                     light: "moon", deco: ["tree", "star", "star", "tree"] },
        scuola:    { sky: "#D9D2FF", low: "#FFF8EA", far: "#C9EBDD", near: "#A9DEC8",
                     light: "sun-face",  deco: ["books", "tulip", "tree", "pencil"] },
        cameretta: { sky: "#FFE3C9", low: "#FFF8EE", far: "", near: "#E9C593",
                     light: "",     deco: ["teddy", "package", "books", "ball"] }
    })
    readonly property var look: themes[theme] || themes.prato
    readonly property bool indoor: theme === "cameretta"
    // il renderer software ridisegna tutto a ogni fotogramma: nuvole ferme
    readonly property bool animated: GraphicsInfo.api !== GraphicsInfo.Software

    Rectangle {   // cielo (o parete)
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0;  color: root.look.sky }
            GradientStop { position: 0.75; color: root.look.low }
        }
    }

    Repeater {   // pois sulla parete della cameretta
        model: root.indoor ? 40 : 0
        Rectangle {
            required property int index
            width: 18; height: 18; radius: 9
            color: "#80FFFFFF"
            x: ((index % 8) + (Math.floor(index / 8) % 2) * 0.5) * root.width / 8 + 24
            y: Math.floor(index / 8) * root.height * 0.17 + 26
        }
    }

    AppIcon {   // sole o luna
        visible: root.look.light !== ""
        name: root.look.light
        size: 76
        x: root.width * 0.14 + 60; y: 12
    }

    component Cloud: Item {
        id: cloud
        property real startX: 0
        property int  period: 60000
        width: 150; height: 66
        x: startX
        Rectangle { y: 28; width: 150; height: 38; radius: 19; color: "white" }
        Rectangle { x: 24; y: 8;  width: 56; height: 56; radius: 28; color: "white" }
        Rectangle { x: 62; y: 0;  width: 64; height: 64; radius: 32; color: "white" }

        SequentialAnimation on x {
            running: root.animated && root.width > 0
            loops: Animation.Infinite
            NumberAnimation { from: cloud.startX; to: root.width; duration: cloud.period * Math.max(0.05, 1 - cloud.startX / Math.max(1, root.width)) }
            NumberAnimation { from: -cloud.width; to: cloud.startX; duration: cloud.period * Math.max(0.05, cloud.startX / Math.max(1, root.width)) }
        }
    }

    Item {
        visible: !root.indoor
        anchors.fill: parent
        Cloud { startX: root.width * 0.04; y: root.height * 0.19; period: 90000 }
        Cloud { startX: root.width * 0.68; y: root.height * 0.13; period: 120000; scale: 0.75 }
        Cloud { startX: root.width * 0.82; y: root.height * 0.42; period: 105000; scale: 0.9 }
    }

    // colline (cerchi molto grandi che spuntano dal basso)
    Rectangle {
        visible: !root.indoor
        width: root.width * 1.15; height: width; radius: width / 2
        x: -width * 0.45; y: root.height * 0.76
        color: root.indoor ? "transparent" : root.look.far
    }
    Rectangle {
        visible: !root.indoor
        width: root.width * 1.15; height: width; radius: width / 2
        x: root.width - width * 0.55; y: root.height * 0.80
        color: root.indoor ? "transparent" : root.look.far
    }
    Rectangle {
        visible: !root.indoor
        width: root.width * 2.4; height: width; radius: width / 2
        x: (root.width - width) / 2; y: root.height * 0.89
        color: root.look.near
    }

    Item {   // pavimento di legno della cameretta
        visible: root.indoor
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: root.height * 0.15
        Rectangle { anchors.fill: parent; color: root.look.near }
        Rectangle { width: parent.width; height: 10; color: "#CFA36B" }
        Repeater {
            model: root.indoor ? 9 : 0
            Rectangle {
                required property int index
                x: (index + 0.5) * root.width / 9; y: 10
                width: 3; height: parent.height - 10
                color: "#D9B17C"
            }
        }
    }

    Repeater {   // piccole decorazioni in basso, lontane dagli angoli
        model: root.look.deco
        AppIcon {
            required property string modelData
            required property int index
            name: modelData
            size: index % 2 ? 54 : 78
            x: root.width * [0.15, 0.24, 0.72, 0.81][index]
            y: root.height - height - [14, 6, 10, 20][index]
        }
    }
}
