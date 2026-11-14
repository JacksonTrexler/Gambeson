#!/usr/bin/env python3
"""Gambeson placeholder art: plain PNGs standing in until real art replaces the file (same path, any size).

  python3 Util/icon.py skill kick [--text Kk]      # Icons/Skills/kick.png: its mark (Skill.mark()) in pixel letters
  python3 Util/icon.py skills                      # every skill still missing one
  python3 Util/icon.py tile sand --color "#d8c48a" [--text Sa]   # Tiles/sand.png: 32x32 ground, flat colour
  python3 Util/icon.py unit Blinthe --color "#b07acc" [--text B]  # Units/Blinthe.png: a 20x25 figure
  python3 Util/icon.py item dagger                # Icons/Items/dagger.png: 32x32 drawn off Items/dagger.tres (slot, weapon's damage tag, trim)
  python3 Util/icon.py items                       # every item still missing one
  python3 Util/icon.py check                       # fails an item without an icon (skill.py check runs it too)
  python3 Util/icon.py effect suspicion --shape eye [--text Su]  # Icons/Effects/suspicion.png: a status's icon on a unit card

Skill and effect icons are white on clear, so the skills screen tints them by state (learned, open, a stub); draw real
ones the same way, or in colour where tinting doesn't matter. Godot imports a new PNG on the next
`godot --headless --path . --import` (the tools run it); commit the .png.import beside it. Plain python3.
"""
import argparse, os, re, struct, sys, zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKILL_ICONS = "Icons/Skills"

# 5x7 pixel letters, one string of rows each ('#' set)
FONT = {
    "A": ".###. #...# #...# ##### #...# #...# #...#", "B": "####. #...# #...# ####. #...# #...# ####.",
    "C": ".###. #...# #.... #.... #.... #...# .###.", "D": "####. #...# #...# #...# #...# #...# ####.",
    "E": "##### #.... #.... ####. #.... #.... #####", "F": "##### #.... #.... ####. #.... #.... #....",
    "G": ".###. #...# #.... #.### #...# #...# .####", "H": "#...# #...# #...# ##### #...# #...# #...#",
    "I": ".###. ..#.. ..#.. ..#.. ..#.. ..#.. .###.", "J": "..### ...#. ...#. ...#. ...#. #..#. .##..",
    "K": "#...# #..#. #.#.. ##... #.#.. #..#. #...#", "L": "#.... #.... #.... #.... #.... #.... #####",
    "M": "#...# ##.## #.#.# #.#.# #...# #...# #...#", "N": "#...# #...# ##..# #.#.# #..## #...# #...#",
    "O": ".###. #...# #...# #...# #...# #...# .###.", "P": "####. #...# #...# ####. #.... #.... #....",
    "Q": ".###. #...# #...# #...# #.#.# #..#. .##.#", "R": "####. #...# #...# ####. #.#.. #..#. #...#",
    "S": ".#### #.... #.... .###. ....# ....# ####.", "T": "##### ..#.. ..#.. ..#.. ..#.. ..#.. ..#..",
    "U": "#...# #...# #...# #...# #...# #...# .###.", "V": "#...# #...# #...# #...# #...# .#.#. ..#..",
    "W": "#...# #...# #...# #.#.# #.#.# #.#.# .#.#.", "X": "#...# #...# .#.#. ..#.. .#.#. #...# #...#",
    "Y": "#...# #...# .#.#. ..#.. ..#.. ..#.. ..#..", "Z": "##### ....# ...#. ..#.. .#... #.... #####",
    "a": "..... ..... .###. ....# .#### #...# .####", "b": "#.... #.... #.##. ##..# #...# #...# ####.",
    "c": "..... ..... .###. #.... #.... #...# .###.", "d": "....# ....# .##.# #..## #...# #...# .####",
    "e": "..... ..... .###. #...# ##### #.... .###.", "f": "..##. .#..# .#... ###.. .#... .#... .#...",
    "g": "..... .#### #...# #...# .#### ....# .###.", "h": "#.... #.... #.##. ##..# #...# #...# #...#",
    "i": "..#.. ..... .##.. ..#.. ..#.. ..#.. .###.", "j": "...#. ..... ..##. ...#. ...#. #..#. .##..",
    "k": "#.... #.... #..#. #.#.. ##... #.#.. #..#.", "l": ".##.. ..#.. ..#.. ..#.. ..#.. ..#.. .###.",
    "m": "..... ..... ##.#. #.#.# #.#.# #...# #...#", "n": "..... ..... #.##. ##..# #...# #...# #...#",
    "o": "..... ..... .###. #...# #...# #...# .###.", "p": "..... ..... ####. #...# ####. #.... #....",
    "q": "..... ..... .##.# #..## .#### ....# ....#", "r": "..... ..... #.##. ##..# #.... #.... #....",
    "s": "..... ..... .###. #.... .###. ....# ####.", "t": ".#... .#... ###.. .#... .#... .#..# ..##.",
    "u": "..... ..... #...# #...# #...# #..## .##.#", "v": "..... ..... #...# #...# #...# .#.#. ..#..",
    "w": "..... ..... #...# #...# #.#.# #.#.# .#.#.", "x": "..... ..... #...# .#.#. ..#.. .#.#. #...#",
    "y": "..... ..... #...# #...# .#### ....# .###.", "z": "..... ..... ##### ...#. ..#.. .#... #####",
    "0": ".###. #...# #..## #.#.# ##..# #...# .###.", "1": "..#.. .##.. ..#.. ..#.. ..#.. ..#.. .###.",
    "2": ".###. #...# ....# ...#. ..#.. .#... #####", "3": "##### ...#. ..#.. ...#. ....# #...# .###.",
    "4": "...#. ..##. .#.#. #..#. ##### ...#. ...#.", "5": "##### #.... ####. ....# ....# #...# .###.",
    "6": "..##. .#... #.... ####. #...# #...# .###.", "7": "##### ....# ...#. ..#.. .#... .#... .#...",
    "8": ".###. #...# #...# .###. #...# #...# .###.", "9": ".###. #...# #...# .#### ....# ...#. .##..",
    "+": "..... ..#.. ..#.. ##### ..#.. ..#.. .....", "!": "..#.. ..#.. ..#.. ..#.. ..#.. ..... ..#..",
    "?": ".###. #...# ....# ...#. ..#.. ..... ..#..", "-": "..... ..... ..... ##### ..... ..... .....",
    ".": "..... ..... ..... ..... ..... .##.. .##..", "'": "..#.. ..#.. .#... ..... ..... ..... .....",
    "&": ".##.. #..#. #.#.. .#... #.#.# #..#. .##.#", "/": "....# ....# ...#. ..#.. .#... #.... #....",
    " ": ". . . . . . .",
    "ρ": "..... .###. #...# #...# #...# ####. #....", "σ": "..... ..... .#### #..#. #...# #...# .###.",
    "λ": "#.... .#... ..#.. .#.#. #...# #...# #...#", "↑": "..#.. .###. #.#.# ..#.. ..#.. ..#.. ..#..",
    "↓": "..#.. ..#.. ..#.. ..#.. #.#.# .###. ..#..",
}


def die(msg):
    sys.exit("icon.py: " + msg)


def png(w, h, px):  # px: rows of (r, g, b, a) tuples
    raw = b"".join(b"\0" + bytes(c for p in row for c in p) for row in px)
    chunk = lambda t, d: struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) \
        + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")


def colour(hexs):
    m = re.fullmatch(r"#?([0-9a-fA-F]{6})", hexs or "") or die('a colour is "#rrggbb", not %r' % hexs)
    v = m.group(1)
    return tuple(int(v[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def letters(px, text, scale, ink, outline=None, cy=None):
    """Draws text centred on px (a grid of pixels), scale pixels a font dot, with a 1px outline."""
    h, w = len(px), len(px[0])
    glyphs = [FONT.get(ch, FONT["?"]).split(" ") for ch in text]
    tw = sum(5 * scale for _ in glyphs) + scale * (len(glyphs) - 1)
    x0, y0 = (w - tw) // 2, (h - 7 * scale) // 2 if cy is None else cy - 7 * scale // 2
    dots = set()
    for k, g in enumerate(glyphs):
        gx = x0 + k * 6 * scale
        for r, row in enumerate(g):
            for c, ch in enumerate(row):
                if ch == "#":
                    dots.update((gx + c * scale + i, y0 + r * scale + j) for i in range(scale) for j in range(scale))
    if outline:
        for x, y in dots:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if (x + dx, y + dy) not in dots and 0 <= x + dx < w and 0 <= y + dy < h:
                    px[y + dy][x + dx] = outline
    for x, y in dots:
        if 0 <= x < w and 0 <= y < h:
            px[y][x] = ink


def blank(w, h, fill=(0, 0, 0, 0)):
    return [[fill] * w for _ in range(h)]


def save(path, w, h, px, dry=False):
    if dry:
        print("would write", path)
        return
    os.makedirs(os.path.dirname(os.path.join(ROOT, path)), exist_ok=True)
    with open(os.path.join(ROOT, path), "wb") as f:
        f.write(png(w, h, px))
    print("wrote", path)


# --- skills

def skill_mark(sid):
    """Skill.mark() read off the .tres: its glyph, else the initials of its first two words, else its first two letters."""
    p = os.path.join(ROOT, "Skills/%s.tres" % sid)
    os.path.exists(p) or die("no Skills/%s.tres" % sid)
    text = open(p, encoding="utf-8").read()
    text = text[text.find("\n[resource]"):]  # the skill's own glyph and name, not an effect's (Dazzled)
    g = re.search(r'^glyph = "(.*)"$', text, re.M)
    if g and g.group(1):
        return g.group(1)
    n = re.search(r'^name = "(.*)"$', text, re.M)
    name = n.group(1) if n else sid
    words = name.split()
    return words[0][:1] + words[1][:1] if len(words) > 1 else name[:2]


def skill_icon(sid, text=None, dry=False):
    text = text or skill_mark(sid)
    px = blank(32, 32)
    letters(px, text[:2], 3 if len(text) == 1 else 2, (255, 255, 255, 255), (0, 0, 0, 150))
    save("%s/%s.png" % (SKILL_ICONS, sid), 32, 32, px, dry)


def missing_skill_icons():
    return sorted(f[:-5] for f in os.listdir(os.path.join(ROOT, "Skills")) if f.endswith(".tres")
                  and not os.path.exists(os.path.join(ROOT, SKILL_ICONS, f[:-5] + ".png")))


# --- items: 32x32 in colour (not tinted): the shape by slot and kind, the accent its trim (Item.trim())

ITEM_ICONS = "Icons/Items"
OUTLINE = (24, 20, 16, 255)
STEEL, CLOTH, LEATHER, GOLD = (150, 158, 172, 255), (190, 170, 130, 255), (130, 94, 62, 255), (232, 196, 90, 255)
WEIGHT_BODY = {"light": CLOTH, "medium": (146, 156, 176, 255), "heavy": (104, 110, 124, 255)}
RESTORE = {"hp": (216, 80, 90, 255), "energy": (224, 192, 80, 255), "mana": (96, 128, 224, 255)}
SYMBOLS = {"rho_up": "ρ↑", "rho_down": "ρ↓", "sigma_up": "σ↑", "sigma_down": "σ↓",
           "lambda_up": "λ↑", "lambda_down": "λ↓"}  # Modifiers.SYMBOLS


def tag_table():
    """Scripts/Tags.gd's COLOR, PARENT and PLAIN, read the way Tags.color() and Tags.mark() do."""
    t = open(os.path.join(ROOT, "Scripts/Tags.gd"), encoding="utf-8").read()
    body = t[t.index("const COLOR"):t.index("const NEUTRAL")]
    colours = {k: colour(v) for k, v in re.findall(r'&"(\w+)":\s*Color\("(#[0-9a-fA-F]{6})"\)', body)}
    parent = dict(re.findall(r'&"(\w+)": &"(\w+)"', re.search(r"const PARENT := \{(.*?)\}", t).group(1)))
    plain = set(re.findall(r'&"(\w+)"', t[t.index("const PLAIN"):t.index("const BROAD")]))
    return colours, parent, plain


def read_item(iid):
    p = os.path.join(ROOT, "Items/%s.tres" % iid)
    os.path.exists(p) or die("no Items/%s.tres" % iid)
    text = open(p, encoding="utf-8").read()
    text = text[text.find("\n[resource]"):]
    d = {k: v.strip().lstrip("&").strip('"') for k, v in re.findall(r"^(\w+) = (.+)$", text, re.M)}
    tags = re.search(r"^tags = Array\[StringName\]\(\[(.*)\]\)", text, re.M)
    d["tags"] = re.findall(r'&"(\w+)"', tags.group(1)) if tags else []
    d.setdefault("slot", "armor")
    return d


def item_trim(it):
    """Item.trim_tag() and its colour: the emblem first, then the tags, skipping plain words and weights (Tags.mark())."""
    colours, parent, plain = tag_table()
    weights = ("light", "medium", "heavy")
    for t in ([it["emblem"]] if it.get("emblem") else []) + it["tags"]:
        if (t in colours or parent.get(t) in colours) and t not in plain and t not in weights and parent.get(t) not in weights:
            return t, colours.get(t) or colours[parent[t]]
    return "", None


class Canvas:
    def __init__(self):
        self.px = blank(32, 32)

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if 0 <= x < 32 and 0 <= y < 32:
                    self.px[y][x] = c

    def disc(self, cx, cy, r, c):
        for y in range(32):
            for x in range(32):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                    self.px[y][x] = c

    def line(self, x0, y0, x1, y1, c, w=1):
        n = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(n + 1):
            x, y = round(x0 + (x1 - x0) * i / n) - w // 2, round(y0 + (y1 - y0) * i / n) - w // 2
            self.rect(x, y, x + w - 1, y + w - 1, c)

    def outline(self):
        out = [r[:] for r in self.px]
        for y in range(32):
            for x in range(32):
                if not self.px[y][x][3] and any(0 <= x + dx < 32 and 0 <= y + dy < 32 and self.px[y + dy][x + dx][3]
                                                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    out[y][x] = OUTLINE
        self.px = out


def shade(c, f):
    return tuple(min(255, int(v * f)) for v in c[:3]) + (255,)


def item_icon(iid, dry=False):
    it = read_item(iid)
    tags, slot = it["tags"], it["slot"]
    _, trim = item_trim(it)
    cv = Canvas()
    if it.get("emblem"):  # a plaque by its kind, in its trim, bearing its symbol or its tag's initial
        c = trim or GOLD
        scope = it.get("scope", "")
        dark = shade(c, 0.28)
        if scope == "sigil":
            for y in range(32):
                for x in range(32):
                    if abs(x - 15.5) + abs(y - 15.5) <= 15:
                        cv.px[y][x] = dark
        elif scope == "insignia":
            cv.disc(15.5, 15.5, 14, dark)
        elif scope == "crest":
            cv.rect(4, 3, 27, 18, dark)
            for y in range(19, 30):
                cv.rect(4 + (y - 18), y, 27 - (y - 18), y, dark)
        else:
            cv.rect(4, 4, 27, 27, dark)
        cv.outline()
        sym = SYMBOLS.get(it["emblem"])
        letters(cv.px, sym or it["emblem"][:1].upper(), 2 if sym else 3, c, shade(c, 0.2))
    elif slot == "armor":
        body = next((WEIGHT_BODY[w] for w in WEIGHT_BODY if w in tags), CLOTH)
        cv.rect(3, 5, 28, 12, body)  # shoulders
        cv.rect(7, 12, 24, 28, body)
        cv.rect(13, 5, 18, 8, (0, 0, 0, 0))  # the neck
        cv.rect(7, 22, 24, 23, trim or shade(body, 0.7))  # a band of trim
        cv.rect(3, 5, 28, 6, shade(body, 1.15))
        cv.outline()
    elif slot == "weapon":
        dt = it.get("damage_tag", "")
        if dt == "pierce":  # a dagger or a spear
            cv.line(9, 23, 22, 10, STEEL, 3)
            cv.line(22, 10, 26, 6, STEEL, 1)
            cv.line(7, 25, 10, 22, LEATHER, 3)
            cv.line(11, 19, 15, 23, trim or GOLD, 2)
        elif dt == "blunt":  # a mace or a staff
            cv.line(7, 25, 22, 10, LEATHER, 3)
            cv.disc(23, 9, 5, trim or STEEL)
            cv.disc(23, 9, 2, shade(trim or STEEL, 1.3))
        else:  # slash: a sword
            cv.line(11, 21, 25, 7, STEEL, 4)
            cv.line(9, 23, 12, 20, LEATHER, 3)
            cv.line(9, 17, 16, 24, trim or GOLD, 2)
        cv.outline()
    elif "ring" in tags:
        cv.disc(15.5, 18, 9, GOLD)
        cv.disc(15.5, 18, 5, (0, 0, 0, 0))
        cv.disc(15.5, 8, 4, trim or (200, 90, 110, 255))
        cv.outline()
    elif "book" in tags:
        cv.rect(6, 4, 25, 27, shade(trim, 0.6) if trim else LEATHER)
        cv.rect(6, 4, 9, 27, shade(trim or LEATHER, 0.4))
        cv.rect(13, 9, 21, 12, trim or GOLD)
        cv.outline()
    elif "shackles" in tags:
        for cx in (10, 22):
            cv.disc(cx, 17, 6, STEEL)
            cv.disc(cx, 17, 3, (0, 0, 0, 0))
        cv.rect(14, 16, 18, 18, STEEL)
        cv.outline()
    elif int(it.get("hearts", "0") or 0) > 0:  # a heart
        red = (210, 60, 80, 255)
        cv.disc(10.5, 11, 6, red)
        cv.disc(21.5, 11, 6, red)
        for y in range(12, 28):
            k = int((y - 12) * 0.65)
            cv.rect(5 + k, y, 27 - k, y, red)
        if slot == "trinket" and trim:
            cv.rect(13, 12, 18, 13, trim)
        cv.outline()
    elif "potion" in tags or it.get("restores"):  # a flask of what it gives back
        liquid = RESTORE.get(it.get("restores", ""), trim or RESTORE["mana"])
        cv.disc(15.5, 20, 9, (200, 220, 230, 255))
        cv.rect(13, 5, 18, 12, (200, 220, 230, 255))
        cv.disc(15.5, 21, 7, liquid)
        cv.rect(12, 3, 19, 5, LEATHER)
        cv.outline()
    else:  # a pouch (a consumable or any other trinket), tied in its trim
        cv.disc(15.5, 20, 9, LEATHER)
        cv.rect(12, 7, 19, 12, LEATHER)
        cv.rect(11, 10, 20, 11, trim or GOLD)
        cv.outline()
    save("%s/%s.png" % (ITEM_ICONS, iid), 32, 32, cv.px, dry)


def item_ids():
    return sorted(f[:-5] for f in os.listdir(os.path.join(ROOT, "Items")) if f.endswith(".tres"))


def missing_item_icons():
    return [i for i in item_ids() if not os.path.exists(os.path.join(ROOT, ITEM_ICONS, i + ".png"))]


def check_items():
    problems = ["Items/%s.tres: no %s/%s.png (python3 Util/icon.py item %s)" % (i, ITEM_ICONS, i, i) for i in missing_item_icons()]
    d = os.path.join(ROOT, ITEM_ICONS)
    for f in os.listdir(d) if os.path.isdir(d) else []:
        if f.endswith(".png") and not os.path.exists(os.path.join(ROOT, "Items", f[:-4] + ".tres")):
            problems.append("%s/%s: an icon for no item (renamed? move it with the item)" % (ITEM_ICONS, f))
    return problems


# --- effects: an icon on a unit card's row of what's on it, about a chip's height, white on clear (tinted there)

SHAPES = {  # pixel art by rows, '#' set
    "eye": "...#####... .##.....##. #...###...# #..#####..# #...###...# .##.....##. ...#####...",
}
EFFECT_ICONS = "Icons/Effects"


def effect(eid, shape=None, text=None, dry=False):
    if shape:
        shape in SHAPES or die("--shape: one of %s" % ", ".join(SHAPES))
        rows = SHAPES[shape].split(" ")
        w, h = len(rows[0]), len(rows)
        px = [[(255, 255, 255, 255) if ch == "#" else (0, 0, 0, 0) for ch in row] for row in rows]
    else:
        w, h = 13, 9
        px = blank(w, h)
        letters(px, (text or eid[:2])[:2], 1, (255, 255, 255, 255))
    save("%s/%s.png" % (EFFECT_ICONS, eid), w, h, px, dry)


# --- tiles and units

def tile(tid, rgb, text=None, dry=False):
    dark = tuple(int(c * 0.7) for c in rgb[:3]) + (255,)
    px = blank(32, 32, rgb)
    for i in range(32):
        px[0][i] = px[31][i] = px[i][0] = px[i][31] = dark
    if text:
        letters(px, text[:2], 1, dark)
    save("Tiles/%s.png" % tid, 32, 32, px, dry)


def unit(name, rgb, text=None, dry=False):
    w, h = 20, 25
    dark = tuple(int(c * 0.45) for c in rgb[:3]) + (255,)
    px = blank(w, h)
    for y in range(h):
        for x in range(w):
            head = (x - 9.5) ** 2 + (y - 5.5) ** 2 <= 16
            body = 11 <= y <= 23 and abs(x - 9.5) <= 3 + (y - 11) * 0.35
            if head or body:
                px[y][x] = rgb
    for y in range(h):  # a dark edge round the figure
        for x in range(w):
            if px[y][x][3] and any(not (0 <= x + dx < w and 0 <= y + dy < h) or not px[y + dy][x + dx][3]
                                   for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                px[y][x] = dark
    if text:
        letters(px, text[:1], 1, dark, cy=17)
    save("Units/%s.png" % name, w, h, px, dry)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("skill", help="Icons/Skills/<id>.png")
    s.add_argument("id")
    s.add_argument("--text", help="up to 2 characters (default: its mark)")
    sub.add_parser("skills", help="every skill missing an icon")
    for kind in ("tile", "unit"):
        k = sub.add_parser(kind, help="Tiles/<id>.png" if kind == "tile" else "Units/<Name>.png")
        k.add_argument("id")
        k.add_argument("--color", required=True, help='"#rrggbb"')
        k.add_argument("--text")
    i = sub.add_parser("item", help="Icons/Items/<id>.png")
    i.add_argument("id")
    sub.add_parser("items", help="every item missing an icon")
    sub.add_parser("check", help="fail an item without an icon")
    e = sub.add_parser("effect", help="Icons/Effects/<id>.png")
    e.add_argument("id")
    e.add_argument("--shape", help="drawn: %s" % ", ".join(SHAPES))
    e.add_argument("--text", help="or up to 2 letters (default: the id's first two)")
    for k in sub.choices.values():
        k.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    if a.cmd == "skill":
        skill_icon(a.id, a.text, a.dry_run)
    elif a.cmd == "skills":
        for sid in missing_skill_icons():
            skill_icon(sid, None, a.dry_run)
    elif a.cmd == "item":
        item_icon(a.id, a.dry_run)
    elif a.cmd == "items":
        for iid in missing_item_icons():
            item_icon(iid, a.dry_run)
    elif a.cmd == "check":
        problems = check_items()
        print("\n".join(problems) or "icon.py: ok")
        sys.exit(1 if problems else 0)
    elif a.cmd == "effect":
        effect(a.id, a.shape, a.text, a.dry_run)
    elif a.cmd == "tile":
        tile(a.id, colour(a.color), a.text, a.dry_run)
    else:
        unit(a.id, colour(a.color), a.text, a.dry_run)


if __name__ == "__main__":
    main()
