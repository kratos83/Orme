import QtQuick

// Il personaggio: un robottino simpatico. Disegnato con forme, niente immagini.
Item {
    id: root

    Rectangle {                       // corpo
        id: body
        anchors.fill: parent
        anchors.margins: parent.width * 0.14
        radius: width * 0.32
        color: "#FF7043"

        Rectangle {                   // visore
            anchors.centerIn: parent
            width: parent.width * 0.68
            height: parent.height * 0.46
            radius: height * 0.4
            color: "#FFF3E0"

            Row {
                anchors.centerIn: parent
                spacing: parent.width * 0.22
                Repeater {
                    model: 2
                    Rectangle {
                        width: body.width * 0.14
                        height: width
                        radius: width / 2
                        color: "#3E2723"
                    }
                }
            }
        }
    }

    Rectangle {                       // antenna
        width: parent.width * 0.06
        height: parent.height * 0.14
        color: "#FF7043"
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.03

        Rectangle {
            width: parent.width * 3.2
            height: width
            radius: width / 2
            color: "#FFCA28"
            anchors.horizontalCenter: parent.horizontalCenter
            y: -height * 0.7
        }
    }
}
