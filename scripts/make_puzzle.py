#!/usr/bin/env python3
# Orme - Copyright (c) 2026 Angelo Scarnà
# SPDX-License-Identifier: GPL-3.0-or-later
"""Taglia un'immagine in pezzi di puzzle a incastro (richiede Pillow).

    python3 scripts/make_puzzle.py disegno.png nome
    python3 scripts/make_puzzle.py foto.jpg nome --angoli 75,30,844,53,871,1189,29,1161

--angoli serve quando l'immagine e' una FOTO di un disegno stampato: sono le
coordinate dei quattro angoli del disegno (alto-sx, alto-dx, basso-dx,
basso-sx), che viene raddrizzato.

Scrive in assets/puzzle/<nome>/ l'immagine intera (full.png) e, per ogni
griglia, i pezzi <colonne>x<righe>-<numero>.png con lo sfondo trasparente.
Le misure (WIDTH, HEIGHT, PAD, GRIDS) devono coincidere con quelle di
qml/games/jigsaw/JigsawGame.qml.
"""
import argparse
import pathlib
import random

from PIL import Image, ImageDraw, ImageFilter, ImageOps

ROOT = pathlib.Path(__file__).resolve().parent.parent

WIDTH, HEIGHT = 600, 840
GRIDS = [(2, 2), (2, 3), (3, 3), (3, 4)]
PAD = 0.25      # margine per le linguette, rispetto al lato corto del pezzo
SS = 4          # sovracampionamento per avere bordi morbidi

# mezzo incastro come curve di Bezier: t lungo il lato (0..1), n in fuori
CURVES = [
    ((0.00, 0.00), (0.34, 0.00), (0.44, -0.03), (0.40, 0.06)),
    ((0.40, 0.06), (0.29, 0.24), (0.71, 0.24), (0.60, 0.06)),
    ((0.60, 0.06), (0.56, -0.03), (0.66, 0.00), (1.00, 0.00)),
]


def edge(start, end, sign, bump):
    """Punti di un lato da start a end; sign 0 = lato dritto (bordo)."""
    if sign == 0:
        return [start, end]
    dx, dy = end[0] - start[0], end[1] - start[1]
    length = (dx * dx + dy * dy) ** 0.5
    nx, ny = -dy / length, dx / length
    points = []
    for p0, p1, p2, p3 in CURVES:
        for i in range(25):
            u = i / 24
            w = ((1 - u) ** 3, 3 * u * (1 - u) ** 2, 3 * u * u * (1 - u), u ** 3)
            t = sum(a * p[0] for a, p in zip(w, (p0, p1, p2, p3)))
            n = sum(a * p[1] for a, p in zip(w, (p0, p1, p2, p3))) * bump * sign
            points.append((start[0] + dx * t + nx * n, start[1] + dy * t + ny * n))
    return points


def cut(image, cols, rows, out):
    cw, ch = WIDTH / cols, HEIGHT / rows
    side = min(cw, ch)
    pad = round(side * PAD)
    rnd = random.Random(cols * 100 + rows)    # sempre lo stesso taglio

    # ogni lato interno si calcola una volta sola: i due pezzi vicini combaciano
    horizontal = {}
    for r in range(rows + 1):
        for c in range(cols):
            sign = 0 if r in (0, rows) else rnd.choice((-1, 1))
            horizontal[c, r] = edge((c * cw, r * ch), ((c + 1) * cw, r * ch), sign, side)
    vertical = {}
    for r in range(rows):
        for c in range(cols + 1):
            sign = 0 if c in (0, cols) else rnd.choice((-1, 1))
            vertical[c, r] = edge((c * cw, r * ch), (c * cw, (r + 1) * ch), sign, side)

    size = (round(cw) + 2 * pad, round(ch) + 2 * pad)
    big = (size[0] * SS, size[1] * SS)
    canvas = Image.new("RGBA", (WIDTH + 2 * pad, HEIGHT + 2 * pad))
    canvas.paste(image, (pad, pad))

    for r in range(rows):
        for c in range(cols):
            outline = (horizontal[c, r] + vertical[c + 1, r]
                       + horizontal[c, r + 1][::-1] + vertical[c, r][::-1])
            local = [((x - c * cw + pad) * SS, (y - r * ch + pad) * SS) for x, y in outline]

            mask = Image.new("L", big, 0)
            ImageDraw.Draw(mask).polygon(local, fill=255)

            box = (round(c * cw), round(r * ch))
            piece = canvas.crop((box[0], box[1], box[0] + size[0], box[1] + size[1]))
            piece = piece.resize(big, Image.BICUBIC)

            # rilievo: filo chiaro lungo il taglio e un'ombra scura sottile
            line = local + local[:1]
            for color, width in (((255, 255, 255, 215), 7), ((60, 40, 30, 170), 3)):
                rim = Image.new("RGBA", big)
                ImageDraw.Draw(rim).line(line, fill=color, width=width * SS, joint="curve")
                piece.alpha_composite(rim)

            piece.putalpha(mask)
            piece.resize(size, Image.LANCZOS).save(
                out / ("%dx%d-%d.png" % (cols, rows, r * cols + c)), optimize=True)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("sorgente")
    ap.add_argument("nome")
    ap.add_argument("--angoli", help="x1,y1,x2,y2,x3,y3,x4,y4 (alto-sx in senso orario)")
    args = ap.parse_args()

    image = ImageOps.exif_transpose(Image.open(args.sorgente)).convert("RGB")
    if args.angoli:
        v = [float(n) for n in args.angoli.split(",")]
        if len(v) != 8:
            ap.error("--angoli vuole 8 numeri")
        quad = (v[0], v[1], v[6], v[7], v[4], v[5], v[2], v[3])  # ordine di Pillow
        image = image.transform((WIDTH, HEIGHT), Image.QUAD, quad, Image.BICUBIC)
        image = image.filter(ImageFilter.UnsharpMask(radius=1.2, percent=45, threshold=2))
    else:
        image = ImageOps.fit(image, (WIDTH, HEIGHT), Image.LANCZOS)

    out = ROOT / "assets" / "puzzle" / args.nome
    out.mkdir(parents=True, exist_ok=True)
    image.save(out / "full.png", optimize=True)
    for cols, rows in GRIDS:
        cut(image, cols, rows, out)
    print("Puzzle scritto in", out)


if __name__ == "__main__":
    main()
