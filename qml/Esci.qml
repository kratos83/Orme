import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import Orme

Rectangle {
    id: root
    width: parent.width
    height: parent.height
    color: Theme.background
    signal exitRequested()
    // Layout che chiede conferma per uscire dall'applicazione.
    //Viene mostrato quando si preme il tasto back di Android o il tasto ESC di Windows/Linux.
    GridLayout {
        anchors.centerIn: parent
        width: Math.min(400, root.width - 40)
        rowSpacing: 20
        columns: 1
        rows: 4

        Image {
            width: 100
            height: 100
            Layout.alignment: Qt.AlignHCenter
            source: "qrc:/qt/qml/Orme/images/exit.png"
        }

        Text {
            text: qsTr("Vuoi uscire veramente?")
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 40
            color: Theme.text
        }

        Button {
            id: exitButton
            Layout.fillWidth: true
            height: 60
            icon.source: "qrc:/qt/qml/Orme/images/exit.png"
            icon.width: 32
            icon.height: 32
            text: qsTr("Esci")
            font.pixelSize: 30
            onClicked: Qt.exit(0)
        }

        Button {
            id: cancelButton
            Layout.fillWidth: true
            icon.source: "qrc:/qt/qml/Orme/images/annulla.png"
            icon.width: 32
            icon.height: 32
            height: 60
            text: qsTr("Annulla")
            font.pixelSize: 30
            onClicked: root.exitRequested()
        }
    }
    
}