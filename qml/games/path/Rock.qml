import QtQuick
import Orme

// Un ostacolo: una roccia.
Rectangle {
    Candy { depth: 4 }
    radius: width * 0.3
    color: "#9E9E9E"
    border.color: "#7C7C7C"
    border.width: 3
}
