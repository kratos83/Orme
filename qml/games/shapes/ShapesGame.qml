// Orme - Copyright (c) 2026 Angelo Scarnà
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Orme

// "Il percorso delle forme" - le sagome colorate sono sparse sul pavimento
// in 5 file; in alto una forma o un colore indica la regola. Il bambino deve
// "saltare" da una fila all'altra toccando solo la sagoma giusta, fila dopo
// fila, fino ad attraversare tutta l'aula. Riconoscere forme/colori e
// seguire una regola passo dopo passo.
MiniGame {
    id: g
    title: qsTr("Il percorso delle forme")
    age: qsTr("3-5 anni")
    levelCount: 8

    readonly property int rowCount: 5
    readonly property int colCount: 3
    readonly property var shapeKinds: ["circle", "square", "triangle", "star"]

    property string ruleType: "shape"   // "shape" oppure "color"
    property int    ruleShape: 0
    property int    ruleColor: 0
    property var    rows: []            // rowCount file, ognuna colCount caselle {kind, colorIndex, ok}
    property int    current: -1         // indice dell'ultima fila superata (-1 = non partito)

    SoundBank { id: snd }

    onBuildLevel: (i) => load(i)

    function randInt(n) { return Math.floor(Math.random() * n) }

    function load(i) {
        levelIndex = i
        won = false
        mistakes = 0
        current = -1
        ruleType = randInt(2) === 0 ? "shape" : "color"
        ruleShape = randInt(shapeKinds.length)
        ruleColor = randInt(Theme.playColors.length)

        var rs = []
        for (var r = 0; r < rowCount; r++) {
            var okSlot = randInt(colCount)
            var cells = []
            for (var c = 0; c < colCount; c++) {
                var kind, colorIndex
                if (c === okSlot) {
                    kind = ruleType === "shape" ? shapeKinds[ruleShape] : shapeKinds[randInt(shapeKinds.length)]
                    colorIndex = ruleType === "color" ? ruleColor : randInt(Theme.playColors.length)
                } else {
                    do {
                        kind = shapeKinds[randInt(shapeKinds.length)]
                        colorIndex = randInt(Theme.playColors.length)
                    } while ((ruleType === "shape" && kind === shapeKinds[ruleShape]) ||
                             (ruleType === "color" && colorIndex === ruleColor))
                }
                cells.push({ kind: kind, colorIndex: colorIndex, ok: c === okSlot })
            }
            rs.push(cells)
        }
        rows = rs
    }

    function okSlot(rowIndex) {
        var cells = rows[rowIndex]
        for (var c = 0; c < cells.length; c++)
            if (cells[c].ok) return c
        return 0
    }

    function tap(rowIndex, cellIndex, cellItem) {
        if (won || rowIndex !== current + 1) return
        var cell = rows[rowIndex][cellIndex]
        if (cell.ok) {
            snd.ok()
            current = rowIndex
            if (current === rowCount - 1) { snd.win(); win() }
        } else {
            snd.nope()
            wrong()
            if (cellItem) cellItem.shake()
        }
    }

    Component.onCompleted: g.buildLevel(0)

    // ---------- contenuto ----------
    Item {
        anchors.fill: parent

        // ===== la regola di oggi: una forma o un colore da cercare =====
        Rectangle {
            id: ruleCard
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 6 }
            width: 130; height: 130; radius: 26
            color: Theme.panel
            border.color: Theme.boardLine
            border.width: 3

            ShapeIcon {
                anchors.centerIn: parent
                width: 84; height: 84
                visible: g.ruleType === "shape"
                kind: g.shapeKinds[g.ruleShape]
                color: Theme.text
            }
            ShapeIcon {
                anchors.centerIn: parent
                width: 84; height: 84
                visible: g.ruleType === "color"
                kind: "circle"
                color: Theme.playColors[g.ruleColor]
            }
        }

        // ===== il campo con le file di sagome =====
        Item {
            id: field
            anchors { top: ruleCard.bottom; left: parent.left; right: parent.right; bottom: parent.bottom; margins: 8 }

            readonly property real laneH: height / (g.rowCount + 2)
            readonly property real slotW: width / g.colCount

            function slotCenterX(c) { return field.slotW * c + field.slotW / 2 }
            function rowCenterY(r)  { return field.height - field.laneH * (r + 1.5) }
            readonly property real startCenterY: field.height - field.laneH * 0.5
            readonly property real goalCenterY: field.laneH * 0.5

            // traguardo, in alto
            Text {
                x: field.width / 2 - width / 2
                y: field.goalCenterY - height / 2
                text: "🏁"
                font.pixelSize: field.laneH * 0.7
            }

            // partenza, in basso
            Text {
                x: field.width / 2 - width / 2
                y: field.startCenterY - height / 2
                text: "👣"
                font.pixelSize: field.laneH * 0.55
                opacity: 0.6
            }

            // il personaggio che salta di fila in fila
            Character {
                id: hero
                width: Math.min(field.laneH, field.slotW) * 0.8
                height: width
                x: (g.current < 0 ? field.width / 2 : field.slotCenterX(g.okSlot(g.current))) - width / 2
                y: (g.current < 0 ? field.startCenterY : field.rowCenterY(g.current)) - height / 2

                Behavior on x { NumberAnimation { duration: 380; easing.type: Easing.InOutQuad } }
                Behavior on y { NumberAnimation { duration: 380; easing.type: Easing.InOutQuad } }
            }

            Repeater {
                model: g.rows

                Item {
                    id: rowItem
                    required property var modelData
                    required property int index

                    Repeater {
                        model: rowItem.modelData

                        Rectangle {
                            id: pad
                            required property var modelData
                            required property int index

                            readonly property bool isActive: rowItem.index === g.current + 1
                            readonly property bool isDone: rowItem.index <= g.current

                            width: Math.min(field.laneH, field.slotW) * 0.86
                            height: width
                            radius: 18
                            x: field.slotCenterX(index) - width / 2
                            y: field.rowCenterY(rowItem.index) - height / 2
                            color: Theme.panel
                            border.color: isActive ? Theme.accent : Theme.boardLine
                            border.width: isActive ? 5 : 3
                            opacity: isDone ? 0.3 : (isActive ? 1 : 0.85)

                            scale: padMa.pressed && isActive ? 0.92 : 1
                            Behavior on scale { NumberAnimation { duration: 80 } }

                            function shake() { shakeAnim.restart() }
                            SequentialAnimation {
                                id: shakeAnim
                                NumberAnimation { target: pad; property: "rotation"; to: -12; duration: 55 }
                                NumberAnimation { target: pad; property: "rotation"; to:  12; duration: 55 }
                                NumberAnimation { target: pad; property: "rotation"; to:   0; duration: 55 }
                            }

                            ShapeIcon {
                                anchors.centerIn: parent
                                width: parent.width * 0.62; height: width
                                kind: pad.modelData.kind
                                color: Theme.playColors[pad.modelData.colorIndex]
                            }

                            MouseArea {
                                id: padMa
                                anchors.fill: parent
                                enabled: pad.isActive
                                onClicked: g.tap(rowItem.index, pad.index, pad)
                            }
                        }
                    }
                }
            }
        }
    }
}
