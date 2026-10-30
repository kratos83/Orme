import QtQuick
import QtQuick.Shapes

// Una forma piena: cerchio, quadrato, triangolo o stella.
Item {
    id: root
    property string kind: "circle"   // circle | square | triangle | star
    property color  color: "white"

    Rectangle {
        anchors.fill: parent
        visible: root.kind === "circle"
        radius: width / 2
        color: root.color
    }

    Rectangle {
        anchors.fill: parent
        visible: root.kind === "square"
        radius: width * 0.12
        color: root.color
    }

    Shape {
        anchors.fill: parent
        visible: root.kind === "triangle"
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            startX: root.width * 0.50; startY: root.height * 0.06
            PathLine { x: root.width * 0.94; y: root.height * 0.92 }
            PathLine { x: root.width * 0.06; y: root.height * 0.92 }
            PathLine { x: root.width * 0.50; y: root.height * 0.06 }
        }
    }

    Shape {
        anchors.fill: parent
        visible: root.kind === "star"
        preferredRendererType: Shape.CurveRenderer

        // stella a 5 punte: 5 vertici esterni e 5 interni alternati
        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            startX: root.starPoint(0).x; startY: root.starPoint(0).y
            PathLine { x: root.starPoint(1).x; y: root.starPoint(1).y }
            PathLine { x: root.starPoint(2).x; y: root.starPoint(2).y }
            PathLine { x: root.starPoint(3).x; y: root.starPoint(3).y }
            PathLine { x: root.starPoint(4).x; y: root.starPoint(4).y }
            PathLine { x: root.starPoint(5).x; y: root.starPoint(5).y }
            PathLine { x: root.starPoint(6).x; y: root.starPoint(6).y }
            PathLine { x: root.starPoint(7).x; y: root.starPoint(7).y }
            PathLine { x: root.starPoint(8).x; y: root.starPoint(8).y }
            PathLine { x: root.starPoint(9).x; y: root.starPoint(9).y }
        }
    }

    function starPoint(i) {
        var cx = root.width * 0.5, cy = root.height * 0.5
        var rOuter = root.width * 0.5, rInner = root.width * 0.2
        var r = (i % 2 === 0) ? rOuter : rInner
        var a = (Math.PI / 5) * i - Math.PI / 2
        return Qt.point(cx + r * Math.cos(a), cy + r * Math.sin(a))
    }
}
