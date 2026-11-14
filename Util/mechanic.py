#!/usr/bin/env python3
"""Gambeson mechanic authoring: the words and numbers rules are built from, each in its one place.

  python3 Util/mechanic.py tag acid --define "Eats through armor: Defense counts half." [--term Acid] \\
      [--kind damage|condition|ground|check|target] [--parent physical] [--human]
  python3 Util/mechanic.py property rotting --effect "stat=mitigate amount=-0.5 tags=fire" \\
      [--tags undead] [--text "Fire takes it apart."] [--name Rotting] [--human]
  python3 Util/mechanic.py effect scorched --effect "stat=poison amount=0.05" [--name Scorched] [--human]
  python3 Util/mechanic.py stat word_reach --doc "tiles more its word carries (Battle.spread())"
  python3 Util/mechanic.py check

tag: a word skills, tiles and units carry (Skill.tags, Terrain.tags, Unit.tags), defined once in the
  Glossary (Glossary.TERMS) so descriptions can say {k:acid}; --parent makes it count as another (Tags.PARENT:
  a slash is physical). The rules ask for it by &"name" - in a behaviour, or where the system lives.
property: what a unit is made of (Properties/<id>.tres, Bio.properties): effects always on it.
effect: a reusable status (Effects/<id>.tres) skills and tiles put on units.
stat: a new Effect stat (Effect.gd's list and its doc line). Read it with unit.stat(&"name") where it acts:
  a behaviour (Behaviours/*.gd) for a skill's own verb, else the one system it changes - never a Skill.gd flag.
An AI-made name gets " ??" (CLAUDE.md). .claude/skills/new-mechanic has the process.
"""
import argparse, re, sys, textwrap

from tres import Doc, ai_name, die, exists, files, literal, names, read, write
import tres

KINDS = ("check", "damage", "condition", "ground", "target")
TEST_STUB = '''extends Test

# %(what)s. STUB(mechanic.py): what it does, where the rule reads it, and what these tests pin down.
# Units: v(1), v(2) Lancin, v(3), v(4) Nemes (Tests/Test.gd); a property goes on before the unit is in
# the tree (bio_test.gd: properties' tags are taken as it readies), an effect with v(1).afflict(e, turns).


func test_%(id)s() -> void:
	stage(lancin, {v(1): Vector2i(2, 3), v(3): Vector2i(3, 3)})
	ok(false, "STUB(mechanic.py): %(id)s does what it says")
'''


def test_stub(a, what):
    p = "Tests/%s_test.gd" % a.id
    if a.no_test or exists(p):
        return
    write(p, TEST_STUB % {"what": what, "id": a.id}, a.dry_run)


def edit(p, old, new, dry):
    text = read(p)
    text.count(old) == 1 or die("%s: the anchor %r isn't there once - has the file changed shape?" % (p, old[:60]))
    write(p, text.replace(old, new), dry)


def tag(a):
    t = a.id
    re.fullmatch(r"[a-z][a-z0-9_]*", t) or die("a tag is lower_snake: acid, holy_fire")
    gl = read("Scripts/Glossary.gd")
    re.search(r'^\t&"%s": \[' % t, gl, re.M) and die("%s is already in Glossary.TERMS" % t)
    a.kind in KINDS or die("--kind: one of %s" % ", ".join(KINDS))
    '"' not in a.define and "[" not in a.define or die("--define: no double quotes or square brackets (BBCode)")
    term = ai_name(a.term or t.replace("_", " ").title(), a.human)
    line = '\t&"%s": ["%s", &"%s", "%s"],\n' % (t, term, a.kind, a.define)
    end = gl.index("\n}\n", gl.index("const TERMS := {"))
    write("Scripts/Glossary.gd", gl[:end + 1] + line + gl[end + 1:], a.dry_run)
    if a.parent:
        edit("Scripts/Tags.gd", "const PARENT := {", 'const PARENT := {&"%s": &"%s", ' % (t, a.parent), a.dry_run)
    test_stub(a, "The %s tag (Glossary.TERMS)" % t)
    print('\nnext: put it on what carries it (skill.py --tags, tile.py --tags, unit.py --tags), and make the rules ask for '
          '&"%s" where it acts; a test that it does. The Glossary page shows it now.' % t)
    return 0


def property_(a):
    pid = a.id
    exists("Properties/%s.tres" % pid) and die("Properties/%s.tres exists" % pid)
    a.effect or a.tags or die("a property does something: --effect (resist, weakness...) and/or --tags")
    d = Doc('[gd_resource type="Resource" script_class="Property" format=3]')
    d.props = ["script = " + d.res("Script", "res://Scripts/Property.gd"), 'name = "%s"' % ai_name(a.name or pid.replace("_", " ").title(), a.human)]
    if a.tags:
        d.props.append("tags = " + names(a.tags))
    if a.effect:
        refs = [d.effect("Effect_%d" % (i + 1), s, a.human) for i, s in enumerate(a.effect)]
        d.props.append("effects = " + tres.typed("res://Scripts/Effect.gd", d, refs))
    if a.text:
        d.props.append('text = "%s"' % a.text.replace('"', '\\"'))
    write("Properties/%s.tres" % pid, d.text(), a.dry_run)
    test_stub(a, "The %s property (Properties/%s.tres)" % (pid, pid))
    print("\nnext: give it to units (unit.py --properties %s), and a test of what it does" % pid)
    return 0


def effect(a):
    eid = a.id
    exists("Effects/%s.tres" % eid) and die("Effects/%s.tres exists" % eid)
    len(a.effect) == 1 or die("one --effect: an Effects/ file is a single effect")
    d = Doc('[gd_resource type="Resource" script_class="Effect" format=3]')
    d.props = ["script = " + d.res("Script", "res://Scripts/Effect.gd")] + tres.effect_props(a.effect[0], a.human)
    if not any(x.startswith("name = ") for x in d.props):
        d.props.append('name = "%s"' % ai_name(a.name or eid.replace("_", " ").title(), a.human))
    write("Effects/%s.tres" % eid, d.text(), a.dry_run)
    test_stub(a, "The %s status (Effects/%s.tres)" % (eid, eid))
    return 0


def stat(a):
    s = a.id
    re.fullmatch(r"[a-z][a-z0-9_]*", s) or die("a stat is lower_snake")
    gd = read("Scripts/Effect.gd")
    m = re.search(r'@export_enum\(([^)]*)\) var stat', gd, re.S) or die("Effect.gd: no stat enum")
    '"%s"' % s in m.group(1) and die("Effect.gd already has %s" % s)
    last = list(re.finditer(r'"\w+"', m.group(1)))[-1]
    at = m.start(1) + last.end()
    gd = gd[:at] + ', "%s"' % s + gd[at:]
    doc = "\n".join(textwrap.wrap("%s: %s" % (s, a.doc), 98, initial_indent="# ", subsequent_indent="# ")) + "\n"
    gd = gd.replace("@export_enum(\"luck\"", doc + "@export_enum(\"luck\"", 1)
    write("Scripts/Effect.gd", gd, a.dry_run)
    test_stub(a, "The %s Effect stat" % s)
    print('\nnext: read it where it acts - unit.stat(&"%s") in a behaviour or the system it changes - and test it' % s)
    return 0


def check(_a=None):
    problems = []
    gl = read("Scripts/Glossary.gd")
    for p in files("Properties", ".tres"):
        if not re.search(r"^(effects|tags) = ", read(p), re.M):
            problems.append("%s: does nothing (no effects or tags)" % p)
    for t, parent in re.findall(r'&"(\w+)": &"(\w+)"', read("Scripts/Tags.gd")):
        if not re.search(r'^\t&"%s": \[' % t, gl, re.M) and t not in ("slash", "pierce", "blunt", "foundation"):
            problems.append('Scripts/Tags.gd: %s has no Glossary entry (mechanic.py tag %s --define ...)' % (t, t))
    stats = re.search(r'@export_enum\(([^)]*)\) var stat', read("Scripts/Effect.gd"), re.S).group(1)
    for p in list(files("Properties", ".tres")) + list(files("Effects", ".tres")):
        for s in re.findall(r'^stat = "(\w+)"', read(p), re.M):
            if '"%s"' % s not in stats:
                problems.append('%s: stat "%s" isn\'t in Effect.gd (mechanic.py stat %s)' % (p, s, s))
    for p in list(files("Items", ".tres")) + list(files("Skills", ".tres")):  # enchanted and honed never together (Tags.QUALITIES)
        m = re.search(r"^tags = .*$", read(p), re.M)
        if m and '&"enchanted"' in m.group(0) and '&"honed"' in m.group(0):
            problems.append("%s: enchanted and honed together - pick one (they exclude each other)" % p)
    for p in problems:
        print(p)
    print("mechanic.py check: %s" % ("%d problem(s)" % len(problems) if problems else "ok"))
    return 1 if problems else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    t = sub.add_parser("tag", help="a word the rules ask about, defined in the Glossary")
    t.add_argument("id")
    t.add_argument("--define", required=True, help="one plain sentence or two: what it means in play")
    t.add_argument("--term", help="shown name (default: from the id)")
    t.add_argument("--kind", required=True, help="its Glossary kind: %s" % ", ".join(KINDS))
    t.add_argument("--parent", help="a tag it also counts as (Tags.PARENT)")
    p = sub.add_parser("property", help="what a unit is made of: Properties/<id>.tres")
    p.add_argument("id")
    p.add_argument("--effect", action="append", default=[], help='"stat=mitigate amount=-0.5 tags=fire" (below 0: a weakness)')
    p.add_argument("--tags", help="what it makes the unit count as")
    p.add_argument("--text", help="one line: what it does")
    p.add_argument("--name")
    e = sub.add_parser("effect", help="a reusable status: Effects/<id>.tres")
    e.add_argument("id")
    e.add_argument("--effect", action="append", default=[], required=True)
    e.add_argument("--name")
    s = sub.add_parser("stat", help="a new Effect stat")
    s.add_argument("id")
    s.add_argument("--doc", required=True, help="what it means, and where it's read")
    for x in (t, p, e, s):
        x.add_argument("--human", action="store_true", help="a person named it: no ??")
        x.add_argument("--dry-run", action="store_true")
        x.add_argument("--no-test", action="store_true", help="don't stub Tests/<id>_test.gd")
    sub.add_parser("check")
    a = ap.parse_args()
    sys.exit({"tag": tag, "property": property_, "effect": effect, "stat": stat, "check": check}[a.cmd](a))


if __name__ == "__main__":
    main()
