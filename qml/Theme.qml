pragma Singleton
import QtQuick

// Colori e misure condivisi da tutti i giochi.
QtObject {
    // sfondo caldo, tinte pastello ad alto contrasto
    readonly property color background: "#FFF7E8"
    readonly property color panel:      "#FFFFFF"
    readonly property color boardLine:  "#E7D9BE"
    readonly property color boardFill:  "#FCEFD6"

    readonly property color accent:     "#4CAF50"  // verde "vai"
    readonly property color accentDark: "#3B8B3E"
    readonly property color danger:     "#EF5350"  // rosso "cestino"
    readonly property color text:       "#5D4037"

    // un colore per ogni direzione (Su, Giu, Sinistra, Destra)
    readonly property color dirUp:    "#42A5F5"
    readonly property color dirDown:  "#AB47BC"
    readonly property color dirLeft:  "#FFA726"
    readonly property color dirRight: "#26A69A"

    readonly property int touch:  92   // lato minimo di un bersaglio touch (px)
    readonly property int radius: 20

    // tavolozza allegra per forme, oggetti e caselle degli altri giochi
    readonly property var playColors: [
        "#EF5350",  // rosso
        "#42A5F5",  // blu
        "#FDD835",  // giallo
        "#66BB6A",  // verde
        "#AB47BC",  // viola
        "#FF7043"   // arancione
    ]

    function directionColor(dir) {
        switch (dir) {
        case 0: return dirUp;
        case 1: return dirDown;
        case 2: return dirLeft;
        case 3: return dirRight;
        }
        return accent;
    }
}
