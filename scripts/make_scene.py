#!/usr/bin/env python3
# Orme - Copyright (c) 2026 Angelo Scarnà
# SPDX-License-Identifier: GPL-3.0-or-later
"""Compone i disegni originali del "Puzzle dei trenini" e li taglia in pezzi.

    python3 scripts/make_scene.py                tutti i disegni
    python3 scripts/make_scene.py mare notte     solo quelli indicati

Usa i trenini, la stazione, le case e gli alberi di make_art.py (disegni
originali) e le figure Fluent Emoji di assets/icons/ (MIT). Richiede
rsvg-convert e Pillow. Il risultato va in assets/puzzle/<disegno>/. I nomi
dei disegni (SCENES) devono coincidere con "pictures" di JigsawGame.qml.
"""
import base64
import pathlib
import random
import subprocess
import sys
import tempfile

import make_art
from make_art import INK, circle, lg, path, rect

ROOT = pathlib.Path(__file__).resolve().parent.parent
ART = ROOT / "assets" / "art"
ICONS = ROOT / "assets" / "icons"
W, H = 600, 840


def image(file, x, y, w, h, extra=""):
    data = base64.b64encode(pathlib.Path(file).read_bytes()).decode()
    return ('<image x="%s" y="%s" width="%s" height="%s" %s '
            'xlink:href="data:image/png;base64,%s"/>' % (x, y, w, h, extra, data))


def icon(name, x, y, size):
    return image(ICONS / (name + ".png"), x, y, size, size)


def art(name, x, y, width):
    sizes = {"station": (528, 330), "house": (256, 256), "tree": (192, 240), "puff": (128, 128)}
    w, h = sizes[name.split("-")[0]]
    return image(ART / (name + ".png"), x, y, width, round(width * h / w))


def car(body, x, bottom, u, riders, locomotive=False, mirror=False):
    """Un vagone o una locomotiva: stesse proporzioni del gioco "Il trenino"
    (200 x 140 unita'), con ruote, passeggeri o macchinista."""
    b = [image(body, -12, -30, 224, 172)]
    if locomotive:
        b.append(icon(riders[0], 37 - 22, 45 - 22, 44))
        wheels = [(34, 52), (88, 40), (131, 40), (167, 28)]
    else:
        for name, cx in zip(riders, (53, 145)):
            b.append(icon(name, cx - 23, 53 - 23, 46))
        wheels = [(30, 36), (64, 36), (134, 36), (168, 36)]
    for cx, d in wheels:
        b.append(image(ART / "wheel.png", cx - d / 2, 140 - d, d, d))
    if locomotive:
        b.append(rect(30, 113, 105, 8, 4, "#FFCA28", "#8D5F00", 1.2))
    flip = "translate(%s 0) scale(-1 1) " % (200 * u + 2 * x) if mirror else ""
    return '<g transform="%stranslate(%s %s) scale(%s)">%s</g>' % (
        flip, x, bottom - 140 * u, u, "".join(b))


def rails(y, x0, x1, k=1.0):
    b = [rect(x0, y - 3 * k, x1 - x0, 20 * k, 6, "#B9AA98")]
    for x in range(int(x0), int(x1), int(26 * k)):
        b.append(rect(x, y + 2 * k, 14 * k, 13 * k, 3, "#8D5F3C", "#5A3820", 1.2))
    for dy in (0, 9 * k):
        b.append(rect(x0, y + dy - 2 * k, x1 - x0, 5 * k, 2, "url(#rail)", "#37474F", 1))
    return "".join(b)


def svg(defs, b):
    return ('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
            'width="%d" height="%d" viewBox="0 0 %d %d"><defs>%s</defs>%s</svg>'
            % (W, H, W, H, defs, "".join(b)))


def text(x, y, size, words, fill="#FFFFFF"):
    return ('<text x="%s" y="%s" font-family="Fredoka, DejaVu Sans, sans-serif" font-weight="bold" '
            'font-size="%s" text-anchor="middle" fill="%s">%s</text>' % (x, y, size, fill, words))


def station_art(x, y, width):
    k = width / 528
    return art("station", x, y, width) + text(x + 264 * k, y + 175 * k + 24 * k, 40 * k, "STAZIONE")


def trenini(tmp):
    defs = (lg("sky", ("0", "#4FB3F6"), ("1", "#CDEEFF"))
            + lg("far", ("0", "#9FC6E8"), ("1", "#C9E6D6"))
            + lg("hill", ("0", "#B5E86A"), ("1", "#5DB64A"))
            + lg("meadow", ("0", "#8FD65A"), ("1", "#3F9A3A"))
            + lg("stone", ("0", "#E8C9A0"), ("1", "#B08864"))
            + lg("rail", ("0", "#ECEFF1"), ("1", "#78909C"))
            + lg("wood", ("0", "#D59B62"), ("1", "#8A5A32"))
            + lg("rock", ("0", "#9AD25A"), ("1", "#4E9440")))
    b = [rect(0, 0, W, 420, 0, "url(#sky)")]

    # ---------- cielo ----------
    b += [icon("sun-face", 18, 16, 128), icon("cloud", 128, 70, 110),
          icon("balloon", 246, 14, 112), icon("rainbow", 428, 4, 168),
          icon("cloud", 350, 96, 92), icon("bird", 168, 8, 58),
          icon("butterfly", 366, 30, 52), icon("cloud", -34, 150, 100)]

    # ---------- montagne, colline, paese ----------
    b.append(path("M -20 300 L 90 150 L 170 235 L 262 128 L 380 262 L 470 172 L 620 300 Z", "url(#far)"))
    for d in ("M 90 150 L 66 183 L 90 176 L 104 190 L 118 179 Z",
              "M 262 128 L 234 160 L 258 154 L 272 169 L 292 160 Z"):
        b.append(path(d, "#FFFFFF"))
    b.append(path("M -20 262 Q 90 196 220 252 Q 330 296 430 214 Q 530 150 620 206 V 430 H -20 Z", "url(#hill)"))
    b += [art("tree-2", 4, 188, 48), art("tree-1", 40, 198, 56),
          art("house-3", 446, 140, 82), art("house-2", 522, 156, 74),
          art("tree-2", 412, 170, 44), art("tree-1", 190, 196, 46)]

    # ---------- prato ----------
    b.append(rect(0, 392, W, H - 392, 0, "url(#meadow)"))

    # ---------- viadotto col trenino ----------
    deck = 318
    arches = "M -20 %d H 620 V 436 H -20 Z" % deck
    for x in range(-6, 600, 124):
        arches += (" M %d 436 V 392 Q %d 348 %d 348 Q %d 348 %d 392 V 436 Z"
                   % (x + 16, x + 16, x + 62, x + 108, x + 108))
    b.append(path(arches, "url(#stone)", "#7A5A40", 3, 'fill-rule="evenodd"'))
    for y in (336, 350):
        b.append(path("M -20 %d H 620" % y, "none", "#7A5A40", 1.5, 'opacity="0.45"'))
    for x in range(0, 600, 34):
        b.append(path("M %d %d v 14 M %d 336 v 14" % (x, deck + 4, x + 17), "none", "#7A5A40", 1.5,
                      'opacity="0.45"'))
    b.append(rails(deck - 8, -20, 620, 0.8))
    b += [car(ART / "wagon-yellow.png", 36, deck, 0.66, ("cat", "frog")),
          car(ART / "wagon-purple.png", 178, deck, 0.66, ("pig", "koala")),
          car(ART / "loco.png", 320, deck, 0.66, ("fox",), locomotive=True),
          art("puff", 410, 190, 44), art("puff", 384, 170, 30)]

    # ---------- stazione ----------
    sx, sy, sw = -8, 372, 296
    k = sw / 528
    b.append(art("station", sx, sy, sw))
    b.append('<text x="%s" y="%s" font-family="Fredoka, DejaVu Sans, sans-serif" font-weight="bold" '
             'font-size="21" text-anchor="middle" fill="#FFFFFF">STAZIONE</text>'
             % (sx + 264 * k, sy + 175 * k + 7))

    # ---------- galleria con la locomotiva verde ----------
    b.append(path("M 322 556 Q 360 372 500 378 Q 590 384 626 436 V 556 Z", "url(#rock)", "#3C7A34", 3))
    b.append(path("M 452 546 V 482 Q 452 420 524 420 Q 596 420 596 482 V 546 Z", "url(#stone)", "#7A5A40", 3))
    b.append(path("M 468 546 V 486 Q 468 436 524 436 Q 580 436 580 486 V 546 Z", "#2A1E1B"))
    b.append(rails(536, 290, 600, 0.8))
    b.append(car(tmp / "loco-green.png", 404, 548, 0.72, ("rabbit",), locomotive=True, mirror=True))
    b.append(art("tree-2", 568, 486, 46))

    # ---------- binario e locomotiva in primo piano ----------
    b.append(rails(756, -20, 620, 1.7))
    b += [art("puff", 334, 474, 74), art("puff", 306, 454, 46)]
    b.append(car(tmp / "loco-blue.png", 118, 770, 1.66, ("panda",), locomotive=True))

    # ---------- primo piano ----------
    for x in (10, 52, 94):
        b.append(rect(x, 650, 20, 100, 8, "url(#wood)", "#5A3820", 3))
    for y in (668, 708):
        b.append(rect(-14, y, 142, 17, 7, "url(#wood)", "#5A3820", 3))
    b.append(icon("chick", 26, 596, 66))
    # cartello con le frecce colorate
    b.append(rect(532, 584, 18, 200, 7, "url(#wood)", "#5A3820", 3))
    for y, color, d in ((592, "#42A5F5", -1), (630, "#EF5350", 1), (668, "#66BB6A", -1), (706, "#FDD835", 1)):
        x0, x1 = 496, 584
        tip = "M %d %d H %d L %d %d L %d %d H %d Z" % (
            (x0, y, x1, x1 + 14, y + 15, x1, y + 30, x0) if d > 0 else
            (x1, y, x0, x0 - 14, y + 15, x0, y + 30, x1))
        b.append(path(tip, color, INK, 2.5))
    b += [icon("blossom", -10, 764, 84), icon("tulip", 66, 786, 62),
          icon("cherry-blossom", 124, 792, 54), icon("clover", 196, 794, 50),
          icon("frog", 258, 778, 68), icon("mushroom", 340, 790, 54),
          icon("turtle", 406, 774, 74), icon("blossom", 484, 786, 62),
          icon("dog", 534, 750, 64), icon("tulip", -6, 718, 48)]
    for x, y in ((168, 806), (246, 826), (330, 780), (470, 830), (582, 826), (22, 612)):
        b.append(circle(x, y, 5, "#FFFFFF"))
        b.append(circle(x, y, 2, "#FDD835"))

    return svg(defs, b)


# ====================== IL MARE ======================
def mare(tmp):
    defs = (lg("sky", ("0", "#35C2F0"), ("1", "#FFF1C9"))
            + lg("sea", ("0", "#2BB6C9"), ("1", "#0B5E9E"))
            + lg("sand", ("0", "#FFE7A8"), ("1", "#E8B765"))
            + lg("stone", ("0", "#F3D9C2"), ("1", "#C08A6E"))
            + lg("rail", ("0", "#ECEFF1"), ("1", "#78909C"))
            + lg("red", ("0", "#FF7B6B"), ("1", "#B92B27")))
    b = [rect(0, 0, W, 330, 0, "url(#sky)")]
    b += [icon("sun-face", 440, 14, 140), icon("cloud", 20, 30, 130), icon("cloud", 250, 8, 96),
          icon("balloon", 150, 74, 96), icon("airplane", 300, 96, 80), icon("bird", 380, 170, 54),
          icon("bird", 52, 168, 40), icon("rainbow", -24, 150, 150)]
    # mare con le onde
    b.append(rect(0, 270, W, 330, 0, "url(#sea)"))
    for row, y in enumerate((292, 322, 520, 552)):
        d = "M %d %d" % (-40 + 22 * (row % 2), y) + "".join(" q 18 -12 36 0 q 18 12 36 0" for _ in range(10))
        b.append(path(d, "none", "#FFFFFF", 4, 'opacity="0.55"'))
    b += [icon("island", 428, 190, 132), icon("sailboat", 120, 196, 112), icon("ship", 268, 222, 84)]

    # faro a strisce
    b.append(path("M 18 330 L 34 196 H 78 L 94 330 Z", "#FFFFFF", INK, 3))
    for y0, y1 in ((222, 246), (276, 302)):
        k0, k1 = (y0 - 196) / 134, (y1 - 196) / 134
        b.append(path("M %.1f %d L %.1f %d L %.1f %d L %.1f %d Z" % (
            34 - 16 * k0, y0, 78 + 16 * k0, y0, 78 + 16 * k1, y1, 34 - 16 * k1, y1), "url(#red)"))
    b.append(rect(30, 168, 52, 30, 5, "#FFF176", INK, 3))
    b.append(path("M 24 170 L 56 142 L 88 170 Z", "url(#red)", INK, 3))
    b.append(path("M -10 336 Q 56 300 124 336 Z", "#8D7466", INK, 3))

    # ponte sul mare col treno
    deck = 414
    arches = "M -20 %d H 620 V 520 H -20 Z" % deck
    for x in range(-20, 620, 106):
        arches += (" M %d 520 V 480 Q %d 440 %d 440 Q %d 440 %d 480 V 520 Z"
                   % (x + 14, x + 14, x + 53, x + 92, x + 92))
    b.append(path(arches, "url(#stone)", "#7A5A40", 3, 'fill-rule="evenodd"'))
    b.append(path("M -20 428 H 620", "none", "#7A5A40", 1.5, 'opacity="0.5"'))
    b.append(rails(deck - 8, -20, 620, 0.8))
    b += [car(ART / "wagon-orange.png", 20, deck, 0.7, ("panda", "rabbit")),
          car(ART / "wagon-green.png", 170, deck, 0.7, ("dog", "pig")),
          car(tmp / "loco-yellow.png", 320, deck, 0.7, ("frog",), locomotive=True),
          art("puff", 416, 276, 50), art("puff", 388, 256, 32)]
    b += [icon("dolphin", 470, 450, 116), icon("fish", 20, 494, 66), icon("fish", 296, 520, 56),
          icon("dolphin", 126, 484, 92)]

    # spiaggia e binario davanti
    b.append(path("M -20 600 Q 120 556 300 588 Q 470 620 620 574 V 860 H -20 Z", "url(#sand)", "#C99A4A", 3))
    b.append(rails(748, -20, 620, 1.7))
    b += [art("puff", 424, 520, 70), art("puff", 394, 498, 44)]
    b.append(car(ART / "loco.png", 214, 762, 1.5, ("cat",), locomotive=True))
    b += [icon("umbrella", 18, 586, 128), icon("ball", 20, 690, 76), icon("turtle", 120, 768, 76),
          icon("shell", 18, 776, 62), icon("shell", 330, 786, 50), icon("watermelon", 220, 786, 56),
          icon("bird", 540, 566, 54), icon("star", 420, 776, 62), icon("pineapple", 514, 760, 76),
          icon("goose", 118, 636, 74)]
    for x, y in ((90, 800), (196, 776), (300, 826), (396, 838), (494, 836), (560, 690), (100, 570)):
        b.append(circle(x, y, 6, "#FFF6E0", "#C99A4A", 1.5))
    return svg(defs, b)


# ====================== LA NOTTE ======================
def notte(tmp):
    defs = (lg("sky", ("0", "#141B52"), ("0.6", "#3B3E8F"), ("1", "#8A6FB8"))
            + lg("far", ("0", "#4A4F9A"), ("1", "#2E3470"))
            + lg("hill", ("0", "#2F6F6A"), ("1", "#17424A"))
            + lg("meadow", ("0", "#2C6B55"), ("1", "#12352F"))
            + lg("stone", ("0", "#9A86B5"), ("1", "#5A4A78"))
            + lg("rail", ("0", "#D8DEF0"), ("1", "#5C6790"))
            + lg("beam", ("0", "#FFF59D"), ("1", "#FFF59D"), h=True))
    b = [rect(0, 0, W, 440, 0, "url(#sky)")]
    rnd = random.Random(7)    # stelline sparse, sempre uguali
    for _ in range(80):
        x, y, r = rnd.uniform(2, 598), rnd.uniform(4, 300), rnd.uniform(1.2, 3.4)
        b.append(circle(round(x, 1), round(y, 1), round(r, 1), "#FFF9C4", extra='opacity="0.9"'))
    b += [icon("moon", 424, 18, 136), icon("star-glowing", 60, 34, 74), icon("star", 224, 12, 50),
          icon("star-glowing", 330, 108, 52), icon("rocket", 160, 80, 96), icon("star", 16, 170, 42),
          icon("cloud", 478, 130, 104)]
    b.append(path("M -20 330 L 80 180 L 190 292 L 300 160 L 430 300 L 520 212 L 620 318 V 440 H -20 Z", "url(#far)"))
    for d in ("M 80 180 L 58 213 L 80 205 L 94 220 L 108 209 Z",
              "M 300 160 L 272 192 L 296 186 L 310 202 L 330 192 Z"):
        b.append(path(d, "#E8EAFF"))
    b.append(path("M -20 300 Q 110 232 250 288 Q 360 330 450 262 Q 540 214 620 250 V 460 H -20 Z", "url(#hill)"))

    def lit_house(name, x, y, width):
        k = width / 200
        out = [art(name, x, y, width)]
        for wx, wy, ww, wh in ((36, 116, 36, 34), (130, 116, 36, 34), (86, 52, 28, 28)):
            out.append(rect(x + wx * k, y + wy * k, ww * k, wh * k, 8 * k, "#FFD600", extra='opacity="0.85"'))
        return "".join(out)

    b += [art("tree-2", 10, 220, 56), lit_house("house-2", 62, 232, 86), art("tree-1", 150, 240, 52),
          lit_house("house-3", 388, 208, 94), lit_house("house-1", 482, 226, 78), art("tree-2", 344, 230, 50)]

    b.append(rect(0, 392, W, H - 392, 0, "url(#meadow)"))
    deck = 366
    b.append(rails(deck - 8, -20, 620, 0.8))
    b += [car(ART / "wagon-red.png", 30, deck, 0.68, ("koala", "cat")),
          car(ART / "wagon-yellow.png", 176, deck, 0.68, ("rabbit", "panda")),
          car(tmp / "loco-purple.png", 322, deck, 0.68, ("fox",), locomotive=True),
          art("puff", 414, 232, 46), art("puff", 388, 212, 30)]

    # stazione illuminata
    b.append(station_art(-6, 406, 300))
    for k in range(3):
        x = -6 + 300 * (0.12 + k * 0.3)
        b.append(rect(x + 10, 539, 28, 38, 14, "#FFE082", extra='opacity="0.85"'))
    # albero col gufo
    b.append(art("tree-1", 396, 386, 190))
    b.append(icon("owl", 446, 424, 88))
    # lampione
    b.append(rect(332, 470, 12, 120, 5, "#455A64", "#17232A", 2))
    b.append(circle(338, 462, 40, "#FFF59D", extra='opacity="0.28"'))
    b.append(circle(338, 462, 20, "#FFF176", "#F9A825", 4))

    # binario e locomotiva in primo piano, col fanale acceso
    b.append(rails(756, -20, 620, 1.7))
    b.append(path("M 430 640 L 620 566 V 748 Z", "url(#beam)", extra='opacity="0.35"'))
    b += [art("puff", 300, 504, 66), art("puff", 270, 486, 42)]
    b.append(car(tmp / "loco-green.png", 96, 770, 1.62, ("tiger",), locomotive=True))
    b += [icon("face-sleeping", 14, 590, 66), icon("zzz", 66, 566, 56), icon("mushroom", 6, 764, 74),
          icon("frog", 96, 788, 54), icon("teddy", 190, 782, 62), icon("mouse", 292, 790, 54),
          icon("clover", 372, 792, 50), icon("rabbit", 456, 758, 78), icon("blossom", 540, 786, 62),
          icon("elephant", 504, 640, 92)]
    for k in range(22):   # lucciole
        x, y = (k * 163) % 580 + 10, 600 + (k * 47) % 230
        b.append(circle(x, y, 7, "#F4FF81", extra='opacity="0.25"'))
        b.append(circle(x, y, 2.6, "#F4FF81"))
    return svg(defs, b)


# ====================== IL PASSAGGIO A LIVELLO ======================
def segnali(tmp):
    defs = (lg("sky", ("0", "#7FD4F7"), ("1", "#E6F7FF"))
            + lg("hill", ("0", "#C8ED76"), ("1", "#6FBF4C"))
            + lg("meadow", ("0", "#9BDB5E"), ("1", "#4CA23E"))
            + lg("road", ("0", "#8C99A3"), ("1", "#59646D"))
            + lg("rail", ("0", "#ECEFF1"), ("1", "#78909C")))
    b = [rect(0, 0, W, 420, 0, "url(#sky)")]
    b += [icon("sun-face", 20, 14, 118), icon("cloud", 140, 20, 110), icon("cloud", 440, 50, 128),
          icon("helicopter", 284, 40, 118), icon("balloon", 506, 130, 80), icon("bird", 190, 130, 52),
          icon("butterfly", 40, 150, 56)]
    b.append(path("M -20 262 Q 100 178 240 250 Q 350 306 450 220 Q 540 168 620 218 V 440 H -20 Z", "url(#hill)"))
    b += [art("house-1", 18, 192, 108), art("tree-1", 120, 190, 74), art("house-2", 196, 220, 86),
          art("tree-2", 380, 190, 66), art("house-3", 450, 204, 110), art("tree-2", 556, 220, 54),
          icon("school", 280, 182, 118)]
    b.append(rect(0, 372, W, H - 372, 0, "url(#meadow)"))

    # la strada che attraversa i binari
    b.append(path("M 246 372 H 330 L 520 860 H 130 Z", "url(#road)", "#455A64", 3))
    for y0, y1 in ((392, 414), (432, 458), (640, 686), (790, 840)):
        k0, k1 = (y0 - 372) / 488, (y1 - 372) / 488
        b.append(path("M %.1f %d L %.1f %d L %.1f %d L %.1f %d Z" % (
            285 + 38 * k0, y0, 291 + 40 * k0, y0, 291 + 40 * k1, y1, 285 + 38 * k1, y1), "#FFFFFF"))

    # il treno che passa
    deck = 556
    b.append(rails(deck - 10, -20, 620, 1.2))
    b += [car(ART / "wagon-blue.png", -6, deck, 1.06, ("dog", "rabbit")),
          car(ART / "wagon-purple.png", 222, deck, 1.06, ("panda", "frog")),
          car(ART / "loco.png", 450, deck, 1.06, ("fox",), locomotive=True)]
    b += [art("puff", 584, 332, 56), art("puff", 546, 306, 40)]

    # sbarre a strisce abbassate
    for x, y, d in ((150, 624, 1), (482, 624, -1)):
        length = 150
        x0 = x if d > 0 else x - length
        b.append(rect(x0, y, length, 20, 9, "#FFFFFF", INK, 3))
        for k in range(4):
            b.append(rect(x0 + 14 + k * 36, y + 2, 18, 16, 2, "#E53935"))
        b.append(rect(x - 11, y - 8, 22, 70, 7, "#607D8B", "#17232A", 3))
        b.append(circle(x, y + 10, 8, "#FF1744", "#17232A", 3))

    # i segnali, grandi
    def sign(kind, x, y, width, lamp=False):
        out = [image(ART / ("sign-" + kind + ".png"), x, y, width, width * 2.5)]
        u = width / 120
        if lamp:
            out.append(circle(x + 60 * u, y + 42 * u, 33 * u, "#FF1744", extra='opacity="0.35"'))
            out.append(circle(x + 60 * u, y + 42 * u, 21 * u, "#FF1F1F"))
            out.append(circle(x + 52 * u, y + 34 * u, 6 * u, "#FFFFFF", extra='opacity="0.75"'))
        if kind == "stop":
            out.append(text(x + 60 * u, y + 78 * u, 34 * u, "STOP"))
        return "".join(out)

    b.append(sign("light", 8, 556, 108, lamp=True))
    b.append(sign("stop", 486, 566, 110))
    b.append(sign("noentry", 380, 356 - 40, 56))
    b.append(sign("straight", 148, 322, 52))
    b += [icon("car", 232, 668, 132), icon("cat", 104, 732, 76), icon("chick", 158, 782, 56),
          icon("walker", 500, 756, 80), icon("tulip", -8, 784, 64), icon("blossom", 52, 800, 48),
          icon("cherry-blossom", 556, 806, 44), icon("turtle", 396, 700, 70), icon("mushroom", 438, 796, 50)]
    return svg(defs, b)


SCENES = {"trenini": trenini, "mare": mare, "notte": notte, "segnali": segnali}


def main(names):
    unknown = [n for n in names if n not in SCENES]
    if unknown:
        print("Disegni sconosciuti:", ", ".join(unknown), "- ci sono:", ", ".join(SCENES))
        return 1
    with tempfile.TemporaryDirectory() as folder:
        tmp = pathlib.Path(folder)
        # locomotive di altri colori, disegnate al volo nella cartella temporanea
        make_art.OUT = tmp
        for color in ("blue", "green", "yellow", "purple"):
            make_art.loco(color, "loco-" + color)
        for name in names or SCENES:
            png = tmp / (name + ".png")
            subprocess.run(["rsvg-convert", "-o", str(png)], input=SCENES[name](tmp).encode(), check=True)
            result = subprocess.run([sys.executable, str(ROOT / "scripts" / "make_puzzle.py"),
                                     str(png), name]).returncode
            if result:
                return result
    return 0


if __name__ == "__main__":
    sys.dont_write_bytecode = True
    sys.exit(main(sys.argv[1:]))
