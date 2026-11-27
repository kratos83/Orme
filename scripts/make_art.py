#!/usr/bin/env python3
# Orme - Copyright (c) 2026 Angelo Scarnà
# SPDX-License-Identifier: GPL-3.0-or-later
"""Disegna le illustrazioni originali dell'app (SVG scritti qui sotto) e le
converte in PNG in assets/art/. Richiede rsvg-convert.

    python3 scripts/make_art.py

Contiene: treno (locomotiva, vagoni, ruote, sbuffo), scenario del trenino
(stazione, case, alberi), segnali (semaforo, stop, divieto di accesso),
bottiglia con i suoi liquidi e le conchiglie delle tabelline. Le figure sono PNG piccole: costano poca RAM.
"""
import pathlib
import subprocess
import sys

OUT = pathlib.Path(__file__).resolve().parent.parent / "assets" / "art"

INK = "#4A2C2A"   # contorno comune, marrone scuro morbido


def lg(i, *stops, h=False):
    """gradiente lineare verticale (o orizzontale con h=True)"""
    xy = 'x1="0" y1="0" x2="1" y2="0"' if h else 'x1="0" y1="0" x2="0" y2="1"'
    body = "".join('<stop offset="%s" stop-color="%s"/>' % s for s in stops)
    return '<linearGradient id="%s" %s>%s</linearGradient>' % (i, xy, body)


def rect(x, y, w, h, r, fill, stroke=None, sw=3, extra=""):
    s = ' stroke="%s" stroke-width="%s"' % (stroke, sw) if stroke else ""
    return '<rect x="%s" y="%s" width="%s" height="%s" rx="%s" fill="%s"%s %s/>' % (
        x, y, w, h, r, fill, s, extra)


def circle(cx, cy, r, fill, stroke=None, sw=3, extra=""):
    s = ' stroke="%s" stroke-width="%s"' % (stroke, sw) if stroke else ""
    return '<circle cx="%s" cy="%s" r="%s" fill="%s"%s %s/>' % (cx, cy, r, fill, s, extra)


def path(d, fill="none", stroke=None, sw=3, extra=""):
    s = ' stroke="%s" stroke-width="%s"' % (stroke, sw) if stroke else ""
    return ('<path d="%s" fill="%s"%s stroke-linejoin="round" stroke-linecap="round" %s/>'
            % (d, fill, s, extra))


def save(name, viewbox, width, defs, body):
    x, y, w, h = viewbox
    height = round(width * h / w)
    svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" '
           'viewBox="%s %s %s %s"><defs>%s</defs>%s</svg>'
           % (width, height, x, y, w, h, defs, "".join(body)))
    subprocess.run(["rsvg-convert", "-o", str(OUT / (name + ".png"))],
                   input=svg.encode(), check=True)


# ====================== TRENO ======================
# Coordinate: il vagone e' largo 200 e alto 140 (il fondo e' dove poggiano le
# ruote). L'immagine ha un margine: viewBox -12 -30 224 172 (vedi Car nel QML).
CAR_BOX = (-12, -30, 224, 172)
CAR_PX = 448

# colore -> (chiaro, base, scuro)
PAINT = {
    "red":    ("#FF8A80", "#EF4444", "#A61B1B"),
    "blue":   ("#90CAF9", "#3B9BEF", "#1561A8"),
    "yellow": ("#FFF3A0", "#FDD22F", "#C58A00"),
    "green":  ("#A5E6A9", "#54BB5C", "#27792F"),
    "purple": ("#DDA6EA", "#A94BC0", "#6B1F80"),
    "orange": ("#FFC1A1", "#FF7840", "#BE4310"),
    "grey":   ("#ECEFF1", "#CFD8DC", "#90A4AE"),
}

GOLD = lg("gold", ("0", "#FFF3B0"), ("0.45", "#FFCE3A"), ("1", "#C98A00"))
METAL = lg("metal", ("0", "#B8C7CF"), ("0.5", "#5E7480"), ("1", "#2E3F48"))
GLASS = lg("glass", ("0", "#FFFFFF"), ("0.4", "#CDEFFF"), ("1", "#8FD0F2"))


def wagon(name):
    light, base, dark = PAINT[name]
    defs = (GOLD + METAL + GLASS
            + lg("body", ("0", light), ("0.35", base), ("1", dark))
            + lg("roof", ("0", base), ("1", dark)))
    b = []
    # ganci e respingenti
    b.append(rect(188, 76, 22, 9, 3, "url(#metal)", "#263238", 2))
    b.append(circle(209, 80, 7, "url(#gold)", "#8D5F00", 2))
    b.append(rect(-9, 66, 13, 22, 4, "url(#metal)", "#263238", 2))
    # carrello
    b.append(rect(4, 92, 190, 17, 7, "url(#metal)", "#1F2D34", 3))
    for x in (14, 118):
        b.append(rect(x, 104, 66, 14, 6, "#37474F", "#1F2D34", 2))
    # cassa
    b.append(rect(2, 8, 194, 90, 20, "url(#body)", dark, 4))
    # tetto bombato sporgente
    b.append(path("M -4 22 Q -2 -6 40 -8 L 158 -8 Q 200 -6 202 22 Q 100 8 -4 22 Z",
                  "url(#roof)", dark, 4))
    b.append(path("M 14 8 Q 100 -6 184 8", "none", "#FFFFFF", 5, 'opacity="0.45"'))
    # tre comignoli di aerazione
    for x in (46, 91, 136):
        b.append(rect(x, -16, 18, 10, 4, "url(#gold)", "#8D5F00", 2))
    # due finestroni (ci si affacciano i passeggeri)
    for x in (18, 110):
        b.append(rect(x - 4, 22, 78, 56, 16, "url(#gold)", "#8D5F00", 2))
        b.append(rect(x, 26, 70, 48, 12, "url(#glass)", dark, 3))
        b.append(path("M %d 34 L %d 62" % (x + 59, x + 47), "none", "#FFFFFF", 6, 'opacity="0.75"'))
    # fascia dorata e bulloni
    b.append(rect(6, 83, 186, 9, 4, "url(#gold)", "#8D5F00", 1.5))
    for x in (16, 52, 99, 146, 182):
        b.append(circle(x, 87.5, 2.2, "#8D5F00"))
    # riflesso sulla fiancata
    b.append(rect(9, 24, 6, 52, 3, "#FFFFFF", extra='opacity="0.4"'))
    if name == "grey":   # sagoma per le caselle vuote
        b = ['<g opacity="0.85">'] + b + ['</g>']
    save("wagon-" + name, CAR_BOX, CAR_PX, defs, b)


def loco(name="red", out="loco"):
    light, base, dark = PAINT[name]
    defs = (GOLD + METAL + GLASS
            + lg("body", ("0", light), ("0.4", base), ("1", dark))
            + lg("boiler", ("0", dark), ("0.18", light), ("0.45", base), ("1", dark))
            + lg("cab", ("0", light), ("0.3", base), ("1", dark))
            + lg("roof", ("0", "#6D7F8A"), ("1", "#263238"))
            + lg("face", ("0", "#FFF6E0"), ("1", "#FFD9A0")))
    b = []
    # telaio e predellino
    b.append(rect(-6, 90, 200, 17, 7, "url(#metal)", "#1F2D34", 3))
    # cacciapietre a barre
    b.append(path("M 186 90 L 209 126 L 176 126 L 176 96 Z", "url(#gold)", "#8D5F00", 3))
    for x in (183, 191, 199):
        b.append(path("M %d 101 L %d 122" % (x - 3, x + 1), "none", "#8D5F00", 2.5))
    # ciminiera svasata
    b.append(path("M 140 30 L 144 4 L 162 4 L 166 30 Z", "url(#metal)", "#1F2D34", 3))
    b.append(path("M 130 -12 Q 153 -20 176 -12 L 168 6 Q 153 10 138 6 Z", "url(#roof)", "#1F2D34", 3))
    b.append(rect(131, -17, 44, 9, 4.5, "url(#gold)", "#8D5F00", 2))
    # duomo del vapore e campana
    b.append(path("M 96 30 Q 96 6 112 6 Q 128 6 128 30 Z", "url(#gold)", "#8D5F00", 3))
    b.append(circle(112, 4, 5, "url(#gold)", "#8D5F00", 2))
    # caldaia
    b.append(rect(66, 24, 112, 70, 24, "url(#boiler)", dark, 4))
    for x in (92, 132):
        b.append(rect(x, 24, 10, 70, 3, "url(#gold)", "#8D5F00", 1.5))
    # muso tondo con il visetto
    b.append(circle(172, 59, 35, "url(#gold)", "#8D5F00", 3))
    b.append(circle(172, 59, 28, "url(#face)", "#C9822E", 2))
    for x in (161, 184):
        b.append(circle(x, 51, 7.5, "#FFFFFF", INK, 1.5))
        b.append(circle(x + 1.5, 52, 4.6, INK))
        b.append(circle(x + 3.2, 49.8, 1.8, "#FFFFFF"))
    b.append(path("M 159 68 Q 173 84 187 68 Z", "#8E2430", INK, 2.5))
    b.append(path("M 166 75 Q 173 71 180 75", "none", "#FF8A8A", 3.5))
    for x in (153, 192):
        b.append('<ellipse cx="%d" cy="64" rx="5.5" ry="3.5" fill="#FF7F7F" opacity="0.65"/>' % x)
    # fanale sopra il muso
    b.append(circle(188, 22, 11, "url(#gold)", "#8D5F00", 3))
    b.append(circle(188, 22, 6.5, "#FFF9C4"))
    # cabina
    b.append(rect(-2, 6, 78, 90, 12, "url(#cab)", dark, 4))
    b.append(rect(7, 15, 60, 54, 16, "url(#gold)", "#8D5F00", 2))
    b.append(rect(11, 19, 52, 46, 12, "url(#glass)", dark, 3))
    b.append(path("M 56 27 L 46 55", "none", "#FFFFFF", 5, 'opacity="0.75"'))
    # targhetta con stella
    b.append(rect(17, 74, 40, 14, 7, "url(#gold)", "#8D5F00", 2))
    b.append(path("M37 75.5 l2.2 4 4.6.6 -3.4 3.1 .9 4.5 -4.3-2.3 -4.3 2.3 .9-4.5 -3.4-3.1 4.6-.6z", "#FFFFFF"))
    # tetto della cabina
    b.append(path("M -12 14 Q -10 -14 22 -15 L 56 -15 Q 86 -14 88 14 Q 38 0 -12 14 Z", "url(#roof)", "#1F2D34", 4))
    b.append(path("M 2 1 Q 38 -11 74 1", "none", "#FFFFFF", 4, 'opacity="0.4"'))
    if name == "grey":
        b = ['<g opacity="0.85">'] + b + ['</g>']
    save(out, CAR_BOX, CAR_PX, defs, b)


def wheel(name, tyre, rim, spoke):
    defs = (lg("tyre", ("0", rim), ("1", tyre)) + GOLD)
    b = [circle(50, 50, 47, "url(#tyre)", "#17232A", 5),
         circle(50, 50, 34, spoke, "#17232A", 3)]
    for a in range(0, 360, 45):   # raggi
        b.append('<rect x="45.5" y="17" width="9" height="30" rx="4" fill="url(#gold)" '
                 'stroke="#8D5F00" stroke-width="1.5" transform="rotate(%d 50 50)"/>' % a)
    b.append(circle(50, 50, 13, "url(#gold)", "#8D5F00", 3))
    b.append(circle(46, 46, 4, "#FFFFFF", extra='opacity="0.8"'))
    save(name, (0, 0, 100, 100), 128, defs, b)


def puff():
    defs = ('<radialGradient id="p" cx="0.4" cy="0.35" r="0.65">'
            '<stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#D5E3EC"/>'
            '</radialGradient>')
    b = [circle(x, y, r, "url(#p)") for x, y, r in
         ((38, 62, 26), (66, 62, 24), (34, 40, 20), (58, 34, 26), (74, 46, 17), (52, 55, 24))]
    save("puff", (0, 0, 100, 100), 128, defs, b)


# ====================== SCENARIO DEL TRENINO ======================
def house(name, wall, wall_d, roof, roof_d):
    defs = (lg("w", ("0", wall), ("1", wall_d)) + lg("r", ("0", roof), ("1", roof_d)) + GLASS
            + lg("door", ("0", "#B9835A"), ("1", "#7B4F30")))
    b = []
    b.append(rect(142, 24, 24, 52, 4, "url(#r)", roof_d, 3))       # comignolo
    b.append(rect(138, 18, 32, 12, 4, "#8D6E63", INK, 2.5))
    b.append(rect(22, 84, 156, 104, 10, "url(#w)", wall_d, 4))     # muro
    b.append(path("M 6 94 L 92 20 Q 100 13 108 20 L 194 94 Q 197 103 186 102 L 14 102 Q 3 103 6 94 Z",
                  "url(#r)", roof_d, 4))
    for y, x0, x1 in ((48, 66, 134), (68, 43, 157), (86, 24, 176)):   # file di tegole
        n = int((x1 - x0) // 22)
        d = "M %d %d" % (x0, y) + "".join(" q 11 11 22 0" for _ in range(n))
        b.append(path(d, "none", roof_d, 3, 'opacity="0.7"'))
    b.append(circle(100, 66, 15, "url(#glass)", "#FFFFFF", 5))      # oblò
    b.append(path("M 100 52 V 80 M 86 66 H 114", "none", "#FFFFFF", 3))
    b.append(path("M 82 188 V 148 Q 82 126 100 126 Q 118 126 118 148 V 188 Z", "url(#door)", INK, 3.5))
    b.append(circle(111, 160, 3.5, "#FFD54F"))
    for x in (36, 130):                                             # finestre
        b.append(rect(x, 116, 36, 34, 8, "url(#glass)", "#FFFFFF", 5))
        b.append(path("M %d 117 V 149 M %d 133 H %d" % (x + 18, x + 2, x + 34), "none", "#FFFFFF", 3))
        b.append(rect(x - 5, 151, 46, 11, 4, "#8D5F3C", INK, 2))    # fioriera
        for k, c in enumerate(("#FF5C8D", "#FFD43B", "#FF5C8D", "#B96BE0")):
            b.append(circle(x + 2 + k * 11, 149, 5.5, c, "#FFFFFF", 1.5))
    b.append(rect(14, 184, 172, 12, 5, "#B7A99F", INK, 2.5))        # zoccolo
    save(name, (0, 0, 200, 200), 256, defs, b)


def tree_round(name, light, base, dark):
    defs = ('<radialGradient id="l" cx="0.38" cy="0.3" r="0.75"><stop offset="0" stop-color="%s"/>'
            '<stop offset="0.6" stop-color="%s"/><stop offset="1" stop-color="%s"/></radialGradient>'
            % (light, base, dark)) + lg("t", ("0", "#7B4F30"), ("0.4", "#B9835A"), ("1", "#6B4226"), h=True)
    b = [path("M 62 198 Q 70 170 68 120 L 92 120 Q 90 170 98 198 Z", "url(#t)", "#5A3820", 3)]
    for x, y, r in ((45, 105, 34), (115, 105, 34), (80, 116, 36), (50, 66, 36), (110, 66, 36), (80, 46, 42), (80, 84, 44)):
        b.append(circle(x, y, r, "url(#l)"))
    for x, y in ((46, 78), (108, 98), (84, 34), (118, 62), (66, 112)):
        b.append(circle(x, y, 7, "#FF5252", "#B71C1C", 2))
        b.append(circle(x - 2, y - 2, 2, "#FFFFFF", extra='opacity="0.8"'))
    save(name, (0, 0, 160, 200), 192, defs, b)


def tree_pine(name):
    defs = (lg("l", ("0", "#7ED488"), ("1", "#1F7A3A"))
            + lg("t", ("0", "#7B4F30"), ("0.4", "#B9835A"), ("1", "#6B4226"), h=True))
    b = [rect(68, 150, 24, 48, 5, "url(#t)", "#5A3820", 3)]
    for d in ("M 12 164 Q 50 128 62 108 L 98 108 Q 110 128 148 164 Q 80 184 12 164 Z",
              "M 24 122 Q 56 90 66 66 L 94 66 Q 104 90 136 122 Q 80 140 24 122 Z",
              "M 38 80 Q 66 50 80 10 Q 94 50 122 80 Q 80 96 38 80 Z"):
        b.append(path(d, "url(#l)", "#1B6531", 3.5))
    save(name, (0, 0, 160, 200), 192, defs, b)


def station():
    """Edificio della stazione, largo 260 e alto 161 (rapporto 0.62 come nel
    QML). Le porte stanno a x = 12%, 42%, 72% (larghe 16%), dal 70% in giu'."""
    W, H = 520, 322
    defs = (GOLD + GLASS + lg("w", ("0", "#FFF0D2"), ("1", "#FFCF8E"))
            + lg("r", ("0", "#FF7B6B"), ("1", "#B92B27"))
            + lg("s", ("0", "#42A5F5"), ("1", "#1259A8"))
            + lg("door", ("0", "#C58B5C"), ("1", "#7B4F30")))
    b = []
    b.append(rect(8, 130, 504, 188, 14, "url(#w)", "#B5793C", 5))
    for y in (156, 292):
        b.append(path("M 12 %d H 508" % y, "none", "#E9AF6B", 4, 'opacity="0.7"'))
    # tetto con tegole
    b.append(path("M -2 138 L 46 76 Q 52 68 64 68 L 456 68 Q 468 68 474 76 L 522 138 Z", "url(#r)", "#8E1F1C", 5))
    for y, x0, n in ((92, 52, 13), (112, 36, 14), (132, 18, 15)):
        d = "M %d %d" % (x0, y) + "".join(" q 16 14 32 0" for _ in range(n))
        b.append(path(d, "none", "#8E1F1C", 4, 'opacity="0.55"'))
    # torretta con orologio
    b.append(rect(208, 34, 104, 110, 10, "url(#w)", "#B5793C", 5))
    b.append(path("M 194 42 L 260 0 L 326 42 Z", "url(#r)", "#8E1F1C", 5))
    b.append(circle(260, 86, 34, "url(#gold)", "#8D5F00", 3))
    b.append(circle(260, 86, 26, "#FFFFFF", INK, 3))
    b.append(path("M 260 66 V 86 L 276 94", "none", INK, 5))
    # insegna (la scritta la mette il QML)
    b.append(rect(104, 142, 312, 58, 18, "url(#gold)", "#8D5F00", 3))
    b.append(rect(112, 149, 296, 44, 13, "url(#s)", "#0D4580", 3))
    # finestre laterali
    for x in (38, 430):
        b.append(rect(x, 154, 52, 54, 22, "url(#glass)", "#FFFFFF", 7))
        b.append(path("M %d 158 V 204 M %d 183 H %d" % (x + 26, x + 5, x + 47), "none", "#FFFFFF", 4))
    # tre porte ad arco
    for k in range(3):
        x = W * (0.12 + k * 0.3)
        w = W * 0.16
        top = H * 0.68
        d = "M %f 314 V %f Q %f %f %f %f Q %f %f %f %f V 314 Z" % (
            x, top + 32, x, top, x + w / 2, top, x + w, top, x + w, top + 32)
        b.append(path(d, "url(#door)", "#FFF3DA", 8))
        b.append(path(d, "none", "#6B4226", 2.5))
        b.append(path("M %f %f V 314" % (x + w / 2, top + 4), "none", "#6B4226", 3))
        b.append(circle(x + w / 2 - 9, 276, 4.5, "#FFD54F"))
        b.append(circle(x + w / 2 + 9, 276, 4.5, "#FFD54F"))
    b.append(rect(0, 310, 520, 12, 4, "#B7A99F", "#7A6A60", 2))
    save("station", (-4, -4, 528, 330), 528, defs, b)


# ====================== SEGNALI ======================
# Disegnati su 120 x 300, palo compreso: le misure usate da RoadSign.qml (centri
# delle luci e del cartello) devono coincidere con quelle qui sotto.
def _pole(top):
    return [rect(53, top, 14, 288 - top, 5, "url(#pole)", "#37474F", 2.5),
            rect(34, 282, 52, 16, 6, "#78909C", "#37474F", 3)]


def _sign_defs():
    return (lg("pole", ("0", "#ECEFF1"), ("0.5", "#B0BEC5"), ("1", "#607D8B"), h=True)
            + lg("red", ("0", "#FF5A52"), ("1", "#C4161C"))
            + lg("blue", ("0", "#3D9BF0"), ("1", "#0D55B0"))
            + lg("box", ("0", "#5B6B75"), ("0.5", "#37474F"), ("1", "#1F2D34"), h=True))


def sign_light():
    """Semaforo con le tre luci spente (quella accesa la disegna il QML):
    centri in (60, 42), (60, 96) e (60, 150), raggio 21."""
    b = _pole(170)
    b.append(rect(20, 8, 80, 170, 26, "url(#box)", "#17232A", 4))
    for y, off in ((42, "#5D2A2A"), (96, "#5C5226"), (150, "#24482C")):
        b.append(circle(60, y, 25, "#17232A"))
        b.append(circle(60, y, 21, off))
        b.append(path("M %d %d Q 60 %d %d %d" % (31, y - 14, y - 42, 89, y - 14),
                      "none", "#17232A", 6))   # visiera
    save("sign-light", (0, 0, 120, 300), 192, _sign_defs(), b)


def sign_stop():
    """Ottagono rosso; la scritta STOP la mette il QML al centro (60, 66)."""
    def octagon(r):
        import math
        pts = ["%.1f %.1f" % (60 + r * math.cos(math.radians(22.5 + 45 * k)),
                              66 + r * math.sin(math.radians(22.5 + 45 * k))) for k in range(8)]
        return "M " + " L ".join(pts) + " Z"
    b = _pole(110)
    b.append(path(octagon(60), "#FFFFFF", "#8E1F1C", 3))
    b.append(path(octagon(52), "url(#red)"))
    save("sign-stop", (0, 0, 120, 300), 192, _sign_defs(), b)


def sign_noentry():
    b = _pole(110)
    b.append(circle(60, 66, 57, "#FFFFFF", "#8E1F1C", 3))
    b.append(circle(60, 66, 51, "url(#red)"))
    b.append(rect(24, 55, 72, 22, 5, "#FFFFFF"))
    save("sign-noentry", (0, 0, 120, 300), 192, _sign_defs(), b)


def sign_straight():
    """Cartello blu "direzione obbligatoria": di qui si puo' passare."""
    b = _pole(110)
    b.append(circle(60, 66, 57, "#FFFFFF", "#0D4580", 3))
    b.append(circle(60, 66, 51, "url(#blue)"))
    b.append(path("M 60 28 L 86 58 H 70 V 104 H 50 V 58 H 34 Z", "#FFFFFF"))
    save("sign-straight", (0, 0, 120, 300), 192, _sign_defs(), b)


def signs():
    sign_light()
    sign_stop()
    sign_noentry()
    sign_straight()


# ====================== BOTTIGLIA ======================
# Disegnata su 130 x 194, la stessa proporzione dell'elemento nel QML.
BOTTLE_OUT = ("M 49 14 H 81 V 44 Q 82 54 94 62 Q 113 74 113 96 V 168 "
              "Q 113 191 90 191 H 40 Q 17 191 17 168 V 96 Q 17 74 36 62 Q 48 54 49 44 Z")
BOTTLE_IN = ("M 54 14 H 76 V 45 Q 78 57 91 66 Q 108 77 108 97 V 167 "
             "Q 108 186 89 186 H 41 Q 22 186 22 167 V 97 Q 22 77 39 66 Q 52 57 54 45 Z")


def bottle():
    defs = (lg("g", ("0", "#FFFFFF"), ("0.2", "#E3F6FF"), ("0.75", "#FFFFFF"), ("1", "#9FD3EC"), h=True))
    # vetro: velato, con bordo marcato e riflessi, cosi' si vede il liquido dietro
    b = [path(BOTTLE_OUT, "url(#g)", None, extra='opacity="0.16"'),
         path(BOTTLE_OUT, "none", "#2F7FA8", 4.5),
         path("M 29 100 Q 29 84 40 76 M 29 108 V 164", "none", "#FFFFFF", 7, 'opacity="0.85"'),
         path("M 101 104 V 150", "none", "#FFFFFF", 3.5, 'opacity="0.7"'),
         path("M 57 22 V 42", "none", "#FFFFFF", 4, 'opacity="0.85"'),
         path("M 36 182 Q 65 190 94 182", "none", "#2F7FA8", 3, 'opacity="0.5"'),
         # bocca della bottiglia
         rect(43, 3, 44, 14, 7, "#BDE6F7", "#2F7FA8", 4),
         path("M 50 8 H 68", "none", "#FFFFFF", 3, 'opacity="0.9"')]
    save("bottle-glass", (0, 0, 130, 194), 390, defs, b)


def liquid(name, light, base, dark):
    defs = lg("l", ("0", dark), ("0.22", light), ("0.6", base), ("1", dark), h=True)
    b = [path(BOTTLE_IN, "url(#l)")]
    for x, y, r in ((44, 150, 4), (84, 128, 3), (72, 168, 5), (50, 112, 2.5), (92, 160, 2.5)):
        b.append(circle(x, y, r, "#FFFFFF", extra='opacity="0.55"'))   # bollicine
    save("liquid-" + name, (0, 0, 130, 194), 390, defs, b)


# ====================== CONCHIGLIE ======================
def shell(name, light, base, dark):
    defs = (lg("s", ("0", light), ("0.55", base), ("1", dark))
            + '<radialGradient id="pearl" cx="0.4" cy="0.32" r="0.75"><stop offset="0" stop-color="#FFFFFF"/>'
              '<stop offset="0.75" stop-color="#FFF6EC"/><stop offset="1" stop-color="#EBD3C4"/></radialGradient>')
    # cerniera in basso e ventaglio smerlato
    b = [path("M 62 128 L 56 150 Q 80 158 104 150 L 98 128 Z", "url(#s)", dark, 4)]
    d = ("M 66 140 L 14 98 Q 0 84 10 70 Q 6 50 26 44 Q 30 22 52 24 Q 62 6 80 12 "
         "Q 98 6 108 24 Q 130 22 134 44 Q 154 50 150 70 Q 160 84 146 98 L 94 140 Q 80 147 66 140 Z")
    b.append(path(d, "url(#s)", dark, 4.5))
    for x, y in ((18, 84), (28, 54), (52, 32), (80, 22), (108, 32), (132, 54), (142, 84)):
        b.append(path("M 80 138 Q %d %d %d %d" % ((80 + x) / 2 + (x - 80) * 0.12, (138 + y) / 2, x, y),
                      "none", dark, 3.5, 'opacity="0.55"'))
    b.append(path("M 24 66 Q 34 36 62 26", "none", "#FFFFFF", 6, 'opacity="0.65"'))
    b.append(circle(80, 82, 40, "url(#pearl)", dark, 3))   # perla per il numero
    save(name, (0, 0, 160, 160), 192, defs, b)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for c in ("red", "blue", "yellow", "green", "purple", "orange", "grey"):
        wagon(c)
    loco("red", "loco")
    loco("grey", "loco-grey")
    wheel("wheel", "#2B3A42", "#6F8794", "#B71C1C")
    puff()
    house("house-1", "#FFF1C9", "#FFD27A", "#FF7B6B", "#C0392B")
    house("house-2", "#E3F4FF", "#AFD8F5", "#7C8CE0", "#43509E")
    house("house-3", "#FFE1EC", "#F8AFC8", "#B97BD6", "#7A3D99")
    tree_round("tree-1", "#B8F07A", "#5CBF4A", "#2E7D32")
    tree_pine("tree-2")
    station()
    signs()
    bottle()
    # stesso ordine di BeansGame.liquids: acqua, aranciata, uva, limonata
    liquid("water", "#9BD8FF", "#42A5F5", "#1B6FC2")
    liquid("orange", "#FFD08A", "#FFA726", "#E06F00")
    liquid("grape", "#D99AE6", "#AB47BC", "#722085")
    liquid("lemon", "#FFF7A8", "#FDD835", "#D5A500")
    shell("shell-empty", "#FFE3EC", "#FFB3C9", "#D6638A")
    shell("shell-full", "#FFF2B0", "#FFC83D", "#C77E00")
    print("Illustrazioni create in", OUT)
    return 0


if __name__ == "__main__":
    sys.exit(main())
