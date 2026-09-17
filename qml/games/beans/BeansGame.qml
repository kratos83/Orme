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
        bottle.goHome()
    }

    function pourStep() {
        if (won) return
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

        // ===== rivolo colorato fra bottiglia e bicchiere, mentre si versa =====
        Rectangle {
            id: stream
            z: 1
            visible: g.pouring
            readonly property real ax: bottle.x + bottle.width / 2
            readonly property real ay: bottle.y + bottle.height * 0.30
            readonly property real bx: cup.x + cup.width / 2
            readonly property real by: cup.y + 12
            readonly property real dx: bx - ax
            readonly property real dy: by - ay
            width: Math.sqrt(dx * dx + dy * dy)
            height: 10
            radius: 5
            color: g.liquidColor
            x: ax
            y: ay - height / 2
            transformOrigin: Item.Left
            rotation: Math.atan2(dy, dx) * 180 / Math.PI
        }

        // ===== bicchiere (destra, fisso) - trapezio, largo sopra e stretto sotto =====
        Item {
            id: cup
            width: 130; height: 170
            anchors { right: parent.right; rightMargin: 56; bottom: parent.bottom; bottomMargin: 30 }

            readonly property real botW: width * 0.72
            readonly property real botLeftX: (width - botW) / 2
            readonly property real botRightX: botLeftX + botW

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

            MouseArea {
                id: dragArea
                anchors.fill: parent
                enabled: !g.won
                drag.target: bottle
                drag.minimumX: 0
                drag.maximumX: playArea.width - bottle.width
                drag.minimumY: 0
                drag.maximumY: playArea.height - bottle.height

                onReleased: bottle.goHome()
            }
        }

        Timer {
            interval: 90
            repeat: true
            running: g.pouring
            onTriggered: g.pourStep()
        }
    }

    readonly property bool pouring: dragArea.drag.active && bottle.overTarget && fromLevel > 0.001 && !won
}
