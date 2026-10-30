import QtQuick
import QtQuick.Shapes

// Una freccia piena. direction: 0 Su, 1 Giu', 2 Sinistra, 3 Destra.
Item {
    id: root
    property int direction: 0
    property color color: "white"

    width: 40
    height: 40

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        rotation: {
            switch (root.direction) {
            case 0: return 0;      // su
            case 1: return 180;    // giu'
            case 2: return -90;    // sinistra
            case 3: return 90;     // destra
            }
            return 0;
        }

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"

            // sagoma di una freccia che punta in alto
            startX: root.width * 0.50; startY: root.height * 0.10
            PathLine { x: root.width * 0.90; y: root.height * 0.52 }
            PathLine { x: root.width * 0.66; y: root.height * 0.52 }
            PathLine { x: root.width * 0.66; y: root.height * 0.90 }
            PathLine { x: root.width * 0.34; y: root.height * 0.90 }
            PathLine { x: root.width * 0.34; y: root.height * 0.52 }
            PathLine { x: root.width * 0.10; y: root.height * 0.52 }
        }
    }
}
