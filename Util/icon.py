#!/usr/bin/env python3
"""Gambeson placeholder art: plain PNGs standing in until real art replaces the file (same path, any size).

  python3 Util/icon.py skill kick [--text Kk]      # Icons/Skills/kick.png: its mark (Skill.mark()) in pixel letters
  python3 Util/icon.py skills                      # every skill still missing one
  python3 Util/icon.py tile sand --color "#d8c48a" [--text Sa]   # Tiles/sand.png: 32x32 ground, flat colour
  python3 Util/icon.py unit Blinthe --color "#b07acc" [--text B]  # Units/Blinthe.png: a 20x25 figure

Skill icons are white on clear, so the skills screen tints them by state (learned, open, a stub); draw real
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
    for k in sub.choices.values():
        k.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    if a.cmd == "skill":
        skill_icon(a.id, a.text, a.dry_run)
    elif a.cmd == "skills":
        for sid in missing_skill_icons():
            skill_icon(sid, None, a.dry_run)
    elif a.cmd == "tile":
        tile(a.id, colour(a.color), a.text, a.dry_run)
    else:
        unit(a.id, colour(a.color), a.text, a.dry_run)


if __name__ == "__main__":
    main()
