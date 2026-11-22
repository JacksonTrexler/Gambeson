"""Shared by Gambeson's authoring tools (skill.py, tile.py, role.py, unit.py, mechanic.py): read and write Godot
.tres/.tscn text without Godot, and the conventions every tool keeps.

Conventions (CLAUDE.md): anything an AI names gets " ??" after its shown name until a person reviews it
(ai_name(); a skill carries `ai = true` instead, Skill.title()); new art is a placeholder PNG at a fixed
path that real art replaces (icon.py); tools import after writing, so new scripts and PNGs get their
.uid/.import files. Plain python3, no dependencies.
"""
import os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REVIEW = " ??"  # after a name an AI made up, until a person reviews it
FLOATS = {"ap", "radius", "radius_per_rank", "amount", "decays", "carry", "blast", "strike_ap", "restores", "rank_growth", "drag"}
NAME_LISTS = {"tags", "bears", "unless_on", "checks", "damage_tags", "shows_tags", "strategy", "general"}  # comma lists -> Array[StringName]


def rel(p):
    return os.path.relpath(p, ROOT)


def exists(p):
    return os.path.exists(os.path.join(ROOT, p))


def read(p):
    with open(os.path.join(ROOT, p), encoding="utf-8") as f:
        return f.read()


def write(p, text, dry):
    if dry:
        print("--- would write %s ---\n%s" % (p, text))
        return
    os.makedirs(os.path.dirname(os.path.join(ROOT, p)), exist_ok=True)
    with open(os.path.join(ROOT, p), "w", encoding="utf-8") as f:
        f.write(text)
    print("wrote", p)


def die(msg):
    sys.exit("%s: %s" % (os.path.basename(sys.argv[0]), msg))


def ai_name(name, human=False):
    """The name as shown: an AI's gets REVIEW after it (CLAUDE.md), a person's stays as it is."""
    return name if human or name.endswith(REVIEW.strip()) else name + REVIEW


def snake(s):
    return re.sub(r"[^a-z0-9]+", "_", s.lower()).strip("_")


def import_project():
    print("importing (writes .uid and .import files)...")
    subprocess.run(["godot", "--headless", "--path", ROOT, "--import"], capture_output=True)


def readers(word):
    """The scripts that ask about &"word": where the rules react to a tag."""
    return sorted({rel(p) for top in ("Scripts", "Behaviours") for p in [os.path.join(ROOT, f) for f in files(top, ".gd")]
                   if '&"%s"' % word in read(rel(p))})


def files(top, ext):
    for d, dirs, fs in os.walk(os.path.join(ROOT, top)):
        dirs[:] = [x for x in dirs if not x.startswith(".")]
        for f in fs:
            if f.endswith(ext):
                yield rel(os.path.join(d, f))


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


# --- trees

def tree_roots(p):  # the roots in a .tres: [{name, branches: [(skill path, [after paths], tier, needs)], includes: [tree files]}], the [resource] one flagged "main"
    secs = sections(read(p))
    ext = ext_ids(secs)
    branch = {}
    for s in secs:
        if s["kind"] == "sub_resource" and "skill" in s["props"]:
            pr = s["props"]
            skill = ext.get(REF.search(pr["skill"]).group(2)) if REF.search(pr["skill"]) else None
            after = [ext.get(i) for i in items(pr["after"])] if "after" in pr else []
            tier = int(pr["tier"]) if pr.get("tier", "").strip().isdigit() else 0
            needs = int(pr["needs"]) if pr.get("needs", "").strip().isdigit() else 0
            branch[s["attrs"]["id"]] = (skill, after, tier, needs)
    out = []
    for s in secs:
        if s["kind"] in ("sub_resource", "resource") and "branches" in s["props"]:
            inc = [ext.get(i, "") for i in items(s["props"]["includes"])] if "includes" in s["props"] else []
            out.append({"name": s["props"].get("name", s["attrs"].get("id", "")).strip('"'), "main": s["kind"] == "resource", "includes": [x.replace("res://", "") for x in inc],
                        "branches": [branch[i] for i in items(s["props"]["branches"]) if i in branch]})
    return out


def composition_problems():
    """Tree composition (SkillRoot.includes): a root that includes trees shows their skills as its own, so they must not
    loop, repeat a skill, name a file that isn't a tree, or leave a prerequisite or tier unresolved in the composed whole."""
    problems, cache = [], {}

    def root_of_file(f):
        if f not in cache:
            cache[f] = next((r for r in tree_roots(f) if r["main"]), None) if os.path.exists(os.path.join(ROOT, f)) else None
        return cache[f]

    def compose(root, trail, problems_for):  # its branches then its included trees', each [(branch, from file)]
        out = [(b, trail[0]) for b in root["branches"]]
        for f in root["includes"]:
            inc = root_of_file(f)
            if inc is None:
                problems_for.append("includes %s, which isn't a tree root (a Trees/ file whose [resource] is a SkillRoot)" % f)
            elif f in trail:
                problems_for.append("includes %s again: a loop (%s)" % (f, " -> ".join(trail + [f])))
            else:
                out += compose(inc, trail + [f], problems_for)
        return out

    for p in sorted(list(files("Trees", ".tres")) + list(files("Roles", ".tres")) + list(files("Gods", ".tres"))):
        for root in tree_roots(p):
            if not root["includes"]:
                continue
            mine = []
            whole = compose(root, [p], mine)
            seen, tiers = {}, {}
            for (skill, after, tier, needs), src in whole:
                if skill in seen:
                    mine.append("%s is on it twice (%s and %s)" % (skill, seen[skill], src))
                seen[skill] = src
                tiers[skill] = tier
            for (skill, after, tier, needs), src in whole:
                for a in after:
                    if a not in seen:
                        mine.append("%s (from %s) comes after %s, which it doesn't hold" % (skill, src, a))
                    elif tier and tiers[a] and tiers[a] >= tier:
                        mine.append("%s (T%d) comes after %s (T%d): its tier must be higher" % (skill, tier, a, tiers[a]))
                if tier == 0 and any(t for t in tiers.values()):
                    mine.append("%s (from %s) has no tier, where its tree sets them (python3 Util/skill.py new --branch-tier)" % (skill, src))
            for m in mine:
                problems.append("%s: root %s %s" % (p, root["name"], m))
    return problems


# --- values

def names(v):
    """A comma list as a typed array of StringNames: fire,water -> Array[StringName]([&"fire", &"water"])."""
    return "Array[StringName]([%s])" % ", ".join('&"%s"' % x.strip() for x in v.split(",") if x.strip())


def strings(v):
    return "Array[String]([%s])" % ", ".join('"%s"' % x.strip() for x in v.split(",") if x.strip())


def literal(key, v):
    if v in ("true", "false") or re.fullmatch(r"-?\d+", v) and key not in FLOATS:
        return v
    if re.fullmatch(r"-?\d+(\.\d+)?", v):
        return v if "." in v else v + ".0"
    if re.fullmatch(r"\w+(\[[\w, ]*\])?\(.*\)|&\".*\"|\".*\"|\[.*\]", v, re.S):
        return v  # already a literal: Vector2i(1, 4), Array[String](["Precious"]), &"str", "text"
    if key in NAME_LISTS:
        return names(v)
    return '"%s"' % v


def effect_props(spec, human=True):
    """An Effect's properties from "stat=mitigate amount=0.5 tags=fire,water per_rank=true". human=False: an
    AI made it, so a name= gets REVIEW (a name with spaces: name=Hot_Coals, underscores for spaces)."""
    out = []
    for kv in spec.split():
        k, _, v = kv.partition("=")
        if k == "name":
            v = '"%s"' % ai_name(v.replace("_", " ").strip('"'), human)
        out.append("%s = %s" % (k, literal(k, v) if k != "stat" else '"%s"' % v))
    return out


def effect_section(i, spec, ext):
    return "\n".join(['[sub_resource type="Resource" id="Effect_%d"]' % i, 'script = ExtResource("%s")' % ext] + effect_props(spec))


class Doc:
    """A new .tres or .tscn built up in order: ext resources (deduplicated by path), sub resources, then the
    [resource] (or a scene's root node) properties."""

    def __init__(self, head):
        self.head, self.ext, self.subs, self.props, self._ids = head, [], [], [], {}

    def res(self, kind, path):
        """ExtResource("id") for path, declared once."""
        if path not in self._ids:
            base = snake(os.path.splitext(os.path.basename(path))[0]) or "res"
            self._ids[path] = "%d_%s" % (len(self._ids) + 1, base)
            self.ext.append('[ext_resource type="%s" path="%s" id="%s"]' % (kind, path, self._ids[path]))
        return 'ExtResource("%s")' % self._ids[path]

    def sub(self, sid, script_path, props):
        """SubResource("sid"), scripted by script_path, with props (["key = value", ...])."""
        self.subs.append("\n".join(['[sub_resource type="Resource" id="%s"]' % sid, "script = " + self.res("Script", script_path)] + props))
        return 'SubResource("%s")' % sid

    def effect(self, sid, spec, human=True):
        return self.sub(sid, "res://Scripts/Effect.gd", effect_props(spec, human))

    def text(self, tail="[resource]"):
        return "\n\n".join([self.head, "\n".join(self.ext)] + self.subs + [tail + "\n" + "\n".join(self.props)]) + "\n"


def typed(script_path, doc, refs):
    """A typed array of resources: Array[ExtResource("<script>")]([refs...])."""
    return "Array[%s]([%s])" % (doc.res("Script", script_path), ", ".join(refs))
