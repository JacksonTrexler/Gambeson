#!/usr/bin/env python3
"""Gambeson class authoring: a class (Roles/<id>.tres), its own skill tree (Trees/<tree>.tres, a root to grow
with skill.py), its placeholder sprite (Units/<Sprite>.png), and a place on the starting screen.

  python3 Util/role.py new monk --focus martial --noun Brawler [--name Monk] [--human] \\
      [--tree "Open Palm:martial"] [--roots protector,brawn] [--general martial,specialist] [--god ramut] \\
      [--tends benevolent|pragmatic|loyal] [--stats "strength=12,dexterity=14,..."] [--items gambeson,dagger] \\
      [--race human] [--look Journeyer | --color "#a08060"] [--no-entry] [--dry-run]
  python3 Util/role.py tree illusion --name Illusion --tag magical [--human]      # an empty tree root, Trees/<id>.tres
  python3 Util/role.py tab rogue --name Trickster --roots showmanship,deception,legerdemain [--kind Calling] \
      [--color "#c58fd0"] [--human] [--choice School --by illusionist --affinity -1 | --into School]
  python3 Util/role.py god ramut [--patron] [--tree luun --kind Divinity] [--offers protector,radiance] [--human]
      # a god or patron (Gods/<id>.tres): its own tree (a tab of --tree's root, picked by a choice of god) and
      # the trees it offers its servants' slots (Gods/tabs/<stem>.tres; TreeChoice.kinds); --offers adds to one
  python3 Util/role.py check

Then give the tree its skills: python3 Util/skill.py new <id> ... --tree <tree file> [--root "Open Palm"]
(.claude/skills/new-class has the whole process). --focus picks starting stats and general trees
(martial, caster, specialist) where --stats/--general don't say. An AI-made name gets " ??" (CLAUDE.md).
tree and tab grow an existing class: `tree` writes a root for skill.py to fill (a school, a wing of a tab);
`tab` puts trees on a class as a tab of their own (SkillTab, Role.tabs), or as a tree picked from a choice
on its own tab (--choice: a new TreeChoice, opened by --by's rank or picked outright; --into: a choice it
already has, like the Mage's School).
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
GODS = tuple(sorted(f[:-5] for f in os.listdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Gods")) if f.endswith(".tres")))  # Gods/<id>.tres


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


def tree(a):
    tid = a.id
    re.fullmatch(r"[a-z][a-z0-9_]*", tid) or die("the id is a file name: lower_snake")
    exists("Trees/%s.tres" % tid) and die("Trees/%s.tres exists" % tid)
    write("Trees/%s.tres" % tid, tree_tres(a.name or tid.replace("_", " ").title(), a.tag, a.human), a.dry_run)
    print("next: its skills, python3 Util/skill.py new <id> ... --tree %s (the first goes in alone), and a tab for it:"
          " python3 Util/role.py tab <class> --roots %s" % (tid, tid))
    return 0


def _ext(text, kind, path):  # the id of path's ext_resource, added if missing
    secs = sections(text)
    for s in secs:
        if s["kind"] == "ext_resource" and s["attrs"].get("path") == path:
            return text, s["attrs"]["id"]
    i = free_id(secs, snake(os.path.splitext(os.path.basename(path))[0]))
    return add_ext(text, '[ext_resource type="%s" path="%s" id="%s"]' % (kind, path, i)), i


def _append(text, section_start, key, script_id, ref):  # adds ref to a typed array property of the section starting at section_start
    end = text.find("\n[", section_start + 1)
    end = len(text) if end < 0 else end
    body = text[section_start:end]
    m = re.search(r"^%s = (Array\[ExtResource\(\"[^\"]+\"\)\]\(\[)(.*?)(\]\))$" % key, body, re.M | re.S)
    if m:
        inner = m.group(2).strip()
        body = body[:m.start(2)] + (inner + ", " if inner else "") + ref + body[m.end(2):]
    else:
        body = body.rstrip("\n") + '\n%s = Array[ExtResource("%s")]([%s])\n' % (key, script_id, ref)
    return text[:section_start] + body + text[end:]


def tab(a):
    p = "Roles/%s.tres" % a.role
    exists(p) or die("no %s" % p)
    roots = [r.strip() for r in a.roots.split(",") if r.strip()]
    for r in roots:
        exists("Trees/%s.tres" % r) or die("--roots %s: no Trees/%s.tres (role.py tree %s first)" % (r, r, r))
    text = read(p)
    text, tab_gd = _ext(text, "Script", "res://Scripts/SkillTab.gd")
    text, root_gd = _ext(text, "Script", "res://Scripts/SkillRoot.gd")
    refs = []
    for r in roots:
        text, rid = _ext(text, "Resource", "res://Trees/%s.tres" % r)
        refs.append('ExtResource("%s")' % rid)
    name = ai_name(a.name, a.human)
    tab_id = free_id(sections(text), "Tab_" + snake(a.name))
    lines = ['[sub_resource type="Resource" id="%s"]' % tab_id, 'script = ExtResource("%s")' % tab_gd, 'name = "%s"' % name]
    if a.kind:
        lines.append('kind = "%s"' % (a.kind if a.human or a.kind in ("Calling", "School", "Path", "Prowess") else ai_name(a.kind)))
    if a.color:
        c = icon.colour(a.color)
        lines.append("color = Color(%.2f, %.2f, %.2f, 1)" % tuple(x / 255 for x in c[:3]))
    lines.append('roots = Array[ExtResource("%s")]([%s])' % (root_gd, ", ".join(refs)))
    blocks = "\n".join(lines) + "\n\n"
    if a.choice:
        text, choice_gd = _ext(text, "Script", "res://Scripts/TreeChoice.gd")
        choice_id = free_id(sections(text), "Choice_" + snake(a.choice))
        cl = ['[sub_resource type="Resource" id="%s"]' % choice_id, 'script = ExtResource("%s")' % choice_gd,
              'name = "%s"' % (a.choice if a.human else ai_name(a.choice)), 'tabs = Array[ExtResource("%s")]([SubResource("%s")])' % (tab_gd, tab_id)]
        if a.by:
            exists("Skills/%s.tres" % a.by) or die("--by %s: no Skills/%s.tres (skill.py new it first)" % (a.by, a.by))
            text, by = _ext(text, "Resource", "res://Skills/%s.tres" % a.by)
            cl.append('by = ExtResource("%s")' % by)
        if a.affinity:
            cl.append("affinity = %d" % a.affinity)
        blocks += "\n".join(cl) + "\n\n"
    if a.into:  # the tab goes in just before the choice that holds it: Godot reads a sub resource before its use
        m = None
        for s in sections(text):
            if s["kind"] == "sub_resource" and s["props"].get("name", "").strip('"') == a.into and "tabs" in s["props"] and "center" not in s["props"]:
                m = s
        if not m:
            choices = [s["props"]["name"] for s in sections(text) if s["kind"] == "sub_resource" and "tabs" in s["props"]]
            die("--into %s: %s has no such choice (%s)" % (a.into, p, ", ".join(choices) or "none"))
        head = '[sub_resource type="Resource" id="%s"]' % m["attrs"]["id"]
        text = text.replace(head, blocks + head, 1)
        text = _append(text, text.index(head), "tabs", tab_gd, 'SubResource("%s")' % tab_id)
    else:
        text = text.replace("\n[resource]\n", "\n" + blocks + "[resource]\n", 1)
    if a.into:
        pass  # added to the choice above
    elif a.choice:
        text = _append(text, text.index("\n[resource]\n") + 1, "choices", choice_gd, 'SubResource("%s")' % choice_id)
    else:
        text = _append(text, text.index("\n[resource]\n") + 1, "tabs", tab_gd, 'SubResource("%s")' % tab_id)
    write(p, text, a.dry_run)
    if a.dry_run:
        return 0
    print("next: python3 Util/skill.py check and the class's tests; a tab of an AI's naming is noted for review (CLAUDE.md)")
    return 0


def god(a):
    re.fullmatch(r"[a-z][a-z0-9_]*", a.id) or die("the id is a file name: lower_snake")
    p = "Gods/%s.tres" % a.id
    offers = [o.strip() for o in (a.offers or "").split(",") if o.strip()]
    for o in offers:
        exists("Gods/tabs/%s.tres" % o) or die("--offers %s: no Gods/tabs/%s.tres" % (o, o))
    if exists(p):  # add to its pool
        a.tree and die("%s exists: --tree is for a new god" % p)
        text = read(p)
        text, tab_gd = _ext(text, "Script", "res://Scripts/SkillTab.gd")
        for o in offers:
            text, oid = _ext(text, "Resource", "res://Gods/tabs/%s.tres" % o)
            text = _append(text, text.index("\n[resource]\n") + 1, "pool", tab_gd, 'ExtResource("%s")' % oid)
        write(p, text, a.dry_run)
        return 0
    d = Doc('[gd_resource type="Resource" script_class="God" format=3]')
    d.props = ["script = " + d.res("Script", "res://Scripts/God.gd"), 'id = &"%s"' % a.id]
    if a.patron:
        d.props.append("patron = true")
    if a.tree:
        exists("Trees/%s.tres" % a.tree) or die("--tree %s: no Trees/%s.tres" % (a.tree, a.tree))
        a.kind or die("--tree needs --kind: Divinity, Patron...")
        lines = ['name = "%s"' % ai_name(a.id.replace("_", " ").title(), a.human), 'kind = "%s"' % a.kind]
        if not a.patron:
            lines.append('god = &"%s"' % a.id)
        lines += ["devotes = true", "roots = " + typed(ROOT_GD, d, [d.res("Resource", "res://Trees/%s.tres" % a.tree)])]
        d.props.append("own = " + d.sub("Tab_own", "res://Scripts/SkillTab.gd", lines))
    d.props.append("pool = " + typed("res://Scripts/SkillTab.gd", d, [d.res("Resource", "res://Gods/tabs/%s.tres" % o) for o in offers]))
    write(p, d.text(), a.dry_run)
    print("next: Unit.GODS (its domains) and GOD_TAGS for a god of the pantheon; a pool tab of its own is a Gods/tabs/<stem>.tres (SkillTab: name, kind, roots)")
    return 0


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
    for p in [f for f in files("Gods", ".tres") if os.path.dirname(f) == "Gods"]:  # Gods/tabs/ holds their pools' tabs
        text = read(p)
        for path in re.findall(r'path="res://([^"]+)"', text):
            exists(path) or problems.append("%s: %s is missing" % (p, path))
        if "own = " not in text and not re.search(r"^pool = .*ExtResource", text, re.M):
            problems.append("%s: a god offering nothing (role.py god %s --offers ...)" % (p, p[5:-5]))
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
    tr = sub.add_parser("tree", help="an empty tree root, Trees/<id>.tres, for skill.py to fill")
    tr.add_argument("id")
    tr.add_argument("--name", help="shown name (default: from the id; gets ?? unless --human)")
    tr.add_argument("--tag", default="specialist", help="its root's category: martial, specialist, magical")
    tb = sub.add_parser("tab", help="trees on an existing class: a tab of their own, or a tree picked from a choice")
    tb.add_argument("role", help="Roles/<role>.tres")
    tb.add_argument("--name", required=True, help="the tab's name (gets ?? unless --human)")
    tb.add_argument("--kind", help="the kind it is, shown before its name: Calling, School...")
    tb.add_argument("--roots", required=True, help="Trees/ stems, comma separated, left to right")
    tb.add_argument("--color", help='its colour, "#rrggbb" (default: by kind or class)')
    tb.add_argument("--choice", help="a new choice on the class's own tab holding it (its box's heading)")
    tb.add_argument("--by", help="with --choice: the skill whose rank opens it (TreeChoice.by)")
    tb.add_argument("--affinity", type=int, default=0, help="with --choice: its skills' Affinity for the class (a guest tree: -1)")
    tb.add_argument("--into", help="or: an existing choice of the class to add it to (the Mage's School)")
    for x in (tr, tb):
        x.add_argument("--human", action="store_true", help="a person named it: no ??")
        x.add_argument("--dry-run", action="store_true")
    g = sub.add_parser("god", help="a god or patron (Gods/<id>.tres), or more trees in an existing one's pool")
    g.add_argument("id")
    g.add_argument("--patron", action="store_true", help="a Warlock's patron")
    g.add_argument("--tree", help="its own tree: a Trees/ stem (a new god only)")
    g.add_argument("--kind", help="with --tree: its kind, the choice of god that offers it (Divinity, Patron)")
    g.add_argument("--offers", help="Gods/tabs/ stems it offers its servants' slots, comma separated")
    g.add_argument("--human", action="store_true", help="a person named it: no ??")
    g.add_argument("--dry-run", action="store_true")
    sub.add_parser("check", help="every class has a sprite and is offered; no tree left empty; every god offers something")
    a = ap.parse_args()
    sys.exit({"new": new, "tree": tree, "tab": tab, "god": god, "check": check}[a.cmd](a))


if __name__ == "__main__":
    main()
