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
FLOATS = {"ap", "radius", "radius_per_rank", "amount", "decays", "carry", "blast", "strike_ap", "restores", "rank_growth", "cone", "drag"}
NAME_LISTS = {"tags", "unless_on", "checks", "damage_tags", "shows_tags", "strategy", "general"}  # comma lists -> Array[StringName]


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


def effect_props(spec):
    """An Effect's properties from "stat=mitigate amount=0.5 tags=fire,water per_rank=true"."""
    out = []
    for kv in spec.split():
        k, _, v = kv.partition("=")
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

    def effect(self, sid, spec):
        return self.sub(sid, "res://Scripts/Effect.gd", effect_props(spec))

    def text(self, tail="[resource]"):
        return "\n\n".join([self.head, "\n".join(self.ext)] + self.subs + [tail + "\n" + "\n".join(self.props)]) + "\n"


def typed(script_path, doc, refs):
    """A typed array of resources: Array[ExtResource("<script>")]([refs...])."""
    return "Array[%s]([%s])" % (doc.res("Script", script_path), ", ".join(refs))
