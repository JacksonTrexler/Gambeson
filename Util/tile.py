#!/usr/bin/env python3
"""Gambeson tile authoring: a kind of ground (Terrain/<id>.tres), its placeholder art (Tiles/<id>.png), and
optionally a tile carrying it in a scene's tile set, ready to paint in the editor.

  python3 Util/tile.py new sand --tags sand,loose,rough --enter 2 --color "#d8c48a" [--glyph Sa] \\
      [--effect "stat=movement amount=-1"] [--afflicts "stat=luck amount=-1 name=Sandblind" --turns 2] \\
      [--at-end "stat=regen amount=0.1"] [--set exit=1] [--set depth=2] [--scene museum] [--human] [--dry-run]
  python3 Util/tile.py check

Terrain.gd's fields are the vocabulary: --set key=value sets any of them (concealment, looks_like, dice,
damage_tags, passes, drag, brittle...). Effects use Effect.gd's stats ("stat=mitigate amount=0.5 tags=fire").
A tile Battle.paint()s gets its art from Terrain.look, so a scene needs --scene only to paint it by hand.
Replace Tiles/<id>.png with art any time (32x32). An AI-made name gets " ??" (CLAUDE.md); --human for a
name a person gave.
"""
import argparse, re, sys

from tres import Doc, ai_name, die, exists, files, import_project, items, literal, read, readers, sections, typed, write, add_ext, free_id
import icon

TERRAIN = "res://Scripts/Terrain.gd"
EFFECT = "res://Scripts/Effect.gd"


def fields():  # Terrain.gd's @export vars: what --set may name
    return set(re.findall(r"^@export(?:_\w+\([^)]*\))? var (\w+)", read("Scripts/Terrain.gd"), re.M))


def terrain_tres(a):
    d = Doc('[gd_resource type="Resource" script_class="Terrain" format=3]')
    d.props = ["script = " + d.res("Script", TERRAIN), 'name = "%s"' % ai_name(a.name, a.human),
               "look = " + d.res("Texture2D", "res://Tiles/%s.png" % a.id)]
    for key in ("enter", "turns"):
        if getattr(a, key) is not None:
            d.props.append("%s = %d" % (key, getattr(a, key)))
    if a.tags:
        d.props.append("tags = " + literal("tags", a.tags))
    for key, specs in (("effects", a.effect), ("afflicts", a.afflicts), ("at_end", a.at_end)):
        if specs:
            refs = [d.effect("Effect_%s_%d" % (key, i + 1), s, a.human) for i, s in enumerate(specs)]
            d.props.append("%s = %s" % (key, typed(EFFECT, d, refs)))
    known = fields()
    for kv in a.set:
        k, _, v = kv.partition("=")
        k in known or die("--set %s: Terrain.gd has no such field (%s)" % (k, ", ".join(sorted(known))))
        d.props.append("%s = %s" % (k, literal(k, v)))
    return d.text()


def add_to_scene(scene, tid):
    p = "Scenes/%s.tscn" % scene
    exists(p) or die("--scene %s: no %s" % (scene, p))
    text = read(p)
    secs = sections(text)
    ts = next((s for s in secs if s["kind"] == "sub_resource" and s["attrs"].get("type") == "TileSet"), None) or die("%s has no TileSet" % p)
    taken = [int(m) for m in re.findall(r"^sources/(\d+) = ", text, re.M)]
    n = max(taken) + 1 if taken else 0
    tex, ter = free_id(secs, "tile_" + tid), free_id(secs, "t_" + tid)
    text = add_ext(text, '[ext_resource type="Texture2D" path="res://Tiles/%s.png" id="%s"]\n[ext_resource type="Resource" path="res://Terrain/%s.tres" id="%s"]' % (tid, tex, tid, ter))
    atlas = free_id(sections(text), "Atlas_" + tid)
    block = '[sub_resource type="TileSetAtlasSource" id="%s"]\ntexture = ExtResource("%s")\ntexture_region_size = Vector2i(32, 32)\n0:0/0 = 0\n0:0/0/custom_data_0 = ExtResource("%s")\n\n' % (atlas, tex, ter)
    head = '[sub_resource type="TileSet" id="%s"]' % ts["attrs"]["id"]
    text = text.replace(head, block + head, 1)
    last = list(re.finditer(r"^sources/\d+ = .*$", text, re.M))[-1]
    text = text[:last.end()] + '\nsources/%d = SubResource("%s")' % (n, atlas) + text[last.end():]
    return p, text, n


def new(a):
    tid = a.id
    re.fullmatch(r"[a-z][a-z0-9_]*", tid) or die("the id is a file name: lower_snake (sand, hot_coals)")
    exists("Terrain/%s.tres" % tid) and die("Terrain/%s.tres exists" % tid)
    a.name = a.name or tid.replace("_", " ").title()
    out = [("Terrain/%s.tres" % tid, terrain_tres(a))]
    if a.scene:
        p, text, n = add_to_scene(a.scene, tid)
        if a.dry_run:
            print("--- would add to %s: source %d, a tile carrying Terrain/%s.tres ---" % (p, n, tid))
        else:
            out.append((p, text))
            print("%s: source %d paints it" % (p, n))
    for p, text in out:
        write(p, text, a.dry_run)
    for t in filter(None, (a.tags or "").split(",")):  # what its tags will do: the rules that ask about each
        r = readers(t.strip())
        print("tag %s: %s" % (t, "read by " + ", ".join(r) if r else "no rule reads it yet - flavour, or wire one (new-mechanic)"))
    icon.tile(tid, icon.colour(a.color), a.glyph or a.name[:2], a.dry_run)
    if a.dry_run:
        return 0
    import_project()
    print("\nnext: a test (Tests/<id>_test.gd: b.paint(c, load(\"res://Terrain/%s.tres\")), then what it does to a unit on it),"
          " the Glossary if it brings a new word, then `python3 Util/tile.py check` and the tests (.claude/skills/new-tile)" % tid)
    return check()


def check(_a=None):
    problems = []
    for p in files("Terrain", ".tres"):
        tid = p[len("Terrain/"):-5]
        text = read(p)
        m = re.search(r'^look = ExtResource\("([^"]+)"\)', text, re.M)
        if m and not exists("Tiles/%s.png" % tid) and "Tiles/%s.png" % tid in text:
            problems.append("%s: its look, Tiles/%s.png, is missing (python3 Util/icon.py tile %s --color ...)" % (p, tid, tid))
        if exists("Tiles/%s.png" % tid) and not exists("Tiles/%s.png.import" % tid):
            problems.append("Tiles/%s.png: not imported (godot --headless --path . --import)" % tid)
    for p in files("Tiles", ".png"):
        tid = p[len("Tiles/"):-4]
        if tid != "placeholder" and not exists("Terrain/%s.tres" % tid):
            problems.append("%s: art for no terrain (renamed? move it with Terrain/%s.tres)" % (p, tid))
    for p in problems:
        print(p)
    print("tile.py check: %s" % ("%d problem(s)" % len(problems) if problems else "ok"))
    return 1 if problems else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    n = sub.add_parser("new", help="a kind of ground, its art, and optionally a tile in a scene")
    n.add_argument("id", help="file name: sand -> Terrain/sand.tres, Tiles/sand.png")
    n.add_argument("--name", help="shown name (default: from the id; gets ?? unless --human)")
    n.add_argument("--human", action="store_true", help="a person named it: no ??")
    n.add_argument("--tags", help="comma separated: water,wet / rough / sticky / beneficial / detrimental")
    n.add_argument("--enter", type=int, help="movement to step on (default 1)")
    n.add_argument("--effect", action="append", default=[], help="on whoever stands on it: \"stat=regen amount=0.1\"")
    n.add_argument("--afflicts", action="append", default=[], help="put on whoever steps on it, for --turns")
    n.add_argument("--at-end", dest="at_end", action="append", default=[], help="put on whoever ends its side's turn on it")
    n.add_argument("--turns", type=int)
    n.add_argument("--set", action="append", default=[], help="any other Terrain field: key=value (exit=1, depth=2, concealment=2)")
    n.add_argument("--color", default="#8a8f7a", help="the placeholder's colour")
    n.add_argument("--glyph", help="up to 2 letters on the placeholder (default: its name's first two)")
    n.add_argument("--scene", help="also a tile carrying it in Scenes/<scene>.tscn's tile set (museum, meadows)")
    n.add_argument("--dry-run", action="store_true")
    sub.add_parser("check", help="every terrain's art is there and imported")
    a = ap.parse_args()
    sys.exit(new(a) if a.cmd == "new" else check(a))


if __name__ == "__main__":
    main()
