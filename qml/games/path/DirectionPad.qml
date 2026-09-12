import QtQuick
import Giochi

// I quattro tasti-freccia disposti a croce. Emette moved(direction).
Item {
    id: root
    signal moved(int direction)
    property bool active: true

    property real btn: Theme.touch
    property real gap: 10

    implicitWidth:  btn * 3 + gap * 2
    implicitHeight: btn * 3 + gap * 2

    component PadButton: Rectangle {
        id: pb
        property int dir: 0
        width: root.btn
        height: root.btn
        radius: 18
        color: Theme.directionColor(dir)
        opacity: root.active ? (pma.pressed ? 0.7 : 1) : 0.3
        scale: pma.pressed && root.active ? 0.9 : 1
        Behavior on scale { NumberAnimation { duration: 80 } }

        Arrow {
            anchors.centerIn: parent
            width: parent.width * 0.6
            height: parent.height * 0.6
            direction: pb.dir
        }

        MouseArea {
            id: pma
            anchors.fill: parent
            enabled: root.active
            onClicked: root.moved(pb.dir)
        }
    }

    PadButton { dir: 0; x: root.btn + root.gap;         y: 0 }                          // su
    PadButton { dir: 2; x: 0;                           y: root.btn + root.gap }        // sinistra
    PadButton { dir: 3; x: (root.btn + root.gap) * 2;   y: root.btn + root.gap }        // destra
    PadButton { dir: 1; x: root.btn + root.gap;         y: (root.btn + root.gap) * 2 }  // giu'
}
