#!/usr/bin/env python3
"""Gambeson sprite sheet cutter: one PNG per sprite, named by its average colour so a folder sorts by hue.

  python3 Util/sprites.py cut sortme/sheet-*.png [--out Assets/sorted] [--min-size 4] [--dry-run]
  python3 Util/sprites.py check                    # synthetic sheet through both decoders; Assets/sorted names and imports

A sprite is an 8-connected island (diagonals attach) of pixels with alpha > 0, clipped to its bounding box.
Each lands in <out>/<sheet-stem>/<hex>-<colour>.png: hex is the alpha-weighted average RGB of its pixels,
colour the nearest of a small named palette (red orange yellow green cyan blue purple pink brown gray black
white), e.g. 7a3f2c-brown.png. A clash (same hex) gets -2, -3 in reading order (top to bottom, left to right).
The sheet is only read (decoded to RGBA in memory, never edited); re-running overwrites by name and leaves
stale files. Pillow decodes if importable (any mode); else a plain zlib reader (8-bit PNG only). Output is
always written with zlib. Godot imports the new PNGs on the next `godot --headless --path . --import`; commit
the .png.import beside each.
"""
import argparse, os, re, struct, sys, tempfile, zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = "Assets/sorted"
PALETTE = {  # name: a typical RGB; nearest (redmean distance) wins
    "red": (200, 40, 40), "orange": (230, 140, 30), "yellow": (230, 210, 50), "green": (50, 160, 60),
    "cyan": (60, 200, 210), "blue": (50, 80, 200), "purple": (140, 60, 170), "pink": (240, 150, 190),
    "brown": (120, 75, 40), "gray": (128, 128, 128), "black": (15, 15, 15), "white": (240, 240, 240),
}


def die(msg):
    sys.exit("sprites.py: " + msg)


# ---- PNG in and out -------------------------------------------------------------------------------

def decode_plain(data):
    """(w, h, RGBA bytes) from a non-interlaced 8-bit PNG (gray, RGB, palette, gray+alpha, RGBA)."""
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        die("not a PNG")
    pos, idat, plte, trns, head = 8, [], b"", b"", None
    while pos < len(data):
        n, kind = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + n]
        pos += 12 + n
        if kind == b"IHDR":
            head = struct.unpack(">IIBBBBB", body)
        elif kind == b"PLTE":
            plte = body
        elif kind == b"tRNS":
            trns = body
        elif kind == b"IDAT":
            idat.append(body)
    w, h, depth, ctype, _, _, inter = head
    if depth != 8 or inter or ctype not in (0, 2, 3, 4, 6):
        die("this PNG needs Pillow (pip install pillow): only 8-bit, non-interlaced is read without it")
    ch = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[ctype]
    stride, raw = w * ch, zlib.decompress(b"".join(idat))
    rows, prev = [], bytearray(stride)
    for y in range(h):
        f, cur = raw[y * (stride + 1)], bytearray(raw[y * (stride + 1) + 1:(y + 1) * (stride + 1)])
        for i in range(stride):
            a = cur[i - ch] if i >= ch else 0
            b, c = prev[i], (prev[i - ch] if i >= ch else 0)
            if f == 1: cur[i] = (cur[i] + a) & 255
            elif f == 2: cur[i] = (cur[i] + b) & 255
            elif f == 3: cur[i] = (cur[i] + (a + b) // 2) & 255
            elif f == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                cur[i] = (cur[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append(cur)
        prev = cur
    out = bytearray()
    for cur in rows:
        for x in range(w):
            px = cur[x * ch:(x + 1) * ch]
            if ctype == 6: out += px
            elif ctype == 4: out += bytes((px[0], px[0], px[0], px[1]))
            elif ctype == 2: out += bytes(px) + b"\xff"
            elif ctype == 0: out += bytes((px[0], px[0], px[0], 255))
            else: out += plte[px[0] * 3:px[0] * 3 + 3] + bytes((trns[px[0]] if px[0] < len(trns) else 255,))
    return w, h, bytes(out)


def load(path, plain=False):
    """(w, h, RGBA bytes) of the sheet, as a copy converted in memory."""
    if not plain:
        try:
            from PIL import Image
            im = Image.open(path).convert("RGBA")
            return im.width, im.height, im.tobytes()
        except ImportError:
            pass
    with open(path, "rb") as f:
        return decode_plain(f.read())


def encode(w, h, rgba):
    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body))
    raw = b"".join(b"\x00" + rgba[y * w * 4:(y + 1) * w * 4] for y in range(h))
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) \
        + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")


# ---- finding and naming sprites ---------------------------------------------------------------------

def find(w, h, rgba):
    """Sprites as dicts (box, count, avg RGB, RGBA crop), in reading order of their first pixel."""
    seen = bytearray(w * h)
    sprites = []
    for start in range(w * h):
        if seen[start] or rgba[start * 4 + 3] == 0:
            continue
        seen[start] = 1
        stack, px = [start], []
        while stack:
            i = stack.pop()
            px.append(i)
            x, y = i % w, i // w
            for ny in (y - 1, y, y + 1):
                if 0 <= ny < h:
                    for nx in (x - 1, x, x + 1):
                        j = ny * w + nx
                        if 0 <= nx < w and not seen[j] and rgba[j * 4 + 3]:
                            seen[j] = 1
                            stack.append(j)
        xs, ys = [i % w for i in px], [i // w for i in px]
        x0, y0, x1, y1 = min(xs), min(ys), max(xs), max(ys)
        crop = bytearray((x1 - x0 + 1) * (y1 - y0 + 1) * 4)
        wsum = [0, 0, 0]
        weight = 0
        for i in px:
            a = rgba[i * 4 + 3]
            o = ((i // w - y0) * (x1 - x0 + 1) + i % w - x0) * 4
            crop[o:o + 4] = rgba[i * 4:i * 4 + 4]
            weight += a
            for c in range(3):
                wsum[c] += rgba[i * 4 + c] * a
        avg = tuple(int(round(s / weight)) for s in wsum)
        sprites.append({"box": (x0, y0, x1, y1), "count": len(px), "avg": avg, "size": (x1 - x0 + 1, y1 - y0 + 1), "crop": bytes(crop)})
    return sprites


def colour_name(rgb):
    def dist(p):
        r = (rgb[0] + p[0]) / 2
        return (2 + r / 256) * (rgb[0] - p[0]) ** 2 + 4 * (rgb[1] - p[1]) ** 2 + (2 + (255 - r) / 256) * (rgb[2] - p[2]) ** 2
    return min(PALETTE, key=lambda n: dist(PALETTE[n]))


def names(sprites):
    """Unique file names, in order: <hex>-<colour>.png, then -2, -3 on a clash."""
    used, out = {}, []
    for s in sprites:
        stem = "%02x%02x%02x-%s" % (*s["avg"], colour_name(s["avg"]))
        used[stem] = used.get(stem, 0) + 1
        out.append(stem + ("" if used[stem] == 1 else "-%d" % used[stem]) + ".png")
    return out


def cut_sheet(path, out_root, min_size=4, dry=False, plain=False, quiet=False):
    w, h, rgba = load(path, plain)
    sprites = [s for s in find(w, h, rgba) if s["count"] >= min_size]
    stem = os.path.splitext(os.path.basename(path))[0]
    folder = os.path.join(out_root, stem)
    files = names(sprites)
    if not dry:
        os.makedirs(folder, exist_ok=True)
        for s, f in zip(sprites, files):
            with open(os.path.join(folder, f), "wb") as fh:
                fh.write(encode(*s["size"], s["crop"]))
    quiet or print("%s: %dx%d, %d sprite(s) -> %s%s" % (path, w, h, len(sprites), folder, " (dry run)" if dry else ""))
    return files


def cut(a):
    for p in a.sheets:
        os.path.isfile(p) or die("no sheet " + p)
    for p in a.sheets:
        cut_sheet(p, a.out, a.min_size, a.dry_run)
    if not a.dry_run:
        print("next: godot --headless --path . --import, then commit the PNGs and their .import files")
    return 0


# ---- check ---------------------------------------------------------------------------------------

def check(_a=None):
    problems = []
    # a synthetic 12x6 sheet: a 2x2 red block; a green pair touching only diagonally; a lone blue speck;
    # a second red block (same hex, so -2); a pair of unequal alpha (weighted average).
    w, h = 12, 6
    px = bytearray(w * h * 4)

    def put(x, y, rgba):
        px[(y * w + x) * 4:(y * w + x) * 4 + 4] = bytes(rgba)
    for x, y in ((0, 0), (1, 0), (0, 1), (1, 1)):
        put(x, y, (200, 0, 0, 255))
    put(4, 0, (0, 160, 0, 255))
    put(5, 1, (0, 160, 0, 255))
    put(9, 5, (0, 0, 255, 255))
    for x, y in ((6, 3), (7, 3), (6, 4), (7, 4)):
        put(x, y, (200, 0, 0, 255))
    put(10, 0, (200, 200, 200, 200))
    put(11, 0, (0, 0, 0, 50))  # alpha-weighted: 200*200/250 = 160 (a0), not the plain 100
    sheet = encode(w, h, bytes(px))
    with tempfile.TemporaryDirectory() as tmp:
        src = os.path.join(tmp, "sheet-probe.png")
        with open(src, "wb") as f:
            f.write(sheet)
        # reading order of each sprite's first pixel; the speck (1 px) is cut by min-size 2
        want = ["c80000-red.png", "00a000-green.png", "a0a0a0-gray.png", "c80000-red-2.png"]
        got = {plain: cut_sheet(src, os.path.join(tmp, "o%d" % plain), 2, plain=plain, quiet=True) for plain in (True, False)}
        dflt = cut_sheet(src, os.path.join(tmp, "o3"), quiet=True)  # default 4: only the two 4-px blocks
        if dflt != ["c80000-red.png", "c80000-red-2.png"]:
            problems.append("default min-size cut %s, wanted the two blocks only" % dflt)
        kept = cut_sheet(src, os.path.join(tmp, "o2"), 1, quiet=True)  # --min-size 1 keeps the speck
        if len(kept) != len(want) + 1 or "0000ff-blue.png" not in kept:
            problems.append("--min-size 1 should keep the 1-px speck, got %s" % kept)
        if got[True] != want:
            problems.append("synthetic sheet cut to %s, wanted %s" % (got[True], want))
        if got[True] != got[False]:
            problems.append("Pillow and the plain decoder disagree: %s vs %s" % (got[False], got[True]))
        for f in got[True]:
            with open(os.path.join(tmp, "o1", "sheet-probe", f), "rb") as fh:
                size = decode_plain(fh.read())[:2]
            if f.startswith("00a000") and size != (2, 2):
                problems.append("diagonal pair clipped to %s, wanted 2x2" % (size,))
            if f.startswith("c80000-red.png") and size != (2, 2):
                problems.append("block clipped to %s, wanted 2x2" % (size,))
    # the committed output: every name is <hex>-<colour>[-n].png, and imported
    sorted_dir = os.path.join(ROOT, OUT)
    pat = re.compile(r"^[0-9a-f]{6}-(%s)(-\d+)?\.png$" % "|".join(PALETTE))
    for dirpath, _, files in os.walk(sorted_dir):
        for f in files:
            if f.endswith(".png"):
                rel = os.path.relpath(os.path.join(dirpath, f), ROOT)
                if not pat.match(f):
                    problems.append("%s: not named <hex>-<colour>.png (python3 Util/sprites.py cut)" % rel)
                if not os.path.exists(os.path.join(dirpath, f + ".import")):
                    problems.append("%s: not imported (godot --headless --path . --import)" % rel)
    for p in problems:
        print(p)
    print("sprites.py check: %s" % ("%d problem(s)" % len(problems) if problems else "ok"))
    return 1 if problems else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("cut", help="cut sheets into one PNG per sprite, named by average colour")
    c.add_argument("sheets", nargs="+", help="sheet PNGs (read only)")
    c.add_argument("--out", default=os.path.join(ROOT, OUT), help="output root (default Assets/sorted; a folder per sheet)")
    c.add_argument("--min-size", type=int, default=4, help="skip islands under this many pixels, so area < 4 is skipped by default (1 keeps every speck)")
    c.add_argument("--dry-run", action="store_true", help="list, write nothing")
    sub.add_parser("check", help="synthetic sheet through both decoders; Assets/sorted names and imports")
    a = ap.parse_args()
    sys.exit(cut(a) if a.cmd == "cut" else check(a))


if __name__ == "__main__":
    main()
