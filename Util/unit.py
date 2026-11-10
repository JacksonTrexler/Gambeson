#!/usr/bin/env python3
"""Gambeson unit authoring: a unit (Scenes/<id>.tscn) with its bio, stats, skills and sprite, optionally
placed in a battle.

  python3 Util/unit.py new blinthe --name Blinthe --human --role bard --level 16 --faction blinthe \\
      --behaviour timid --appearance Bard --adjectives Charming,Rotten --properties rotting \\
      --clout lancin=2,nemes=1 --skill bandwagon:3 --skill molothrus:2 --stats "cha=18,wis=12" \\
      [--bio "A line or two."] [--tags monster] [--vibe "Smouldering"] [--aura -1] [--tends loyal] \\
      [--strategy weakest] [--intention "Purge evil"] [--hp 30] [--energy 12] [--look Doebour | --color "#b07acc"] \\
      [--into museum --at 5,3 [--side nemes]] [--dry-run]
  python3 Util/unit.py faction blinthe --name "Blinthe's Own" --color "#b07acc" [--allies lancin] [--human]
  python3 Util/unit.py check

Bio (Scripts/Bio.gd): behaviour (timid, brave, aggressive, helpful, stoic) drives its AI; appearance and
adjectives are how it looks to whoever can't make out its class; properties (Properties/*.tres:
mechanic.py property) are always on it; clout is its standing with sides. An AI-made name gets " ??"
(CLAUDE.md): shown through its nick, as node names can't carry it. .claude/skills/new-unit has the process.
"""
import argparse, re, sys

from tres import Doc, ai_name, die, exists, files, import_project, literal, names, read, sections, snake, strings, typed, write, add_ext, free_id
import icon

UNIT, BIO, SLOT, FACTION = "res://Scenes/unit.tscn", "res://Scripts/Bio.gd", "res://Scripts/Slot.gd", "res://Scripts/Faction.gd"
BEHAVIOURS = ("timid", "brave", "aggressive", "helpful", "stoic")
SHORT = {"str": "strength", "dex": "dexterity", "con": "constitution", "int": "intelligence", "wis": "wisdom", "cha": "charisma"}


def pairs(v, what):
    out = []
    for kv in filter(None, (v or "").split(",")):
        k, _, n = kv.partition("=")
        re.fullmatch(r"-?\d+", n.strip()) or die("%s: want name=number, not %r" % (what, kv))
        out.append((k.strip(), int(n)))
    return out


def faction_ref(d, f):
    exists("Factions/%s.tres" % f) or die("no Factions/%s.tres (python3 Util/unit.py faction %s ...)" % (f, f))
    return d.res("Resource", "res://Factions/%s.tres" % f)


def bio(d, a):
    props = []
    if a.behaviour:
        a.behaviour in BEHAVIOURS or die("--behaviour: one of %s (a new one goes in Bio.BEHAVIOURS and AI.act())" % ", ".join(BEHAVIOURS))
        props.append('behaviour = &"%s"' % a.behaviour)
    if a.appearance:
        props.append('appearance = "%s"' % a.appearance)
    if a.adjectives:
        props.append("adjectives = " + strings(a.adjectives))
    refs = []
    for p in filter(None, (a.properties or "").split(",")):
        exists("Properties/%s.tres" % p) or die("--properties %s: no Properties/%s.tres (python3 Util/mechanic.py property %s ...)" % (p, p, p))
        refs.append(d.res("Resource", "res://Properties/%s.tres" % p))
    if refs:
        props.append("properties = " + typed("res://Scripts/Property.gd", d, refs))
    clout = pairs(a.clout, "--clout")
    if clout:
        props.append("clout = Dictionary[%s, int]({%s})" % (d.res("Script", FACTION), ", ".join("%s: %d" % (faction_ref(d, f), n) for f, n in clout)))
    if a.bio:
        props.append('text = "%s"' % a.bio.replace('"', '\\"'))
    return d.sub("Bio_%s" % a.id, BIO, props) if props else None


def unit_tscn(a, sprite):
    d = Doc("[gd_scene format=3]")
    d.res("PackedScene", UNIT)
    node = re.sub(r"[^A-Za-z0-9 _-]", "", a.name).strip() or a.id.title()
    p = []
    if ai_name(a.name, a.human) != a.name:
        p.append('nick = "%s"' % ai_name(a.name, a.human))  # node names can't carry the ??
    if a.faction:
        p.append("faction = " + faction_ref(d, a.faction))
    if a.role:
        exists("Roles/%s.tres" % a.role) or die("--role %s: no Roles/%s.tres" % (a.role, a.role))
        p.append("role = " + d.res("Resource", "res://Roles/%s.tres" % a.role))
    if a.race:
        exists("Races/%s.tres" % a.race) or die("--race %s: no Races/%s.tres" % (a.race, a.race))
        p.append("race = " + d.res("Resource", "res://Races/%s.tres" % a.race))
    if a.title:
        p.append('title = "%s"' % a.title)
    if a.level:
        p.append("level = %d" % a.level)
    if sprite:
        p.append("look = " + d.res("Texture2D", "res://Units/%s.png" % sprite))
    if a.tags:
        p.append("tags = " + names(a.tags))
    if a.vibe:
        p.append('vibe = "%s"' % a.vibe)
    if a.aura is not None:
        p.append("aura = %d" % a.aura)
    for key in ("tends",):
        if getattr(a, key):
            p.append('%s = &"%s"' % (key, getattr(a, key)))
    if a.intention:
        p.append('intention = "%s"' % a.intention)
    if a.strategy:
        p.append("strategy = " + names(a.strategy))
    b = bio(d, a)
    if b:
        p.append("bio = " + b)
    slots = []
    for spec in a.skill:
        sid, _, rank = spec.partition(":")
        exists("Skills/%s.tres" % sid) or die("--skill %s: no Skills/%s.tres" % (sid, sid))
        slots.append(d.sub("Slot_%s" % sid, SLOT, ["skill = " + d.res("Resource", "res://Skills/%s.tres" % sid), "rank = %d" % int(rank or 1)]))
    if slots:
        p.append("learned = " + typed(SLOT, d, slots))
    if a.hp:
        p.append("max_hp = %d" % a.hp)
    if a.energy:
        p.append("max_energy = %d" % a.energy)
    for k, v in pairs(a.stats, "--stats"):
        k = SHORT.get(k, k)
        k in SHORT.values() or die("--stats: %s isn't a core stat" % k)
        p.append("%s = %d" % (k, v))
    for kv in a.set:
        k, _, v = kv.partition("=")
        p.append("%s = %s" % (k, literal(k, v)))
    d.props = p
    return d.text('[node name="%s" instance=%s]' % (node, d.res("PackedScene", UNIT))), node


def place(a, node):
    p = "Scenes/%s.tscn" % a.into
    exists(p) or die("--into %s: no %s" % (a.into, p))
    m = re.fullmatch(r"(-?\d+),(-?\d+)", a.at or "") or die("--at x,y: the cell it stands on")
    text = read(p)
    secs = sections(text)
    us = next((s for s in secs if s["kind"] == "node" and s["attrs"].get("name") == "Units"), None) or die("%s: no Units node to put it under" % p)
    parent = (us["attrs"].get("parent", ".") + "/Units").lstrip("./") if us["attrs"].get("parent", ".") != "." else "Units"
    sx = free_id(secs, "u_" + a.id)
    text = add_ext(text, '[ext_resource type="PackedScene" path="res://Scenes/%s.tscn" id="%s"]' % (a.id, sx))
    lines = ['[node name="%s" parent="%s" instance=ExtResource("%s")]' % (node, parent, sx), "cell = Vector2i(%s, %s)" % m.groups()]
    side = a.side or a.faction
    if side:
        fx = next((i for i, q in ((s["attrs"].get("id"), s["attrs"].get("path")) for s in sections(text) if s["kind"] == "ext_resource") if q == "res://Factions/%s.tres" % side), None)
        if not fx:
            fx = free_id(sections(text), "f_" + side)
            text = add_ext(text, '[ext_resource type="Resource" path="res://Factions/%s.tres" id="%s"]' % (side, fx))
        lines.append('faction = ExtResource("%s")' % fx)
    return p, text.rstrip("\n") + "\n\n" + "\n".join(lines) + "\n"


TEST_STUB = '''extends Test

# %(name)s (Scenes/%(id)s.tscn). STUB(unit.py): who it is, and what these tests pin down.

var scene: PackedScene = load("res://Scenes/%(id)s.tscn")
var side: Faction = load("res://Factions/%(side)s.tres")


# Brings it on beside v(1) (Lancin) and v(3) (Nemes), %(side)s's turn. summon() wires its hits and heals (Battle._listen()).
func bring() -> Unit:
	var u: Unit = b.summon(scene, side, Vector2i(5, 3))
	stage(side, {v(1): Vector2i(2, 3), v(3): Vector2i(8, 3)})
	b.move(u, Vector2i(5, 3))
	return u


func test_%(id)s() -> void:
	var u := bring()
	ok(u.bio != null, "STUB(unit.py): its bio, stats and skills as designed")
	# How it reads to an observer: var r := b.read(sharp(v(1)), u)  (sharp(): recon 3, so levels show)
	# How its AI acts: var log := AI.act(b, u); ok(..., ", ".join(log))  (hurt_to(ally) for a helpful one to heal;
	# an ally to heal has to be on its side: b.summon(another, side, cell))
'''


def new(a):
    re.fullmatch(r"[a-z][a-z0-9_]*", a.id) or die("the id is a file name: lower_snake (blinthe, bog_hag)")
    exists("Scenes/%s.tscn" % a.id) and die("Scenes/%s.tscn exists" % a.id)
    a.name = a.name or a.id.replace("_", " ").title()
    if a.look:
        exists("Units/%s.png" % a.look) or die("--look %s: no Units/%s.png (leave it out for a placeholder)" % (a.look, a.look))
    sprite = a.look or (None if a.role and not a.color else re.sub(r"\W", "", a.name.title()))  # a class's sprite unless told otherwise
    text, node = unit_tscn(a, sprite)
    out = [("Scenes/%s.tscn" % a.id, text)]
    if not exists("Tests/%s_test.gd" % a.id):
        out.append(("Tests/%s_test.gd" % a.id, TEST_STUB % {"name": a.name, "id": a.id, "side": a.faction or a.side or "nemes"}))
    if a.into:
        out.append(place(a, node))
    for p, t in out:
        write(p, t, a.dry_run)
    if sprite and not a.look:
        icon.unit(sprite, icon.colour(a.color or "#9a8f7a"), a.name[:1], a.dry_run)
    if a.dry_run:
        return 0
    import_project()
    print("\nnext: fill in Tests/%s_test.gd (STUB(unit.py)): its bio, what others read of it, how its AI acts; then "
          "`python3 Util/unit.py check`, `python3 Util/skill.py check` and the tests (.claude/skills/new-unit)" % a.id)
    return check()


def new_faction(a):
    fid = a.id
    exists("Factions/%s.tres" % fid) and die("Factions/%s.tres exists" % fid)
    d = Doc('[gd_resource type="Resource" script_class="Faction" format=3]')
    rgb = icon.colour(a.color)
    dark = tuple(c * 0.35 / 255 for c in rgb[:3])
    d.props = ["script = " + d.res("Script", FACTION), 'name = "%s"' % ai_name(a.name or fid.title(), a.human),
               "primary = Color(%.3f, %.3f, %.3f, 1)" % tuple(c / 255 for c in rgb[:3]), "secondary = Color(%.3f, %.3f, %.3f, 1)" % dark]
    allies = [x for x in (a.allies or "").split(",") if x]
    if allies:
        d.props.append("allies = " + typed(FACTION, d, [faction_ref(d, f) for f in allies]))
    write("Factions/%s.tres" % fid, d.text(), a.dry_run)
    return 0


def check(_a=None):
    problems = []
    for p in files("Scenes", ".tscn"):
        text = read(p)
        if 'instance=ExtResource' not in text or "res://Scenes/unit.tscn" not in text:
            continue
        for m in re.finditer(r'path="res://(Units/\w+\.png)"', text):
            if not exists(m.group(1)):
                problems.append("%s: its sprite %s is missing" % (p, m.group(1)))
        b = re.search(r'^behaviour = &"(\w+)"', text, re.M)
        if b and "Bio_" in text and b.group(1) not in BEHAVIOURS:
            problems.append('%s: behaviour "%s" isn\'t one the AI knows (%s)' % (p, b.group(1), ", ".join(BEHAVIOURS)))
    known = set(re.findall(r'&"(\w+)"', read("Scripts/Bio.gd")))
    for x in BEHAVIOURS:
        x in known or problems.append("Util/unit.py: behaviour %s is gone from Bio.BEHAVIOURS - keep the two together" % x)
    for p in problems:
        print(p)
    print("unit.py check: %s" % ("%d problem(s)" % len(problems) if problems else "ok"))
    return 1 if problems else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    n = sub.add_parser("new", help="a unit scene with its bio, optionally placed in a battle")
    n.add_argument("id", help="file name: blinthe -> Scenes/blinthe.tscn")
    n.add_argument("--name", help="shown name (default: from the id; gets ?? unless --human)")
    n.add_argument("--human", action="store_true", help="a person named it: no ??")
    n.add_argument("--role", help="Roles/<x>.tres: its class (its sprite too, unless --look/--color)")
    n.add_argument("--race")
    n.add_argument("--faction", help="Factions/<x>.tres: the side it's on wherever it goes")
    n.add_argument("--title", help='after its name: "of Red"')
    n.add_argument("--level", type=int)
    n.add_argument("--behaviour", help="its temper: %s" % ", ".join(BEHAVIOURS))
    n.add_argument("--appearance", help="how it looks at a glance: Soldier, Knight, Caster")
    n.add_argument("--adjectives", help="comma separated: Beautiful,Injured")
    n.add_argument("--properties", help="Properties/ stems, comma separated: aquatic,rotting")
    n.add_argument("--clout", help="standing with sides: lancin=2,nemes=1")
    n.add_argument("--bio", help="a line or two about it")
    n.add_argument("--skill", action="append", default=[], help="a skill it has learned: id[:rank]")
    n.add_argument("--stats", help='"str=12,cha=18"')
    n.add_argument("--hp", type=int)
    n.add_argument("--energy", type=int)
    n.add_argument("--tags")
    n.add_argument("--vibe")
    n.add_argument("--aura", type=int, help="-2 ominous .. +2 benevolent")
    n.add_argument("--tends", choices=("benevolent", "pragmatic", "loyal"))
    n.add_argument("--strategy", help="closest, strongest, weakest")
    n.add_argument("--intention")
    n.add_argument("--set", action="append", default=[], help="any other Unit field: key=value")
    n.add_argument("--look", help="an existing sprite: Units/<Look>.png")
    n.add_argument("--color", help="a placeholder sprite in this colour")
    n.add_argument("--into", help="a battle scene to place it in (museum, meadows)")
    n.add_argument("--at", help="x,y: its cell there")
    n.add_argument("--side", help="its side there (default --faction)")
    n.add_argument("--dry-run", action="store_true")
    f = sub.add_parser("faction", help="a side: Factions/<id>.tres")
    f.add_argument("id")
    f.add_argument("--name")
    f.add_argument("--human", action="store_true")
    f.add_argument("--color", required=True, help='its glow: "#rrggbb"')
    f.add_argument("--allies", help="sides it fights beside, comma separated")
    f.add_argument("--dry-run", action="store_true")
    sub.add_parser("check", help="sprites there, behaviours known")
    a = ap.parse_args()
    sys.exit({"new": new, "faction": new_faction, "check": check}[a.cmd](a))


if __name__ == "__main__":
    main()
