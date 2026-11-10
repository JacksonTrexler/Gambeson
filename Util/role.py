#!/usr/bin/env python3
"""Gambeson class authoring: a class (Roles/<id>.tres), its own skill tree (Trees/<tree>.tres, a root to grow
with skill.py), its placeholder sprite (Units/<Sprite>.png), and a place on the starting screen.

  python3 Util/role.py new monk --focus martial --noun Brawler [--name Monk] [--human] \\
      [--tree "Open Palm:martial"] [--roots protector,brawn] [--general martial,specialist] [--god ramut] \\
      [--tends benevolent|pragmatic|loyal] [--stats "strength=12,dexterity=14,..."] [--items gambeson,dagger] \\
      [--race human] [--look Journeyer | --color "#a08060"] [--no-entry] [--dry-run]
  python3 Util/role.py check

Then give the tree its skills: python3 Util/skill.py new <id> ... --tree <tree file> [--root "Open Palm"]
(.claude/skills/new-class has the whole process). --focus picks starting stats and general trees
(martial, caster, specialist) where --stats/--general don't say. An AI-made name gets " ??" (CLAUDE.md).
"""
import argparse, re, sys

from tres import Doc, ai_name, die, exists, files, import_project, items, names, read, sections, snake, typed, write, add_ext, free_id
import os
import icon

ROLE, ROOT_GD, SLOT, ITEM = "res://Scripts/Role.gd", "res://Scripts/SkillRoot.gd", "res://Scripts/Slot.gd", "res://Scripts/Item.gd"
FOCUS = {  # stats, general trees, the tag of its own tree's root
    "martial": ({"strength": 14, "dexterity": 11, "constitution": 14, "intelligence": 8, "wisdom": 10, "charisma": 9}, ["martial"], "martial"),
    "caster": ({"strength": 8, "dexterity": 10, "constitution": 10, "intelligence": 15, "wisdom": 12, "charisma": 10}, ["magical"], "magical"),
    "specialist": ({"strength": 9, "dexterity": 14, "constitution": 10, "intelligence": 11, "wisdom": 11, "charisma": 12}, ["specialist"], "specialist"),
}
NPC_ONLY = {"wizard", "mage"}  # classes off the starting screen on purpose (Icor's; the Mage's schools); role.py new --no-entry adds to it by hand
GODS = ("ramut", "eros", "sol", "urlo", "luun", "vetruvis", "hogel", "elmon")


def stats_of(a):
    base = dict(FOCUS[a.focus][0])
    for kv in filter(None, (a.stats or "").split(",")):
        k, _, v = kv.partition("=")
        k = {"str": "strength", "dex": "dexterity", "con": "constitution", "int": "intelligence", "wis": "wisdom", "cha": "charisma"}.get(k.strip(), k.strip())
        k in base or die("--stats: %s isn't a core stat" % k)
        base[k] = int(v)
    return "Dictionary[StringName, int]({%s})" % ", ".join('&"%s": %d' % kv for kv in base.items())


def tree_tres(name, tag, human):
    d = Doc('[gd_resource type="Resource" script_class="SkillRoot" format=3]')
    d.props = ["script = " + d.res("Script", ROOT_GD), 'name = "%s"' % ai_name(name, human), 'tag = &"%s"' % tag,
               "branches = " + typed("res://Scripts/Branch.gd", d, [])]
    return d.text()


def role_tres(a, tree_file, sprite):
    d = Doc('[gd_resource type="Resource" script_class="Role" format=3]')
    d.props = ["script = " + d.res("Script", ROLE), 'name = "%s"' % ai_name(a.name, a.human)]
    if a.noun:
        d.props.append('noun = "%s"' % a.noun)  # a word for how it looks, not a name: no ??
    for key in ("tends", "god"):
        if getattr(a, key):
            d.props.append('%s = &"%s"' % (key, getattr(a, key)))
    d.props.append("look = " + d.res("Texture2D", "res://Units/%s.png" % sprite))
    exists("Races/%s.tres" % a.race) or die("--race %s: no Races/%s.tres" % (a.race, a.race))
    d.props.append("race = " + d.res("Resource", "res://Races/%s.tres" % a.race))
    strike = d.sub("Slot_strike", SLOT, ["skill = " + d.res("Resource", "res://Skills/strike.tres")])
    d.props.append("innate = " + typed(SLOT, d, [strike]))
    d.props.append("stats = " + stats_of(a))
    roots = []
    for r in filter(None, (a.roots or "").split(",")):
        exists("Trees/%s.tres" % r) or die("--roots %s: no Trees/%s.tres" % (r, r))
        roots.append(d.res("Resource", "res://Trees/%s.tres" % r))
    if tree_file:
        roots.insert(0, d.res("Resource", "res://Trees/%s.tres" % tree_file))
    if roots:
        d.props.append("roots = " + typed(ROOT_GD, d, roots))
    gear = []
    for it in filter(None, (a.items or "").split(",")):
        exists("Items/%s.tres" % it) or die("--items %s: no Items/%s.tres" % (it, it))
        gear.append(d.res("Resource", "res://Items/%s.tres" % it))
    if gear:
        d.props.append("items = " + typed(ITEM, d, gear))
    d.props.append("general = " + names(a.general or ",".join(FOCUS[a.focus][1])))
    return d.text()


def add_to_entry(rid):
    p = "Scenes/entry.tscn"
    text = read(p)
    secs = sections(text)
    path = "res://Roles/%s.tres" % rid
    rx = free_id(secs, "role_" + rid)
    text = add_ext(text, '[ext_resource type="Resource" path="%s" id="%s"]' % (path, rx))
    text, n = re.subn(r"^(roles = Array\[.*?\]\(\[.*)\]\)$", lambda m: m.group(1) + ', ExtResource("%s")])' % rx, text, count=1, flags=re.M)
    n == 1 or die("%s: no roles = line" % p)
    return p, text


def tab_colour(name, colour):  # its tab's colour on the skills screen (SkillTab.CLASSES, keyed by its shown name)
    p = "Scripts/SkillTab.gd"
    text = read(p)
    m = re.search(r'^const CLASSES := \{.*?\}$', text, re.M | re.S) or die("%s: no CLASSES table" % p)
    entry = '"%s": Color("%s")' % (name, colour)
    return p, text[:m.end() - 1] + ",\n\t\t" + entry + "}" + text[m.end():]


def class_names():
    m = re.search(r'^const CLASSES := \{(.*?)\}$', read("Scripts/SkillTab.gd"), re.M | re.S)
    return set(re.findall(r'"([^"]+)": Color', m.group(1))) if m else set()


def new(a):
    rid = a.id
    re.fullmatch(r"[a-z][a-z0-9_]*", rid) or die("the id is a file name: lower_snake (monk, blade_dancer)")
    exists("Roles/%s.tres" % rid) and die("Roles/%s.tres exists" % rid)
    a.god and a.god not in GODS and die("--god: one of %s" % ", ".join(GODS))
    a.name = a.name or rid.replace("_", " ").title()
    out, tree_file = [], None
    if a.tree:
        tname, _, tag = a.tree.partition(":")
        tag = tag or FOCUS[a.focus][2]
        tree_file = snake(tname)
        exists("Trees/%s.tres" % tree_file) and die("Trees/%s.tres exists: name the tree something else, or pass it in --roots" % tree_file)
        out.append(("Trees/%s.tres" % tree_file, tree_tres(tname, tag, a.human)))
    sprite = a.look or re.sub(r"\W", "", a.name.title())
    make_sprite = not a.look
    if a.look and not exists("Units/%s.png" % a.look):
        die("--look %s: no Units/%s.png (leave it out for a placeholder)" % (a.look, a.look))
    out.append(("Roles/%s.tres" % rid, role_tres(a, tree_file, sprite)))
    if a.dry_run:
        print('--- would add to Scripts/SkillTab.gd CLASSES: "%s": Color("%s") ---' % (ai_name(a.name, a.human), a.color))
    else:
        out.append(tab_colour(ai_name(a.name, a.human), a.color))
    if not a.no_entry:
        out.append(add_to_entry(rid))
    else:
        print("NPC-only: add %r to NPC_ONLY in Util/role.py, or its check will ask" % rid)
    for p, text in out:
        write(p, text, a.dry_run)
    if make_sprite:
        icon.unit(sprite, icon.colour(a.color), a.name[:1], a.dry_run)
    if a.dry_run:
        return 0
    import_project()
    print("\nnext:")
    if tree_file:
        print("  its skills: python3 Util/skill.py new <id> ... --tree %s   (the first goes in alone; later ones --after <skill>)" % tree_file)
    print("  Tests/%s_test.gd (a unit of it: stats, its tree, what it starts with); on the starting screen, update"
          " Tests/champions_test.gd test_entry's class names and sprites; then `python3 Util/role.py check`,"
          " `python3 Util/skill.py check` and the tests (.claude/skills/new-class)" % rid)
    if tree_file:
        print("(role.py check names the empty tree until its first skill goes on: expected)")
    return check()


def check(_a=None):
    problems = []
    entry = read("Scenes/entry.tscn")
    for p in files("Roles", ".tres"):
        text = read(p)
        m = re.search(r'^look = ExtResource\("([^"]+)"\)', text, re.M)
        if not m:
            problems.append("%s: no look (a sprite: --look or a placeholder)" % p)
        if "res://" + p not in entry and p[6:-5] not in NPC_ONLY:
            problems.append("%s: not on the starting screen (Scenes/entry.tscn roles); an NPC-only class goes in NPC_ONLY in Util/role.py" % p)
    tabbed = class_names()
    for p in files("Roles", ".tres"):
        res = next((s for s in sections(read(p)) if s["kind"] == "resource"), None)
        name = res["props"].get("name", "").strip('"') if res else ""
        if name and name not in tabbed:
            problems.append('%s: no tab colour - add "%s" to SkillTab.CLASSES (role.py new does)' % (p, name))
    for p in files("Trees", ".tres"):
        secs = sections(read(p))
        res = next((s for s in secs if s["kind"] == "resource"), None)
        if res and "branches" in res["props"] and not items(res["props"]["branches"]):
            problems.append("%s: a tree with no skills yet (python3 Util/skill.py new <id> --tree %s)" % (p, p[6:-5]))
    for p in problems:
        print(p)
    print("role.py check: %s" % ("%d problem(s)" % len(problems) if problems else "ok"))
    return 1 if problems else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    n = sub.add_parser("new", help="a class, its tree, sprite and place on the starting screen")
    n.add_argument("id", help="file name: monk -> Roles/monk.tres")
    n.add_argument("--name", help="shown name (default: from the id; gets ?? unless --human)")
    n.add_argument("--human", action="store_true", help="a person named it (and its tree): no ??")
    n.add_argument("--focus", choices=sorted(FOCUS), default="martial", help="starting stats, general trees, its tree's tag")
    n.add_argument("--noun", help="what its units look like to those who can't tell its class: Soldier, Caster, Tradefolk")
    n.add_argument("--tree", help='its own tree: "Name" or "Name:tag" (Trees/<name>.tres, empty, for skill.py to fill)')
    n.add_argument("--roots", help="existing trees it also offers, comma separated: protector,vanguard")
    n.add_argument("--general", help="general trees: martial, specialist, magical (default: by --focus)")
    n.add_argument("--stats", help='starting stats over --focus\'s, which are: %s' % "; ".join(
        "%s %s" % (k, ",".join("%s=%d" % (s[:3], v) for s, v in f[0].items())) for k, f in FOCUS.items()))
    n.add_argument("--god", choices=GODS, help="whom its units pray to (Unit.GODS)")
    n.add_argument("--tends", choices=("benevolent", "pragmatic", "loyal"))
    n.add_argument("--items", help="what a starter wears: Items/ stems, comma separated")
    n.add_argument("--race", default="human")
    n.add_argument("--look", help="an existing sprite, Units/<Look>.png (default: a placeholder from --color)")
    n.add_argument("--color", default="#8899aa", help="its tab's colour and its placeholder sprite's")
    n.add_argument("--no-entry", action="store_true", help="an NPC-only class: not on the starting screen")
    n.add_argument("--dry-run", action="store_true")
    sub.add_parser("check", help="every class has a sprite and is offered; no tree left empty")
    a = ap.parse_args()
    sys.exit(new(a) if a.cmd == "new" else check(a))


if __name__ == "__main__":
    main()
