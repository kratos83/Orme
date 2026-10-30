import QtQuick
import QtQuick.Shapes
import Orme

MiniGame {
    id: g
    title: qsTr("Travasi e infilo")
    age: qsTr("3-4 anni")
    levelCount: 4

    readonly property var liquids: [
        Theme.dirUp,     // acqua
        Theme.dirLeft,   // succo d'arancia
        Theme.dirDown,   // succo d'uva
        "#FDD835"        // limonata
    ]
    readonly property color liquidColor: liquids[levelIndex % liquids.length]

    property real fromLevel: 1    // quanto e' piena la bottiglia (0-1)
    property real toLevel: 0      // quanto e' pieno il bicchiere (0-1)

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        fromLevel = 1
        toLevel = 0
        pourTicks = 0
        bottle.goHome()
    }

    property int pourTicks: 0

    function pourStep() {
        if (won) return
        pourTicks += 1
        if (pourTicks % 4 === 0) snd.tap()
        var delta = Math.min(0.10, fromLevel, 1 - toLevel)
        fromLevel -= delta
        toLevel += delta
        if (toLevel >= 0.999) {
            toLevel = 1
            fromLevel = 0
            snd.win()
            win()
        }
    }

    // ---------- contenuto ----------
    Item {
        id: playArea
        anchors.fill: parent

        // progresso: quanto e' pieno il bicchiere, a pallini
        Row {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 6 }
            spacing: 10
            Repeater {
                model: 5
                Rectangle {
                    required property int index
                    width: 16; height: 16; radius: 8
                    color: (g.toLevel * 5) > index + 0.01 ? g.liquidColor : Theme.boardLine
                }
            }
        }

        // ===== getto colorato dal collo della bottiglia al pelo del liquido =====
        Rectangle {
            id: stream
            z: 1
            readonly property real rad: tilt.rotation * Math.PI / 180
            // punta del collo (in alto nella bottiglia a riposo), ruotata con la bottiglia
            readonly property real tipX: bottle.x + bottle.width / 2 + 97 * Math.sin(rad)
            readonly property real tipY: bottle.y + 97 - 97 * Math.cos(rad)
            readonly property real surfaceY: cup.y + cup.height * (1 - g.toLevel)
            readonly property real sx: Math.max(cup.x + 14, Math.min(cup.x + cup.width - 14, tipX))
            visible: g.pouring && tilt.rotation > 25 && surfaceY > tipY
            x: sx - width / 2
            y: tipY
            height: Math.max(0, surfaceY - tipY)
            width: 10
            radius: 5
            color: g.liquidColor
            SequentialAnimation on width {
                running: stream.visible
                loops: Animation.Infinite
                NumberAnimation { to: 14; duration: 120 }
                NumberAnimation { to: 8; duration: 120 }
            }
        }

        // schizzi sul pelo del liquido mentre si versa
        Item {
            z: 2
            x: stream.sx
            y: stream.surfaceY
            visible: stream.visible
            Repeater {
                model: 4
                Rectangle {
                    id: drop
                    required property int index
                    width: 9; height: 9; radius: 5
                    color: g.liquidColor
                    x: 0; y: 0
                    SequentialAnimation {
                        running: stream.visible
                        loops: Animation.Infinite
                        PauseAnimation { duration: drop.index * 70 }
                        ParallelAnimation {
                            NumberAnimation { target: drop; property: "x"; from: 0; to: (drop.index % 2 ? 1 : -1) * (16 + drop.index * 7); duration: 300 }
                            SequentialAnimation {
                                NumberAnimation { target: drop; property: "y"; from: 0; to: -26 - drop.index * 4; duration: 150; easing.type: Easing.OutQuad }
                                NumberAnimation { target: drop; property: "y"; to: 0; duration: 150; easing.type: Easing.InQuad }
                            }
                        }
                    }
                }
            }
        }

        // ===== bicchiere (destra, fisso) - trapezio, largo sopra e stretto sotto =====
        Item {
            id: cup
            width: 130; height: 170
            anchors { right: parent.right; rightMargin: 56; bottom: parent.bottom; bottomMargin: 30 }

            readonly property real botW: width * 0.72
            readonly property real botLeftX: (width - botW) / 2
            readonly property real botRightX: botLeftX + botW

            transformOrigin: Item.Bottom
            SequentialAnimation {
                id: cupBounce
                NumberAnimation { target: cup; property: "scale"; to: 1.15; duration: 140; easing.type: Easing.OutQuad }
                NumberAnimation { target: cup; property: "scale"; to: 0.95; duration: 120 }
                NumberAnimation { target: cup; property: "scale"; to: 1.0; duration: 120 }
            }
            Connections {
                target: g
                function onWonChanged() { if (g.won) cupBounce.restart() }
            }

            // il vetro
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: "#55FFFFFF"
                    strokeColor: Theme.boardLine
                    strokeWidth: 5
                    joinStyle: ShapePath.RoundJoin
                    startX: 0; startY: 0
                    PathLine { x: cup.width; y: 0 }
                    PathLine { x: cup.botRightX; y: cup.height }
                    PathLine { x: cup.botLeftX; y: cup.height }
                    PathLine { x: 0; y: 0 }
                }
            }

            // il liquido dentro, che segue la stessa forma a trapezio
            Shape {
                id: cupLiquid
                anchors.fill: parent
                visible: g.toLevel > 0.001
                preferredRendererType: Shape.CurveRenderer

                readonly property real liqW: cup.botW + (cup.width - cup.botW) * g.toLevel
                readonly property real liqY: cup.height * (1 - g.toLevel)
                readonly property real liqLeftX: (cup.width - liqW) / 2
                readonly property real liqRightX: liqLeftX + liqW

                ShapePath {
                    fillColor: g.liquidColor
                    strokeColor: "transparent"
                    startX: cup.botLeftX; startY: cup.height
                    PathLine { x: cup.botRightX; y: cup.height }
                    PathLine { x: cupLiquid.liqRightX; y: cupLiquid.liqY }
                    PathLine { x: cupLiquid.liqLeftX; y: cupLiquid.liqY }
                    PathLine { x: cup.botLeftX; y: cup.height }
                }
            }

            // pelo del liquido: si increspa mentre ci si versa sopra
            Rectangle {
                visible: g.toLevel > 0.001
                x: cupLiquid.liqLeftX + 2
                y: cupLiquid.liqY - height / 2
                width: cupLiquid.liqW - 4
                height: 8
                radius: 4
                color: Qt.lighter(g.liquidColor, 1.3)
                SequentialAnimation on height {
                    running: g.pouring
                    loops: Animation.Infinite
                    NumberAnimation { to: 14; duration: 130 }
                    NumberAnimation { to: 6; duration: 130 }
                }
            }

            // festa quando e' pieno
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: -70
                text: "🎉"
                font.pixelSize: 60
                scale: g.won ? 1 : 0
                Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
            }
        }

        // ===== bottiglia (draggabile) =====
        Item {
            id: bottle
            width: 130; height: 194

            readonly property bool overTarget: bottle.x < cup.x + cup.width
                                                && bottle.x + bottle.width > cup.x
                                                && bottle.y < cup.y + cup.height
                                                && bottle.y + bottle.height > cup.y
            readonly property real homeX: 56
            readonly property real homeY: (playArea.height - height) / 2

            function goHome() { x = homeX; y = homeY }

            onHomeXChanged: if (!dragArea.drag.active) goHome()
            onHomeYChanged: if (!dragArea.drag.active) goHome()

            Behavior on x { enabled: !dragArea.drag.active; NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }
            Behavior on y { enabled: !dragArea.drag.active; NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }

            Component.onCompleted: goHome()

            // la bottiglia si inclina verso il bicchiere quando ci si trova sopra
            property real tiltTarget: g.pouring ? 55 : 0
            property real wob: 0
            Behavior on tiltTarget { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }

            // un tocco la fa dondolare (invito a trascinarla)
            SequentialAnimation {
                id: wobble
                NumberAnimation { target: bottle; property: "wob"; to: -10; duration: 90 }
                NumberAnimation { target: bottle; property: "wob"; to: 10; duration: 140 }
                NumberAnimation { target: bottle; property: "wob"; to: -6; duration: 110 }
                NumberAnimation { target: bottle; property: "wob"; to: 0; duration: 90 }
            }

            Item {
                id: tilt
                anchors.fill: parent
                rotation: bottle.tiltTarget + bottle.wob
                scale: dragArea.pressed ? 1.08 : 1

                // corpo della bottiglia
                Rectangle {
                    id: bottleBody
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 150
                    radius: 16
                    color: "#55FFFFFF"
                    border.color: Theme.boardLine
                    border.width: 5
                    clip: true

                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 4 }
                        height: (parent.height - 8) * g.fromLevel
                        radius: 10
                        color: g.liquidColor
                        Behavior on height { enabled: !g.pouring; NumberAnimation { duration: 200 } }
                    }
                }

                // collo della bottiglia
                Rectangle {
                    width: 40; height: 44
                    radius: 8
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: bottleBody.top }
                    color: "#55FFFFFF"
                    border.color: Theme.boardLine
                    border.width: 4
                }

            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                enabled: !g.won
                drag.target: bottle
                drag.minimumX: 0
                drag.maximumX: playArea.width - bottle.width
                drag.minimumY: 0
                drag.maximumY: playArea.height - bottle.height

                onPressed: snd.tap()
                onClicked: if (!drag.active) { wobble.restart() }
                onReleased: bottle.goHome()
            }
        }

        Timer {
            interval: 90
            repeat: true
            running: g.pouring && tilt.rotation > 30
            onTriggered: g.pourStep()
        }
    }

    readonly property bool pouring: dragArea.drag.active && bottle.overTarget && fromLevel > 0.001 && !won
}
