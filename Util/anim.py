"""Gambeson unit animations: a sprite's poses (requirements.md "Animation") made into a SpriteFrames,
Units/<Name>.tres, holding one animation per state a unit plays (Unit.ANIMS: attacking, hit,
investigating, waiting) and `default`, its base pose (icons, portraits, the HUD's face).

The convention (the user's): Units/<Name>.png or <Name>-neutral.png is the base standing pose;
<Name>-left.png leans left (reeling, dodging, rearing up to strike); <Name>-right.png leans right
(hit from behind, a better look, reaching out); numbered ones (<Name>1.png, <Name>-1.png, <Name>_2.png)
are a cycle, generally idle. A missing pose falls back to the base one, so a placeholder with only
its base image keeps working (the game falls back to `default` with no .tres at all: Unit._show_look()).

  python3 Util/anim.py setup Units/Siren        # a sprite
  python3 Util/anim.py setup bard siren          # a class (Roles/), a unit or monster (Scenes/)...
  python3 Util/anim.py setup sirens_by_water     # ...or a prefab (Formations/): each unit's sprite
  python3 Util/anim.py setup --all               # every sprite with poses beyond its base one
  python3 Util/anim.py show Siren                # what each state would play
  python3 Util/anim.py check                     # every .tres current with the poses on disk
"""
import argparse, os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from tres import ROOT, die, exists, read, write

# state -> (poses in order, fps, loops). "cycle": the numbered frames, else the base pose. Keep the names in
# step with Unit.ANIMS (check). `default` is the base pose alone, first: what the HUD reads as its face.
STATES = {
    "default": (["neutral"], 5.0, True),
    "waiting": (["cycle"], 4.0, True),
    "attacking": (["left", "right"], 6.0, False),  # rears up, strikes
    "hit": (["left"], 6.0, False),  # reels
    "investigating": (["right"], 3.0, False),  # a better look
}
# <base>[-pose[-extra]] or <base>[-_]<n>; an extra (-left-raise) is a variant no state plays yet (show lists it)
POSE = re.compile(r"^(?P<base>.+?)(?:[-_]?(?P<num>\d+)|-(?P<pose>neutral|left|right)(?:-(?P<extra>[\w-]+))?)?\.png$", re.I)


def poses(top="Units"):
    """{base name: {"neutral": file, "left": file, "right": file, "cycle": [files by number], "extra": [files]}} in top/."""
    out = {}
    for f in sorted(os.listdir(os.path.join(ROOT, top))):
        m = POSE.match(f)
        if not m:
            continue
        p = out.setdefault(m.group("base"), {"cycle": [], "extra": []})
        pose = (m.group("pose") or "").lower()
        if m.group("extra"):
            p["extra"].append(f)
        elif m.group("num"):
            p["cycle"].append((int(m.group("num")), f))
        elif pose == "neutral":
            p.setdefault("neutral", f)
        else:
            p[pose or "neutral"] = f  # a plain X.png beats X-neutral.png
    for p in out.values():
        p["cycle"] = [f for _, f in sorted(p["cycle"])]
    return {b: p for b, p in out.items() if "neutral" in p}


def frames_of(p):
    """state -> (files, fps, loops): each pose, or the base pose where it's missing."""
    out = {}
    for state, (want, fps, loops) in STATES.items():
        fs = []
        for w in want:
            fs += (p["cycle"] or [p["neutral"]]) if w == "cycle" else [p.get(w, p["neutral"])]
        out[state] = (fs, fps, loops)
    return out


def tres_text(name, p):
    files, anims = [], []
    for state, (fs, fps, loops) in frames_of(p).items():
        for f in fs:
            f in files or files.append(f)
        frames = ",\n".join('{\n"duration": 1.0,\n"texture": ExtResource("%d")\n}' % (files.index(f) + 1) for f in fs)
        anims.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.1f\n}' % (frames, "true" if loops else "false", state, fps))
    ext = "".join('[ext_resource type="Texture2D" path="res://Units/%s" id="%d"]\n' % (f, i + 1) for i, f in enumerate(files))
    return ('[gd_resource type="SpriteFrames" format=3]\n\n%s\n[resource]\n'
            'animations = [%s]\n') % (ext, ", ".join(anims))


def sprites_of(target, seen=None):
    """The sprite names a target uses: Units/<Name>, a Roles/ or Scenes/ id (its look, else its class's), a Formations/ id."""
    seen = seen if seen is not None else set()
    t = re.sub(r"\.(png|tres|tscn)$", "", target)
    if t.startswith("Units/"):
        return [t[6:]]
    for top, ext in (("Formations", ".tres"), ("Scenes", ".tscn"), ("Roles", ".tres")):
        p = t if t.startswith(top + "/") else "%s/%s" % (top, t)
        if exists(p + ext) and p not in seen:
            seen.add(p)
            text = read(p + ext)
            own = re.findall(r'path="res://Units/(\w+)\.png"', text)
            if own:
                return own
            out = []
            for ref in re.findall(r'path="res://((?:Scenes|Roles)/\w+)\.(?:tscn|tres)"', text):
                out += [s for s in sprites_of(ref, seen) if s not in out]
            return out
    if exists("Units/%s.png" % t) or exists("Units/%s-neutral.png" % t):
        return [t]
    die("%s: not a sprite (Units/), class (Roles/), unit (Scenes/) or prefab (Formations/)" % target)


def setup(a):
    have = poses()
    names = [b for b, p in have.items() if p["cycle"] or "left" in p or "right" in p] if a.all else []
    for t in a.targets:
        names += [s for s in sprites_of(t) if s not in names]
    if not names:
        die("nothing to set up (name a target, or --all)")
    for n in names:
        if n not in have:
            die("Units/%s.png (or -neutral) missing" % n)
        write("Units/%s.tres" % n, tres_text(n, have[n]), a.dry_run)
    return 0


def show(a):
    have = poses()
    for t in a.targets:
        for n in sprites_of(t):
            print(n)
            p = have.get(n, {"neutral": n + ".png", "cycle": [], "extra": []})
            for state, (fs, fps, loops) in frames_of(p).items():
                print("  %-14s %s  %g fps%s" % (state, " ".join(fs), fps, ", loops" if loops else ""))
            if p["extra"]:
                print("  (unused variants: %s)" % " ".join(p["extra"]))
    return 0


def check(_a=None):
    problems = []
    have = poses()
    for f in sorted(os.listdir(os.path.join(ROOT, "Units"))):
        if not f.endswith(".tres"):
            continue
        n = f[:-5]
        text = read("Units/" + f)
        if "SpriteFrames" not in text:
            continue
        if n not in have:
            problems.append("Units/%s: its base sprite Units/%s.png is gone" % (f, n))
        elif text != tres_text(n, have[n]):
            problems.append("Units/%s: out of date with its poses (python3 Util/anim.py setup Units/%s)" % (f, n))
    for n, p in have.items():
        if (p["cycle"] or "left" in p or "right" in p) and not exists("Units/%s.tres" % n):
            problems.append("Units/%s: has poses but no Units/%s.tres (python3 Util/anim.py setup Units/%s)" % (n, n, n))
    game = set(re.findall(r'&"(\w+)"', re.search(r"const ANIMS := \{([^}]*)\}", read("Scripts/Unit.gd")).group(1)))
    for s in game - set(STATES):
        problems.append("Unit.ANIMS plays %s, which Util/anim.py STATES doesn't make" % s)
    for p in problems:
        print(p)
    print("anim.py check: %s" % ("%d problem(s)" % len(problems) if problems else "ok"))
    return 1 if problems else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("setup", help="write Units/<Name>.tres for these sprites, classes, units, prefabs")
    s.add_argument("targets", nargs="*")
    s.add_argument("--all", action="store_true", help="every sprite with poses beyond its base one")
    s.add_argument("--dry-run", action="store_true")
    w = sub.add_parser("show", help="what each state plays")
    w.add_argument("targets", nargs="+")
    sub.add_parser("check", help="every Units/*.tres current; every posed sprite set up")
    a = ap.parse_args()
    sys.exit({"setup": setup, "show": show, "check": check}[a.cmd](a))


if __name__ == "__main__":
    main()
