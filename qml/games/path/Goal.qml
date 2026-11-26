import QtQuick
import Orme

// L'oggetto da raggiungere: cambia a ogni livello (il nome di un'icona).
Item {
    id: root
    property string kind: "apple"

    AppIcon {
        anchors.centerIn: parent
        name: root.kind
        size: Math.min(root.width, root.height) * 0.69
    }

    // pulsazione leggera per attirare lo sguardo del bambino
    SequentialAnimation on scale {
        running: true
        loops: Animation.Infinite
        NumberAnimation { from: 1.0;  to: 1.12; duration: 700; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1.12; to: 1.0;  duration: 700; easing.type: Easing.InOutSine }
    }
}
