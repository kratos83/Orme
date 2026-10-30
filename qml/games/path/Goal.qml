import QtQuick

// L'oggetto da raggiungere: cambia a ogni livello (una emoji).
Item {
    id: root
    property string kind: "🍎"

    Text {
        anchors.centerIn: parent
        text: root.kind
        font.pixelSize: Math.min(root.width, root.height) * 0.6
    }

    // pulsazione leggera per attirare lo sguardo del bambino
    SequentialAnimation on scale {
        running: true
        loops: Animation.Infinite
        NumberAnimation { from: 1.0;  to: 1.12; duration: 700; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1.12; to: 1.0;  duration: 700; easing.type: Easing.InOutSine }
    }
}
