#!/usr/bin/env python3
# Orme - Copyright (c) 2026 Angelo Scarnà
# SPDX-License-Identifier: GPL-3.0-or-later
"""Scarica le icone dell'app in assets/icons/ (entrambe le raccolte sono MIT).

  assets/icons/<nome>.png     figure 3D 256x256 da microsoft/fluentui-emoji
  assets/icons/ui/<nome>.png  simboli dei pulsanti da
                              microsoft/fluentui-system-icons (SVG -> PNG
                              128x128, richiede rsvg-convert)

Il nome del file e' quello usato nel QML: AppIcon { name: "rabbit" }.
Per aggiungere una figura: una riga in FIGURE e poi
    python3 scripts/fetch_icons.py
(scarica solo i file mancanti; con --force li riscarica tutti).
"""
import json
import pathlib
import subprocess
import sys
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "icons"

EMOJI_REPO = "microsoft/fluentui-emoji"
SYSTEM_REPO = "microsoft/fluentui-system-icons"

# nome nel QML -> nome della cartella in fluentui-emoji/assets
FIGURE = {
    # animali
    "bear": "Bear", "bee": "Honeybee", "bird": "Bird", "butterfly": "Butterfly",
    "cat": "Cat face", "chick": "Baby chick", "chick-front": "Front-facing baby chick",
    "chick-hatching": "Hatching chick", "chicken": "Chicken", "cow": "Cow face",
    "dog": "Dog face", "dolphin": "Dolphin", "eagle": "Eagle", "elephant": "Elephant",
    "ewe": "Ewe", "fish": "Fish", "fox": "Fox", "frog": "Frog", "hamster": "Hamster",
    "horse": "Horse face", "kangaroo": "Kangaroo", "koala": "Koala", "lion": "Lion",
    "monkey": "Monkey face", "monkey-see-no-evil": "See-no-evil monkey",
    "mouse": "Mouse face", "owl": "Owl", "panda": "Panda", "paws": "Paw prints",
    "pig": "Pig face", "rabbit": "Rabbit face", "shell": "Spiral shell",
    "snake": "Snake", "tiger": "Tiger face", "turtle": "Turtle",
    # persone e facce
    "baby": "Baby", "child": "Child", "dancer": "Man dancing", "elder": "Older person",
    "eyes": "Eyes", "face-angry": "Angry face", "face-astonished": "Astonished face",
    "face-crying": "Crying face", "face-fearful": "Fearful face",
    "face-grinning": "Grinning face", "face-sleeping": "Sleeping face",
    "face-smiling": "Smiling face with smiling eyes", "face-yum": "Face savoring food",
    "footprints": "Footprints", "gymnast": "Person cartwheeling", "ninja": "Ninja",
    "hand": "Raised hand",
    "point-up": "Backhand index pointing up", "superhero": "Person superhero",
    "victory": "Victory hand", "walker": "Person walking", "wave-hand": "Waving hand",
    # cibo e cucina
    "droplet": "Droplet", "lemon": "Lemon",
    "apple": "Red apple", "banana": "Banana", "bowl": "Bowl with spoon",
    "bread": "Bread", "butter": "Butter", "carrot": "Carrot", "cherries": "Cherries",
    "chestnut": "Chestnut", "coffee": "Hot beverage", "cookie": "Cookie",
    "cooking": "Cooking", "egg": "Egg", "grapes": "Grapes", "juice-box": "Beverage box",
    "knife": "Kitchen knife", "milk": "Glass of milk", "mushroom": "Mushroom",
    "peach": "Peach", "pear": "Pear", "pizza": "Pizza",
    "plate": "Fork and knife with plate", "sponge": "Sponge", "strawberry": "Strawberry",
    "tangerine": "Tangerine", "teapot": "Teapot", "watermelon": "Watermelon",
    # natura e cielo
    "blossom": "Blossom", "cherry-blossom": "Cherry blossom", "cloud": "Cloud",
    "clover": "Four leaf clover", "island": "Desert island",
    "leaf-fallen": "Fallen leaf", "leaf-wind": "Leaf fluttering in wind",
    "moon": "Crescent moon", "moon-full": "Full moon", "moon-half": "First quarter moon",
    "moon-new": "New moon", "rain": "Cloud with rain", "rainbow": "Rainbow",
    "seedling": "Seedling", "sun": "Sun", "sun-face": "Sun with face",
    "tree": "Deciduous tree", "tulip": "Tulip", "water-wave": "Water wave",
    # luoghi e mezzi
    "car": "Automobile", "construction": "Building construction", "house": "House",
    "hotel": "Hotel", "locomotive": "Locomotive", "road": "Motorway",
    "rocket": "Rocket", "sailboat": "Sailboat", "school": "School", "ship": "Ship",
    "station": "Station", "traffic-light": "Vertical traffic light",
    # oggetti
    "baby-bottle": "Baby bottle", "backpack": "Backpack", "ball": "Soccer ball",
    "balloon": "Balloon", "basket": "Basket", "bell": "Bell", "bone": "Bone",
    "books": "Books", "book-open": "Open book", "bottle": "Bottle with popping cork",
    "brick": "Brick", "crown": "Crown", "cup-straw": "Cup with straw", "die": "Game die",
    "door": "Door", "flag-finish": "Chequered flag", "fuel-pump": "Fuel pump",
    "gift": "Wrapped gift", "jar": "Jar", "joker": "Joker", "key": "Key",
    "lock": "Locked", "lotion": "Lotion bottle", "magnifier": "Magnifying glass tilted left",
    "map": "World map", "newspaper": "Newspaper", "package": "Package",
    "page": "Page facing up", "palette": "Artist palette", "party": "Party popper",
    "pencil": "Pencil", "picture": "Framed picture", "puzzle": "Puzzle piece",
    "robot": "Robot", "ruler": "Straight ruler", "shopping-cart": "Shopping cart",
    "tshirt": "T-shirt", "teddy": "Teddy bear", "wastebasket": "Wastebasket",
    "yarn": "Yarn",
    # simboli
    "circle-blue": "Blue circle", "circle-green": "Green circle",
    "circle-red": "Red circle", "divide": "Divide", "heart-red": "Red heart",
    "heart-white": "White heart", "letters": "Input latin letters",
    "letters-lower": "Input latin lowercase", "letters-upper": "Input latin uppercase",
    "minus": "Minus", "multiply": "Multiply", "music": "Musical notes",
    "numbers": "Input numbers", "plus": "Plus", "question": "Red question mark",
    "question-white": "White question mark", "recycle": "Recycling symbol",
    "shuffle": "Shuffle tracks button", "sparkles": "Sparkles",
    "speech": "Speech balloon", "star": "Star", "star-glowing": "Glowing star",
    "triangle-red": "Red triangle", "zzz": "Zzz",
}

WHITE = "#FFFFFF"
DARK = "#5D4037"   # Theme.text

# nome nel QML -> (cartella in fluentui-system-icons/assets, colore)
SIMBOLI = {
    "back": ("Arrow Left", WHITE),
    "person": ("Person", WHITE),
    "restart": ("Arrow Counterclockwise", WHITE),
    "close": ("Dismiss", DARK),
    "down": ("Caret Down", DARK),
    "play": ("Play", WHITE),
    "stop": ("Stop", WHITE),
    "next": ("Arrow Right", WHITE),
    "trash": ("Delete", WHITE),
    "check": ("Checkmark", WHITE),
    "backspace": ("Backspace", WHITE),
}


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "icon-fetcher"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def raw_url(repo, path):
    return "https://raw.githubusercontent.com/%s/main/%s" % (repo, urllib.parse.quote(path))


def figure_paths(folder):
    """Percorsi possibili: le figure di persone hanno la cartella del tono di pelle."""
    slug = folder.lower().replace(" ", "_")
    yield "assets/%s/3D/%s_3d.png" % (folder, slug)
    yield "assets/%s/Default/3D/%s_3d_default.png" % (folder, slug)


def symbol_paths(folder):
    slug = folder.lower().replace(" ", "_")
    for size in (48, 32, 28, 24, 20):
        yield "assets/%s/SVG/ic_fluent_%s_%d_filled.svg" % (folder, slug, size)


def first_available(repo, paths):
    for p in paths:
        try:
            return get(raw_url(repo, p))
        except urllib.error.HTTPError as e:
            if e.code != 404:
                raise
    return None


def main():
    force = "--force" in sys.argv[1:]
    (OUT / "ui").mkdir(parents=True, exist_ok=True)
    missing = []

    for name, folder in sorted(FIGURE.items()):
        dest = OUT / (name + ".png")
        if dest.exists() and not force:
            continue
        data = first_available(EMOJI_REPO, figure_paths(folder))
        if data is None or not data.startswith(b"\x89PNG"):
            missing.append("%s (%s)" % (name, folder))
            continue
        dest.write_bytes(data)
        print("ok ", name)

    for name, (folder, color) in sorted(SIMBOLI.items()):
        dest = OUT / "ui" / (name + ".png")
        if dest.exists() and not force:
            continue
        svg = first_available(SYSTEM_REPO, symbol_paths(folder))
        if svg is None:
            missing.append("ui/%s (%s)" % (name, folder))
            continue
        svg = svg.replace(b"#212121", color.encode())
        subprocess.run(["rsvg-convert", "-w", "128", "-h", "128", "-o", str(dest)],
                       input=svg, check=True)
        print("ok  ui/" + name)

    if missing:
        print("\nNON TROVATE:", *missing, sep="\n  ")
        return 1
    print("\nTutte le icone sono presenti in", OUT)
    return 0


if __name__ == "__main__":
    sys.exit(main())
