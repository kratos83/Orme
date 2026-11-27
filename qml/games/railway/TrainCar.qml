// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// Un vagone o la locomotiva dei giochi con il treno.
// Il disegno e' largo 200 unita' e alto 140 (u = una unita' in px), con un
// margine attorno per tetto, ciminiera e ganci. Le ruote sono a parte
// perche' girano. Lo stesso componente serve per il treno, il vassoio e il
// modellino in miniatura.
Item {
    id: car
    property bool loco: false
    property color body: "red"
    property real spin: 0
    property bool smoking: false
    property string art: ""
    property string rider: ""       // animale al primo finestrino
    property string rider2: ""      // animale al secondo finestrino
    height: width * 0.7

    readonly property real u: width / 200
    readonly property string paint: {
        var names = ["red", "blue", "yellow", "green", "purple", "orange"]
        for (var i = 0; i < names.length; i++)
            if (Qt.colorEqual(car.body, Theme.playColors[i])) return names[i]
        return "grey"
    }

    Image {   // carrozzeria
        x: -12 * car.u; y: -30 * car.u
        width: 224 * car.u; height: 172 * car.u
        source: car.art + (car.loco ? "loco" : "wagon-" + car.paint) + ".png"
        mipmap: car.width < 90
    }

    // chi si affaccia: il macchinista orsetto o i due passeggeri
    AppIcon {
        visible: car.loco
        name: "bear"
        size: 40 * car.u
        x: 37 * car.u - width / 2; y: 45 * car.u - height / 2
    }
    AppIcon {
        visible: !car.loco && car.rider !== ""
        name: car.rider
        size: 46 * car.u
        x: 53 * car.u - width / 2; y: 53 * car.u - height / 2
    }
    AppIcon {
        visible: !car.loco && car.rider2 !== ""
        name: car.rider2
        size: 46 * car.u
        x: 145 * car.u - width / 2; y: 53 * car.u - height / 2
    }

    Repeater {   // ruote: [centro x, diametro], poggiano sul fondo
        model: car.loco ? [[34, 52], [88, 40], [131, 40], [167, 28]]
                        : [[30, 36], [64, 36], [134, 36], [168, 36]]
        Image {
            required property var modelData
            width: modelData[1] * car.u; height: width
            x: modelData[0] * car.u - width / 2
            y: car.height - height
            source: car.art + "wheel.png"
            rotation: car.spin
            mipmap: true
        }
    }

    // biella dorata della locomotiva: va su e giu' mentre le ruote girano
    Rectangle {
        visible: car.loco
        x: 34 * car.u + Math.cos(car.spin * Math.PI / 180) * 8 * car.u
        y: 117 * car.u + Math.sin(car.spin * Math.PI / 180) * 8 * car.u
        width: 97 * car.u; height: Math.max(2, 8 * car.u); radius: height / 2
        color: "#FFCA28"
        border.color: "#8D5F00"; border.width: Math.max(0.5, car.u)
    }

    // sbuffi di fumo dalla ciminiera
    Repeater {
        model: car.loco ? 4 : 0
        Image {
            id: puff
            required property int index
            width: 46 * car.u; height: width
            x: 153 * car.u - width / 2
            y: -34 * car.u
            source: car.art + "puff.png"
            opacity: 0
            SequentialAnimation {
                running: car.smoking
                loops: Animation.Infinite
                PauseAnimation { duration: puff.index * 260 }
                ParallelAnimation {
                    NumberAnimation { target: puff; property: "y"; from: -34 * car.u; to: -150 * car.u; duration: 1040 }
                    NumberAnimation { target: puff; property: "x"; from: 153 * car.u - puff.width / 2; to: 153 * car.u - puff.width / 2 - 70 * car.u; duration: 1040 }
                    NumberAnimation { target: puff; property: "scale"; from: 0.5; to: 2.0; duration: 1040 }
                    SequentialAnimation {
                        NumberAnimation { target: puff; property: "opacity"; to: 0.95; duration: 150 }
                        NumberAnimation { target: puff; property: "opacity"; to: 0; duration: 890 }
                    }
                }
            }
        }
    }
}
