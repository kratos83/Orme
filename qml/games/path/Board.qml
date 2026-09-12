import QtQuick
import Giochi

// Il tabellone: griglia, rocce, mela e personaggio.
// Riceve il motore come proprieta' `engine`.
Item {
    id: root
    property var engine

    readonly property int  cols: engine ? engine.columns : 1
    readonly property int  rowsN: engine ? engine.rows : 1
    readonly property real cell: Math.min(width / cols, height / rowsN)

    Rectangle {
        id: field
        width: root.cell * root.cols
        height: root.cell * root.rowsN
        anchors.centerIn: parent
        color: Theme.boardFill
        radius: 24
        border.color: Theme.boardLine
        border.width: 4
        clip: true

        // linee verticali
        Row {
            Repeater {
                model: root.cols
                Rectangle {
                    width: root.cell; height: field.height
                    color: "transparent"
                    border.color: Theme.boardLine
                    border.width: 1
                }
            }
        }
        // linee orizzontali
        Column {
            Repeater {
                model: root.rowsN
                Rectangle {
                    width: field.width; height: root.cell
                    color: "transparent"
                    border.color: Theme.boardLine
                    border.width: 1
                }
            }
        }

        // rocce
        Repeater {
            model: root.engine ? root.engine.obstacles : []
            Rock {
                width: root.cell * 0.8
                height: root.cell * 0.8
                x: modelData.column * root.cell + root.cell * 0.1
                y: modelData.row * root.cell + root.cell * 0.1
            }
        }

        // traguardo (oggetto diverso a ogni livello)
        Goal {
            kind: root.engine ? root.engine.goalKind : "🍎"
            width: root.cell
            height: root.cell
            x: (root.engine ? root.engine.goalColumn : 0) * root.cell
            y: (root.engine ? root.engine.goalRow : 0) * root.cell
        }

        // personaggio
        Character {
            id: hero
            width: root.cell
            height: root.cell
            x: (root.engine ? root.engine.playerColumn : 0) * root.cell
            y: (root.engine ? root.engine.playerRow : 0) * root.cell

            Behavior on x { NumberAnimation { duration: 420; easing.type: Easing.InOutQuad } }
            Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.InOutQuad } }
        }
    }

    // scossa quando il personaggio sbatte
    SequentialAnimation {
        id: shake
        NumberAnimation { target: hero; property: "rotation"; to: -14; duration: 55 }
        NumberAnimation { target: hero; property: "rotation"; to:  14; duration: 55 }
        NumberAnimation { target: hero; property: "rotation"; to: -10; duration: 55 }
        NumberAnimation { target: hero; property: "rotation"; to:   0; duration: 55 }
    }

    Connections {
        target: root.engine
        function onBumped() { shake.restart() }
    }
}
