import QtQuick
import Orme

// La striscia dei comandi scelti. Toccando una freccia la si toglie.
// Durante l'esecuzione la freccia in corso viene evidenziata.
Rectangle {
    id: root
    property var engine

    radius: 20
    color: Theme.panel
    border.color: Theme.boardLine
    border.width: 3
    implicitHeight: Theme.touch + 26

    readonly property int active: engine ? engine.activeStep : -1
    readonly property bool editing: engine && engine.state === PathEngine.Editing

    Flickable {
        anchors.fill: parent
        anchors.margins: 13
        contentWidth: strip.width
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        clip: true

        Row {
            id: strip
            height: parent.height
            spacing: 10

            Repeater {
                model: root.engine ? root.engine.commands : []

                Rectangle {
                    width: Theme.touch
                    height: Theme.touch
                    radius: 16
                    color: Theme.directionColor(modelData)

                    border.width: index === root.active ? 5 : 0
                    border.color: "#FFEB3B"
                    scale: index === root.active ? 1.12 : 1
                    Behavior on scale { NumberAnimation { duration: 150 } }

                    Arrow {
                        anchors.centerIn: parent
                        width: parent.width * 0.6
                        height: parent.height * 0.6
                        direction: modelData
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.editing
                        onClicked: root.engine.removeCommand(index)
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.engine || root.engine.commands.length === 0
                text: qsTr("Tocca le frecce per costruire il percorso")
                color: Theme.text
                font.pixelSize: 22
            }
        }
    }
}
