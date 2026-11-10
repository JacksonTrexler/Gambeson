#!/usr/bin/env python3
"""Gambeson skill authoring: write a skill and wire it in (`new`), and catch the wiring pitfalls (`check`).

  python3 Util/skill.py new kick --tags physical,blunt,str,martial,offensive --ap 4 --cost 1 \\
      --range-per-rank 1 --tier 1:1d4+strength --behaviour kick --tree general_martial --after brutal_strike \\
      --branch-tier 1 [--role fighter] [--prereq snare] [--effect "stat=luck amount=-1 per_rank=true"] \\
      [--set rolls=false] [--passive] [--no-import] [--dry-run]
  python3 Util/skill.py check       # cheap, plain text: run before every commit (Tests/skills_test.gd runs it too)

`new` writes Skills/<id>.tres, a behaviour stub (Behaviours/<b>.gd) if it names one that doesn't exist, a test
stub (Tests/<id>_test.gd), puts the skill on a tree (Trees/ or Roles/ <file>, beside --after's branch or at the
end of --root's) and in --role's options, imports, then checks. It edits text by anchors and stops if one is
missing. Stubs carry STUB: check fails until they're filled in. Plain python3, no dependencies.
"""
import argparse, os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STUB = "STUB(skill.py)"
FLAG_CEILING = 124  # @export vars on Skill.gd: new behaviour goes in Behaviours/, not a new flag (CLAUDE.md)
FLOATS = {"ap", "radius", "radius_per_rank", "amount", "decays", "carry", "blast", "strike_ap", "restores", "rank_growth", "cone"}


def rel(p):
    return os.path.relpath(p, ROOT)


def read(p):
    with open(os.path.join(ROOT, p), encoding="utf-8") as f:
        return f.read()


def write(p, text, dry):
    if dry:
        print("--- would write %s ---\n%s" % (p, text))
        return
    with open(os.path.join(ROOT, p), "w", encoding="utf-8") as f:
        f.write(text)
    print("wrote", p)


def die(msg):
    sys.exit("skill.py: " + msg)


# --- .tres as text: [sections] of key = value, values possibly spanning lines

HEADER = re.compile(r'^\[(\w+)(.*)\]\s*$')
ATTR = re.compile(r'(\w+)=("(?:[^"\\]|\\.)*"|\S+)')
REF = re.compile(r'\b(Ext|Sub)Resource\("([^"]+)"\)')


def _open(s):  # string still open, bracket depth after s
    depth, q, esc = 0, False, False
    for ch in s:
        if q:
            esc = ch == "\\" and not esc
            if ch == '"' and not esc:
                q = False
            continue
        if ch == '"':
            q = True
        elif ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
    return q or depth > 0


def sections(text):
    out, lines, i = [], text.split("\n"), 0
    while i < len(lines):
        m = HEADER.match(lines[i])
        if not m:
            i += 1
            continue
        sec = {"kind": m.group(1), "attrs": {k: v.strip('"') for k, v in ATTR.findall(m.group(2))}, "props": {}, "line": i}
        i += 1
        while i < len(lines) and not HEADER.match(lines[i]):
            if " = " in lines[i]:
                key, val = lines[i].split(" = ", 1)
                while _open(val) and i + 1 < len(lines):
                    i += 1
                    val += "\n" + lines[i]
                sec["props"][key] = val
            i += 1
        out.append(sec)
    return out


def ext_ids(secs):
    return {s["attrs"].get("id"): s["attrs"].get("path") for s in secs if s["kind"] == "ext_resource"}


def ext_id_for(secs, path):
    for i, p in ext_ids(secs).items():
        if p == path:
            return i
    return None


def items(val):  # the ids in a value, past a typed array's type: Array[ExtResource("7_branch")]([SubResource("Branch_a"), ...])
    return [i for _, i in REF.findall(re.sub(r"^Array\[[^\]]*\]\(", "", val))]


def skill_refs(secs):  # Branch sub_resource id -> skill ext id
    return {s["attrs"]["id"]: REF.search(s["props"]["skill"]).group(2)
            for s in secs if s["kind"] == "sub_resource" and "skill" in s["props"] and REF.search(s["props"]["skill"])}


# --- check

def files(top, ext):
    for d, dirs, fs in os.walk(os.path.join(ROOT, top)):
        dirs[:] = [x for x in dirs if not x.startswith(".")]
        for f in fs:
            if f.endswith(ext):
                yield rel(os.path.join(d, f))


def check_refs(problems):
    for p in files(".", ".tres"):
        text = read(p)
        secs = sections(text)
        ids = {}
        for s in secs:
            if s["kind"] in ("ext_resource", "sub_resource"):
                i = s["attrs"].get("id")
                if i in ids:
                    problems.append("%s: id %s declared twice" % (p, i))
                ids[i] = s["kind"]
            path = s["attrs"].get("path", "")
            if s["kind"] == "ext_resource" and path.startswith("res://") and not os.path.exists(os.path.join(ROOT, path[6:])):
                problems.append("%s: ext_resource %s points at a missing file" % (p, path))
        for kind, i in REF.findall(text):
            want = "ext_resource" if kind == "Ext" else "sub_resource"
            if ids.get(i) != want:
                problems.append('%s: %sResource("%s") has no %s with that id' % (p, kind, i, want))


def check_reachable(problems):
    used = set()
    for top, ext in ((".", ".tres"), (".", ".tscn"), ("Scripts", ".gd"), ("Behaviours", ".gd")):
        for p in files(top, ext):
            if p.startswith("Skills/"):
                continue
            used.update(re.findall(r"res://Skills/\w+\.tres", read(p)))
    for p in files("Skills", ".tres"):  # a skill another grants (Stonegift: Stoneskin) counts too
        used.update(x for x in re.findall(r"res://Skills/\w+\.tres", read(p)) if x != "res://" + p)
    for p in sorted(files("Skills", ".tres")):
        if "res://" + p not in used:
            problems.append("%s: on no tree, role or item, and granted by nothing - nobody can get it" % p)


FLAVOUR = {"idealism", "lawful",  # tags only lore reads, for now (Coordinate, Judgement)
           "bludgeon"}  # Waterstrike: likely meant blunt (what breaks starpanes) - left as it was


def known_tags():  # what the rules can ask about: any &"tag" in the scripts, class names, tags 2+ skills share, FLAVOUR
    known = set(FLAVOUR)
    counts = {}
    for p in files("Skills", ".tres"):
        for t in set(re.findall(r'&"(\w+)"', read(p))):
            counts[t] = counts.get(t, 0) + 1
    known.update(t for t, n in counts.items() if n > 1)
    for p in list(files("Scripts", ".gd")) + list(files("Behaviours", ".gd")):
        known.update(re.findall(r'&"(\w+)"', read(p)))
    known.update(os.path.splitext(os.path.basename(p))[0] for p in files("Roles", ".tres"))
    return known


def check_tags(problems):
    known = known_tags()
    for p in sorted(files("Skills", ".tres")):
        for s in sections(read(p)):
            if s["kind"] == "resource" and "tags" in s["props"]:
                for t in re.findall(r'&"(\w+)"', s["props"]["tags"]):
                    if t not in known:
                        problems.append('%s: tag "%s" is nowhere in Scripts/ (a typo? the Glossary and the rules only know their own)' % (p, t))


def check_uids(problems):
    for top in ("Scripts", "Behaviours", "Tests", "Scenes", "Util"):
        for p in files(top, ".gd"):
            if not os.path.exists(os.path.join(ROOT, p + ".uid")):
                problems.append("%s: no %s.uid (run godot --headless --path . --import, and commit it)" % (p, os.path.basename(p)))
    try:
        tracked = set(subprocess.run(["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True).stdout.split("\n"))
    except (OSError, subprocess.CalledProcessError):
        return
    for p in tracked:
        if p.endswith(".gd") and p + ".uid" not in tracked and os.path.exists(os.path.join(ROOT, p + ".uid")):
            problems.append("%s.uid: not committed beside %s (git add it)" % (p, p))


def check_behaviours(problems):
    used = "\n".join(read(p) for p in files("Skills", ".tres"))
    for p in files("Behaviours", ".gd"):
        text = read(p)
        for f in ("apply", "describe"):
            if "func %s(" % f not in text:
                problems.append("%s: no %s() - a behaviour does and says, side by side" % (p, f))
        if "res://" + p not in used:
            problems.append("%s: no skill uses it" % p)


def check_flags(problems):
    n = len(re.findall(r"^@export var ", read("Scripts/Skill.gd"), re.M))
    if n > FLAG_CEILING:
        problems.append("Scripts/Skill.gd: %d flags, over %d - put new behaviour in a Behaviours/ script (CLAUDE.md); "
                        "raise FLAG_CEILING in Util/skill.py only for a field every skill shares" % (n, FLAG_CEILING))


def check_stubs(problems):
    for top, ext in (("Tests", ".gd"), ("Behaviours", ".gd"), ("Skills", ".tres")):
        for p in files(top, ext):
            for k, line in enumerate(read(p).split("\n")):
                if STUB in line:
                    problems.append("%s:%d: a stub skill.py wrote, still to fill in" % (p, k + 1))


def wheel_count(role):  # the skills on a radial class's own tab (Role.trees(), SkillWheel): centre, core, options, roots,
    secs = sections(read("Roles/%s.tres" % role))  # and its innate skills no other tab or general tree has (Strike)
    exts = ext_ids(secs)
    subs = {s["attrs"]["id"]: s for s in secs if s["kind"] == "sub_resource"}
    res = next(s for s in secs if s["kind"] == "resource")
    out = set(exts[i] for k in ("center", "core", "options") for i in items(res["props"].get(k, "")))
    for r in items(res["props"].get("roots", "")):
        for b in items(subs[r]["props"].get("branches", "")):
            out.add(exts[items(subs[b]["props"]["skill"])[0]])
    elsewhere = "\n".join(read(p) for p in files("Trees", ".tres") if os.path.basename(p).startswith("general"))
    tabbed = {exts[items(s["props"]["skill"])[0]] for s in subs.values() if "skill" in s["props"] and s["attrs"]["id"].startswith("Branch")}
    for i in items(res["props"].get("innate", "")):
        s = exts[items(subs[i]["props"]["skill"])[0]]
        if s not in tabbed and s not in elsewhere:
            out.add(s)
    return len(out)


COUNTS = [  # tests that hold a count of skills: (file, regex whose group 1 is the number, what it should be)
    ("Tests/hud_test.gd", r"w\.skills\(\)\.size\(\) == (\d+)", lambda: wheel_count("adventurer"), "the Adventurer wheel"),
]


def check_counts(problems):
    for p, rx, want, what in COUNTS:
        m = re.search(rx, read(p))
        if not m:
            problems.append("%s: the count of %s is gone - update COUNTS in Util/skill.py" % (p, what))
        elif int(m.group(1)) != want():
            problems.append("%s:%d: says %s skills on %s, the data has %d" % (p, read(p)[:m.start()].count("\n") + 1, m.group(1), what, want()))


def check(_args=None):
    problems = []
    for f in (check_refs, check_reachable, check_tags, check_uids, check_behaviours, check_flags, check_stubs, check_counts):
        f(problems)
    for p in problems:
        print(p)
    print("skill.py check: %s" % ("%d problem%s" % (len(problems), "" if len(problems) == 1 else "s") if problems else "ok"))
    return 1 if problems else 0


# --- new

def literal(key, v):
    if v in ("true", "false") or re.fullmatch(r"-?\d+", v) and key not in FLOATS:
        return v
    if re.fullmatch(r"-?\d+(\.\d+)?", v):
        return v if "." in v else v + ".0"
    if re.fullmatch(r"\w+\(.*\)|&\".*\"|\".*\"|\[.*\]", v):
        return v  # already a literal: Vector2i(1, 4), &"str", "text"
    return '"%s"' % v


def tier_section(i, spec, ext):
    m = re.fullmatch(r"(\d+):(.*)", spec) or die('--tier "%s": want RANK:PARTS, e.g. 1:1d4+strength or 3:2+1d6' % spec)
    lines = ['[sub_resource type="Resource" id="Tier_%d"]' % i, 'script = ExtResource("%s")' % ext, "rank = " + m.group(1)]
    for part in filter(None, m.group(2).split("+")):
        d = re.fullmatch(r"(\d+)d(\d+)", part)
        if d:
            lines.append("dice = Vector2i(%s, %s)" % d.groups())
        elif part.isdigit():
            lines.append("power = " + part)
        elif part == "direct":
            lines.append("direct = true")
        else:
            lines.append('stat = &"%s"' % part)
    return "\n".join(lines)


def effect_section(i, spec, ext):
    lines = ['[sub_resource type="Resource" id="Effect_%d"]' % i, 'script = ExtResource("%s")' % ext]
    for kv in spec.split():
        k, _, v = kv.partition("=")
        lines.append("%s = %s" % (k, literal(k, v) if k != "stat" else '"%s"' % v))
    return "\n".join(lines)


def skill_tres(a):
    ext = ['[ext_resource type="Script" path="res://Scripts/Skill.gd" id="1_skill"]']
    subs, props = [], ['script = ExtResource("1_skill")', 'name = "%s"' % a.title]
    if a.passive:
        props.append("passive = true")
    if a.tags:
        props.append("tags = Array[StringName]([%s])" % ", ".join('&"%s"' % t for t in a.tags.split(",")))
    if a.effect:
        ext.append('[ext_resource type="Script" path="res://Scripts/Effect.gd" id="2_effect"]')
        subs += [effect_section(i + 1, e, "2_effect") for i, e in enumerate(a.effect)]
        props.append('effects = Array[ExtResource("2_effect")]([%s])' % ", ".join('SubResource("Effect_%d")' % (i + 1) for i in range(len(a.effect))))
    for key in ("ap", "cost", "radius", "radius_per_rank"):
        v = getattr(a, key)
        if v is not None:
            props.append("%s = %s" % (key, literal(key, v)))
    if a.tier:
        ext.append('[ext_resource type="Script" path="res://Scripts/Tier.gd" id="3_tier"]')
        subs += [tier_section(i + 1, t, "3_tier") for i, t in enumerate(a.tier)]
        props.append('tiers = Array[ExtResource("3_tier")]([%s])' % ", ".join('SubResource("Tier_%d")' % (i + 1) for i in range(len(a.tier))))
    if a.behaviour:
        ext.append('[ext_resource type="Script" path="res://Scripts/Behaviour.gd" id="4_behaviour"]')
        for b in a.behaviour:
            ext.append('[ext_resource type="Script" path="res://Behaviours/%s.gd" id="b_%s"]' % (b, b))
            subs.append('[sub_resource type="Resource" id="Behaviour_%s"]\nscript = ExtResource("b_%s")' % (b, b))
        props.append('behaviours = Array[ExtResource("4_behaviour")]([%s])' % ", ".join('SubResource("Behaviour_%s")' % b for b in a.behaviour))
    for kv in a.set:
        k, _, v = kv.partition("=")
        props.append("%s = %s" % (k, literal(k, v)))
    head = '[gd_resource type="Resource" script_class="Skill" format=3]'
    return "\n\n".join([head, "\n".join(ext)] + subs + ["[resource]\n" + "\n".join(props)]) + "\n"


BEHAVIOUR_STUB = '''extends Behaviour

# %(title)s: what it does, in a line or two. %(stub)s


func apply(c: Cast) -> void:
	pass  # %(stub)s: c.battle, c.caster, c.target, c.rank; c.put(effect, turns) puts one on the target


func describe(rank: int) -> String:
	return "%(stub)s %(title)s at rank %%d" %% rank  # Glossary markup, one line: what apply() does
'''

TEST_STUB = '''extends Test

# %(title)s (Skills/%(id)s.tres). %(stub)s: what it does, and what these tests pin down.

var %(id)s: Skill = load("res://Skills/%(id)s.tres")


func test_%(id)s() -> void:
	v(1).learned.append(slot(%(id)s, 2))
	stage(lancin, {v(1): Vector2i(4, 3), v(3): Vector2i(5, 3)})
	ok(%(id)s.describe(2) != "", "%(stub)s: it says what it does: %%s" %% %(id)s.describe(2))
'''


def add_ext(text, line):  # after the last ext_resource
    at = list(re.finditer(r"^\[ext_resource .*\]$", text, re.M))
    at or die("no [ext_resource] lines to add beside")
    end = at[-1].end()
    return text[:end] + "\n" + line + text[end:]


def free_id(secs, want):
    ids = {s["attrs"].get("id") for s in secs}
    i, n = want, 2
    while i in ids:
        i, n = "%s_%d" % (want, n), n + 1
    return i


def put_on_tree(a, sid):
    p = next((x for x in ("Trees/%s.tres" % a.tree, "Roles/%s.tres" % a.tree) if os.path.exists(os.path.join(ROOT, x))), None)
    p or die("--tree %s: no Trees/%s.tres or Roles/%s.tres" % (a.tree, a.tree, a.tree))
    text = read(p)
    secs = sections(text)
    path = "res://Skills/%s.tres" % sid
    if ext_id_for(secs, path):
        die("%s already has %s" % (p, path))
    branch = ext_id_for(secs, "res://Scripts/Branch.gd") or die("%s: no Branch.gd ext_resource" % p)
    sk = free_id(secs, "s_" + sid)
    bid = free_id(secs, "Branch_" + sid)
    roots = [s for s in secs if s["kind"] == "sub_resource" and "branches" in s["props"]]
    if a.after:
        aid = ext_id_for(secs, "res://Skills/%s.tres" % a.after) or die("%s: --after %s isn't on it" % (p, a.after))
        anchor = next((b for b, s in skill_refs(secs).items() if s == aid), None) or die("%s: no branch for %s" % (p, a.after))
        root = next((r for r in roots if 'SubResource("%s")' % anchor in r["props"]["branches"]), None) or die("%s: %s is on no root" % (p, a.after))
    else:
        root = next((r for r in roots if a.root in (None, r["props"].get("name", "").strip('"'))), None) or die("%s: no root %s" % (p, a.root))
        anchor = items(root["props"]["branches"])[-1]
    lines = ['[sub_resource type="Resource" id="%s"]' % bid, 'script = ExtResource("%s")' % branch, 'skill = ExtResource("%s")' % sk]
    if a.prereq:
        skill_ext = ext_id_for(secs, "res://Scripts/Skill.gd") or die("%s: no Skill.gd ext_resource for --prereq" % p)
        pre = [ext_id_for(secs, "res://Skills/%s.tres" % x) or die("%s: --prereq %s isn't on it" % (p, x)) for x in a.prereq.split(",")]
        lines.append('after = Array[ExtResource("%s")]([%s])' % (skill_ext, ", ".join('ExtResource("%s")' % x for x in pre)))
    if a.branch_tier:
        lines.append("tier = %d" % a.branch_tier)
    # the new Branch section goes right after the anchor's section
    m = re.search(r'^\[sub_resource type="Resource" id="%s"\]$' % re.escape(anchor), text, re.M) or die("no section %s" % anchor)
    nxt = re.compile(r"^\[", re.M).search(text, m.end())
    cut = nxt.start() if nxt else len(text)
    text = text[:cut].rstrip("\n") + "\n\n" + "\n".join(lines) + "\n\n" + text[cut:]
    old = 'SubResource("%s")' % anchor
    text, n = re.subn(r"^(branches = .*?)%s" % re.escape(old), lambda mm: mm.group(1) + old + ', SubResource("%s")' % bid,
                      text, count=0, flags=re.M)
    n == 1 or die("%s: %s is in %d branches lists, want 1" % (p, anchor, n))
    return p, add_ext(text, '[ext_resource type="Resource" path="%s" id="%s"]' % (path, sk))


def put_in_options(role, sid):
    p = "Roles/%s.tres" % role
    text = read(p)
    secs = sections(text)
    skill_ext = ext_id_for(secs, "res://Scripts/Skill.gd") or die("%s: no Skill.gd ext_resource" % p)
    oid = free_id(secs, "opt_" + sid)
    item = 'ExtResource("%s")' % oid
    if re.search(r"^options = ", text, re.M):
        text = re.sub(r"^(options = .*)\]\)$", lambda m: m.group(1) + ", " + item + "])", text, count=1, flags=re.M)
    else:
        text = re.sub(r"^(\[resource\]\n(?:.+\n)*?)(roots = )", lambda m: m.group(1) + 'options = Array[ExtResource("%s")]([%s])\n' % (skill_ext, item) + m.group(2),
                      text, count=1, flags=re.M)
        "options = " in text or die("%s: no roots = line to put options before" % p)
    return p, add_ext(text, '[ext_resource type="Resource" path="res://Skills/%s.tres" id="%s"]' % (sid, oid))


def new(a):
    sid = a.id
    re.fullmatch(r"[a-z][a-z0-9_]*", sid) or die("the id is a file name: lower_snake (kick, second_wind)")
    a.title = a.title or sid.replace("_", " ").title()
    if os.path.exists(os.path.join(ROOT, "Skills/%s.tres" % sid)):
        die("Skills/%s.tres exists" % sid)
    a.tree or a.role or die("give --tree (and --after or --root) and/or --role, or nobody can learn it")
    out = [("Skills/%s.tres" % sid, skill_tres(a))]
    for b in a.behaviour:
        if not os.path.exists(os.path.join(ROOT, "Behaviours/%s.gd" % b)):
            out.append(("Behaviours/%s.gd" % b, BEHAVIOUR_STUB % {"title": a.title, "stub": STUB}))
    if not os.path.exists(os.path.join(ROOT, "Tests/%s_test.gd" % sid)):
        out.append(("Tests/%s_test.gd" % sid, TEST_STUB % {"title": a.title, "id": sid, "stub": STUB}))
    if a.tree:
        out.append(put_on_tree(a, sid))
    if a.role:
        out.append(put_in_options(a.role, sid))
    os.makedirs(os.path.join(ROOT, "Behaviours"), exist_ok=True)
    for p, text in out:
        write(p, text, a.dry_run)
    if a.dry_run:
        return 0
    if not a.no_import:
        print("importing (writes the .gd.uid files)...")
        subprocess.run(["godot", "--headless", "--path", ROOT, "--import"], capture_output=True)
    print("\nnext: fill in the stubs, then `python3 Util/skill.py check` and the tests (CLAUDE.md)")
    return check()


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    n = sub.add_parser("new", help="write a skill and wire it in")
    n.add_argument("id", help="file name: kick -> Skills/kick.tres")
    n.add_argument("--title", help="shown name (default: from the id)")
    n.add_argument("--tags", help="comma separated: physical,blunt,str,martial")
    n.add_argument("--passive", action="store_true")
    n.add_argument("--ap")
    n.add_argument("--cost")
    n.add_argument("--radius", help="range before rank")
    n.add_argument("--range-per-rank", dest="radius_per_rank")
    n.add_argument("--tier", action="append", default=[], help="damage by rank: 1:1d4+strength, 3:2+1d6+direct")
    n.add_argument("--effect", action="append", default=[], help='"stat=luck amount=-1 per_rank=true name=Hexed"')
    n.add_argument("--behaviour", action="append", default=[], help="Behaviours/<name>.gd, stubbed if missing")
    n.add_argument("--set", action="append", default=[], help="any other Skill field: key=value (a .tres literal)")
    n.add_argument("--tree", help="Trees/<x>.tres or Roles/<x>.tres it goes on")
    n.add_argument("--after", help="the skill whose branch it goes beside (and whose root)")
    n.add_argument("--root", help="or: the root (by name) it goes at the end of")
    n.add_argument("--prereq", help="skills to learn first, comma separated (Branch.after)")
    n.add_argument("--branch-tier", type=int, help="its tier on a general tree (Branch.tier)")
    n.add_argument("--role", help="Roles/<x>.tres it's offered by outright (Role.options)")
    n.add_argument("--no-import", action="store_true")
    n.add_argument("--dry-run", action="store_true", help="print what it would write")
    sub.add_parser("check", help="catch the wiring pitfalls")
    a = ap.parse_args()
    sys.exit(new(a) if a.cmd == "new" else check(a))


if __name__ == "__main__":
    main()
