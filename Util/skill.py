#!/usr/bin/env python3
"""Gambeson skill authoring: write a skill and wire it in (`new`), and catch the wiring pitfalls (`check`).

  python3 Util/skill.py new kick --tags physical,blunt,str,martial,offensive --intensity low --stat strength \\
      [--impact tame] [--penalty minor] [--requires "test=concealed share=0.3 edge=1"] [--check "against=wisdom save=true ranked=true"] [--cost "high stamina, low ap"] \\
      --range-per-rank 1 --behaviour kick --tree general_martial --after brutal_strike \\
      --branch-tier 1 [--role fighter] [--prereq snare] [--effect "stat=luck amount=-1 per_rank=true"] \\
      [--set rolls=false] [--passive] [--lent] [--test] [--no-import] [--dry-run]
  python3 Util/skill.py new alluring --trait --tags siren ...  # a trait: always on, no hotbar slot (Unit.equipped()); declared, never inferred
  python3 Util/skill.py trait starsap [--off]   # declare an existing passive a trait (or take the declaration off)
  python3 Util/skill.py check       # cheap, plain text: run before every commit (Tests/skills_test.gd runs it too)
  python3 Util/skill.py drift       # information: hand-set AP / cost against the cost calculator's (Scripts/Pricing.gd)
  python3 Util/skill.py modifiers   # information: skills no modifier fits, and why - to parameterize (Scripts/Modifiers.gd)
  python3 Util/skill.py terms kick  # one skill's terms: channels, intensity, impact, contingencies, price, modifiers
  python3 Util/skill.py cost kick "high ap, low cost"         # set (or change) a skill's cost profile; prints its price
  python3 Util/skill.py cost kick hand --ap 4 --points 1      # back to a hand price
  python3 Util/skill.py migrate [--dry-run]  # hand prices a profile reproduces exactly at every rank -> that profile

A cost profile (Skill.costs; Scripts/Pricing.gd profile(), docs/plans/w2-cost.md) skews the computed price:
comma-separated clauses "[level] [only|prefers] <dimension>" - levels no, low, moderate (the default), high,
very high (light/heavy, free/cheap too); dimensions ap, cost (whatever pays), or a reserve: mana, stamina, focus,
sweet nothings ("mana" alone: preferred, paid with first; "mana only": nothing else pays) - plus "flat rank"
(every rank costs as rank I) or "steep rank" (rank's growth doubled), or "even" (the baseline).

`new` writes a skill in terms (intensity, impact, penalty, a requirement: Scripts/SkillTerms.gd), priced by the cost
calculator (Scripts/Pricing.gd) by its --cost profile (default "even") unless --hand-priced, then shows its terms and the modifiers it fits. It writes Skills/<id>.tres, a behaviour stub (Behaviours/<b>.gd) if it names one that doesn't exist (and then,
and only then, a test stub, Tests/<id>_test.gd: a data-only skill is covered by Tests/sweep_test.gd; --test forces one), puts the skill on a tree (Trees/ or Roles/ <file>, beside --after's branch or at the
end of --root's) and in --role's options, imports, then checks. It edits text by anchors and stops if one is
missing. Stubs carry STUB: check fails until they're filled in. Plain python3, no dependencies.
"""
import argparse, os, re, subprocess, sys

from tres import (ROOT, REF, die, read, write, rel, files, sections, ext_ids, ext_id_for, items, add_ext, free_id,
                  literal, effect_section, names, composition_problems)
STUB = "STUB(skill.py)"
FLAG_CEILING = 104  # (+1 2026-11-19: `no_density`, the Terms group's declared reason a skill is ineligible for Density, docs/plans/w4-density.md; -1 2026-11-18: `inherent` went; `priced` became `costs`, the cost profile, docs/plans/w2-cost.md; -22 2026-11-15: tile skills and the self/utility block became behaviours, forced movement one Displace (docs/plans/consolidation.md, B4 and B5); -3 +1 2026-11-14: `save`, `resisted` and `drags_to` became one `check`, a SkillCheck (docs/plans/checks.md); +5 2026-11-14: the Terms group every skill shares - intensity, impact, penalty, requires, priced; -1: `pings` became Behaviours/clairvoyance.gd; -1: `cinders` was dead - its Effect does the work) @export vars on Skill.gd: new behaviour goes in Behaviours/, not a new flag (CLAUDE.md).
HOOKS = ("apply_at", "lets_word", "hurt", "healing", "affinity", "command_mod", "ordered", "step_cost", "aim", "edge", "guard", "bonus", "felled", "held", "refunds", "unguarded", "foresee", "reprisal", "revives", "strides", "react", "neutralized", "wearing", "striking", "armor", "summon_ap", "armor_slot", "slot_works", "slot_defense", "slot_blocked")  # Behaviour's hooks: what a passive's behaviour does outside a cast (apply_at: a tile skill's cast)
def skill_refs(secs):  # Branch sub_resource id -> skill ext id
    return {s["attrs"]["id"]: REF.search(s["props"]["skill"]).group(2)
            for s in secs if s["kind"] == "sub_resource" and "skill" in s["props"] and REF.search(s["props"]["skill"])}


# --- check

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


FLAVOUR = {"idealism", "lawful"}  # tags only lore reads, for now (Coordinate, Judgement)


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
        if "func describe(" not in text:
            problems.append("%s: no describe() - a behaviour does and says, side by side" % p)
        if not any("func %s(" % f in text for f in ("apply", "dealt") + HOOKS):  # dealt: after an active's damage lands (Energy Transfer)
            problems.append("%s: no apply() or hook (%s) - it does nothing" % (p, ", ".join(HOOKS)))
        if "res://" + p not in used:
            problems.append("%s: no skill uses it" % p)
        if "func react(" in text:  # the reaction seam (Battle.react()): effects tagged reaction count on what reacts
            for sp in files("Skills", ".tres"):
                st = read(sp)
                if "res://" + p in st and '&"reaction"' not in st:
                    problems.append("%s: its behaviour reacts (%s) but it isn't tagged reaction" % (sp, p))


TAPPING = ("helpless", "sleep")  # Effect stats that take a unit's actions away: a skill putting one on taps


def check_check_tags(problems):
    """The check tag seam (Unit.check_bonus()): a check carries its skill's tags, so a skill that can tap a unit
    must carry `taps`, and one that executes `execute` - else what helps with such checks (Bless) misses it."""
    def stat_of(path):
        m = re.search(r'^stat = "(\w+)"', read(path), re.M) if os.path.exists(os.path.join(ROOT, path)) else None
        return m.group(1) if m else ""
    for p in sorted(files("Skills", ".tres")):
        text = read(p)
        tags = set(re.findall(r'&"(\w+)"', next((x["props"]["tags"] for x in sections(text) if x["kind"] == "resource" and "tags" in x["props"]), "")))
        stats = set(re.findall(r'^stat = "(\w+)"', text, re.M))
        for ref in re.findall(r'path="res://((?:Effects|Behaviours)/[\w/]+\.(?:tres|gd))"', text):
            if ref.startswith("Effects/"):
                stats.add(stat_of(ref))
            else:
                stats.update(stat_of(e) for e in re.findall(r'preload\("res://(Effects/[\w/]+\.tres)"\)', read(ref)))
        if stats & set(TAPPING) and "taps" not in tags:
            problems.append('%s: it can tap a unit (puts on %s) but has no "taps" tag - checks carry their skill\'s tags, so what helps with checks that tap would miss it' % (p, "/".join(sorted(stats & set(TAPPING)))))
        if re.search(r"^kills = true", text, re.M) and "execute" not in tags:
            problems.append('%s: it executes (kills) but has no "execute" tag - what helps against executes would miss it' % p)


def trait_tagged(text):
    return '&"trait"' in next((x["props"].get("tags", "") for x in sections(text) if x["kind"] == "resource"), "")


def check_traits(problems):
    """A trait (Unit.equipped(): always on, no hotbar slot) is declared, never inferred (docs/plans/w3-traits.md): the tag
    `trait`, written by `skill.py new --trait` / `skill.py trait`. It has nothing to cast, switch or disable, so it is
    a plain always-on passive: not a toggle, hybrid or pillar. And a unit scene holds one as innate (unit.py new --trait),
    never among what it learned, where a trait isn't one of its slotted skills."""
    for p in sorted(files("Skills", ".tres")):
        text = read(p)
        if trait_tagged(text):
            res = next(x for x in sections(text) if x["kind"] == "resource")["props"]
            if res.get("passive") != "true" or any(res.get(k) == "true" for k in ("toggle", "hybrid")):
                problems.append("%s: tagged trait but not an always-on passive (a trait takes no slot, so it can't be cast or switched)" % p)
            elif '&"pillar"' in res.get("tags", "") or '&"foundation"' in res.get("tags", ""):
                problems.append("%s: tagged trait but a pillar (pillars sit on the hotbar for a curse to reach; a trait is out of its reach)" % p)
    for p in sorted(files("Scenes", ".tscn")):
        text = read(p)
        paths = {i: pth for pth, i in re.findall(r'path="([^"]+)" id="(\w+)"', text)}
        subs = {}
        for m in re.finditer(r'\[sub_resource [^\]]*id="(\w+)"\]\n((?:.+\n?)*)', text):
            k = re.search(r'^skill = ExtResource\("(\w+)"\)', m.group(2), re.M)
            if k:
                subs[m.group(1)] = paths.get(k.group(1), "").replace("res://", "")
        for node in text.split("\n[node ")[1:]:
            lm = re.search(r'^learned = .*$', node, re.M)
            for i in re.findall(r'SubResource\("(\w+)"\)', lm.group(0)) if lm else []:
                f = subs.get(i, "")
                if f and os.path.exists(os.path.join(ROOT, f)) and trait_tagged(read(f)):
                    problems.append("%s: %s is a trait but listed as learned: a unit's trait is innate (python3 Util/unit.py trait <unit> %s)" % (p, f, os.path.basename(f)[:-5]))


def check_flags(problems):
    n = len(re.findall(r"^@export var ", read("Scripts/Skill.gd"), re.M))
    if n > FLAG_CEILING:
        problems.append("Scripts/Skill.gd: %d flags, over %d - put new behaviour in a Behaviours/ script (CLAUDE.md); "
                        "raise FLAG_CEILING in Util/skill.py only for a field every skill shares" % (n, FLAG_CEILING))


# Cost profiles (Skill.costs), as Scripts/Pricing.gd profile() reads them: keep the two in step.
LEVELS = {"none": 0.0, "no": 0.0, "free": 0.0, "low": 0.5, "light": 0.5, "cheap": 0.5, "moderate": 1.0, "medium": 1.0,
          "normal": 1.0, "even": 1.0, "high": 1.5, "heavy": 1.5, "very high": 2.0, "very heavy": 2.0}
RANK_WORDS = {"flat": 0.0, "scaled": 1.0, "steep": 2.0}
GENERIC = ("cost", "energy", "resource")
RESERVES = ("mana", "stamina", "focus", "sweet_nothings")  # Reserves/<id>.tres
HOW = ("only", "needs", "prefers")


def profile(text):
    """A cost profile read: {ap, cost, rank, reserve, only}; dies-free: raises ValueError with what's wrong."""
    out = {"ap": 1.0, "cost": 1.0, "rank": 1.0, "reserve": "", "only": False}
    seen = False
    for raw in re.split(r",|;| and ", text.lower()):
        raw = raw.strip()
        words = raw.replace("sweet nothings", "sweet_nothings").replace("sweet nothing", "sweet_nothings").split()
        while len(words) > 1 and words[-1] in ("cost", "costs") and words[-2] in ("ap",) + GENERIC + RESERVES:
            words.pop()
        if not words or words == ["even"]:
            continue
        if len(words) == 2 and words[1] == "rank" and words[0] in RANK_WORDS:
            out["rank"] = RANK_WORDS[words[0]]
            continue
        how = next((x for x in HOW if x in words), "")
        words = [x for x in words if x not in HOW]
        if not words:
            raise ValueError('"%s": %s what?' % (raw, how))
        dim = words.pop()
        level = " ".join(words)
        if level and level not in LEVELS:
            raise ValueError('"%s": no level "%s" (%s)' % (raw, level, ", ".join(LEVELS)))
        w = LEVELS.get(level, 1.0)
        if dim in ("health", "hp", "life"):
            raise ValueError('"%s": no skill costs health yet (a mechanic first: new-mechanic)' % raw)
        if dim == "ap":
            if how:
                raise ValueError('"%s": only, needs and prefers name a resource, not AP' % raw)
            out["ap"] = w
            continue
        if dim not in GENERIC + RESERVES:
            raise ValueError('"%s": no dimension "%s" (ap, %s, or <flat|scaled|steep> rank)' % (raw, dim, ", ".join(GENERIC + RESERVES)))
        if seen:
            raise ValueError('"%s": a second resource (a skill has one cost)' % raw)
        seen = True
        if how and dim in GENERIC:
            raise ValueError('"%s": only, needs and prefers name a reserve (%s)' % (raw, ", ".join(RESERVES)))
        out["cost"] = w
        if dim in RESERVES:
            out["reserve"], out["only"] = dim, how in ("only", "needs")
    return out


def check_costs(problems):
    """Every cost profile parses, belongs to an active (or hybrid), and says "X only" exactly where it needs X."""
    for p in sorted(files("Skills", ".tres")):
        res = next((x for x in sections(read(p)) if x["kind"] == "resource"), None)
        if not res or "costs" not in res["props"]:
            continue
        text = res["props"]["costs"].strip('"')
        try:
            prof = profile(text)
        except ValueError as e:
            problems.append("%s: cost profile %s" % (p, e))
            continue
        if not text:
            problems.append('%s: costs = "" is hand-priced: drop the line (skill.py cost %s hand)' % (p, p[7:-5]))
        if res["props"].get("passive") == "true" and res["props"].get("hybrid") != "true":
            problems.append("%s: a cost profile on a passive (it costs nothing)" % p)
        needs = REF.search(res["props"].get("needs", ""))
        needs_path = ext_ids(sections(read(p))).get(needs.group(2)) if needs else None
        want = "res://Reserves/%s.tres" % prof["reserve"] if prof["only"] else None
        if needs_path != want:
            problems.append("%s: its profile says %s but its needs is %s (skill.py cost sets both)" % (
                p, '"%s only"' % prof["reserve"] if want else "no reserve only", needs_path or "none"))


def check_stubs(problems):
    for top, ext in (("Tests", ".gd"), ("Behaviours", ".gd"), ("Skills", ".tres")):
        for p in files(top, ext):
            for k, line in enumerate(read(p).split("\n")):
                m = re.search(r"STUB\((\w+\.py)\)", line)  # any tool's stub: skill.py, unit.py...
                if m:
                    problems.append("%s:%d: a stub %s wrote, still to fill in" % (p, k + 1, m.group(1)))


def check_icons(problems):
    import icon
    for sid in icon.missing_skill_icons():
        problems.append("Skills/%s.tres: no %s/%s.png (python3 Util/icon.py skill %s)" % (sid, icon.SKILL_ICONS, sid, sid))
    for f in os.listdir(os.path.join(ROOT, icon.SKILL_ICONS)):
        if f.endswith(".png") and not os.path.exists(os.path.join(ROOT, "Skills", f[:-4] + ".tres")):
            problems.append("%s/%s: an icon for no skill (renamed? move it with the skill)" % (icon.SKILL_ICONS, f))
    import item
    problems.extend(item.problems())  # every item and loot table: icons, tags, rarity, qualities, lent skills (item.py check)


def check(_args=None):
    problems = []
    for f in (check_refs, check_reachable, check_tags, check_uids, check_behaviours, check_check_tags, check_traits, check_flags, check_costs, check_stubs, check_icons):
        f(problems)
    problems.extend(composition_problems())  # SkillRoot.includes: the trees a tree is composed of (role.py check too)
    for p in problems:
        print(p)
    print("skill.py check: %s" % ("%d problem%s" % (len(problems), "" if len(problems) == 1 else "s") if problems else "ok"))
    return 1 if problems else 0


# --- new

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


# The user's damage intensities -> (Difficulty.MAGNITUDE word, the dice a new skill's rank I tier rolls).
INTENSITY = {"low": ("faint", "1d4"), "moderate_low": ("mild", "1d6"), "moderate": ("moderate", "1d10"),
             "high": ("strong", "2d6"), "extreme": ("severe", "2d12")}
REQUIRES = ("hp_below", "hp_above", "energy_above", "energy_below", "target_hp_below", "target_hp_above", "ally_within", "concealed")


def terms_props(a, ext, subs, props):
    """The skill's terms (Scripts/SkillTerms.gd): intensity, impact, penalty, requirement, and priced unless
    hand-priced. Written so the cost calculator prices it and modifiers find it eligible."""
    if a.intensity:
        a.intensity in INTENSITY or die("--intensity: one of %s" % ", ".join(INTENSITY))
        word, dice = INTENSITY[a.intensity]
        props.append('intensity = &"%s"' % word)
        if not a.tier:  # its rank I tier from the intensity, + its stat mod if --stat
            a.tier = ["1:%s%s" % (dice, "+" + a.stat if a.stat else "")]
    if a.impact:
        a.impact in ("tame", "impactful") or die("--impact: tame or impactful")
        props.append('impact = &"%s"' % a.impact)
    if a.penalty:
        a.penalty in ("minor", "major", "severe") or die("--penalty: minor, major or severe")
        props.append('penalty = &"%s"' % a.penalty)
    if a.requires:
        kv = dict(x.partition("=")[::2] for x in a.requires.split())
        kv.get("test") in REQUIRES or die('--requires "test=<%s> share=0.2 hit=2 damage=0 edge=1 per_rank=false"' % "|".join(REQUIRES))
        ext.append('[ext_resource type="Script" path="res://Scripts/Requirement.gd" id="5_requirement"]')
        lines = ['[sub_resource type="Resource" id="Requirement_1"]', 'script = ExtResource("5_requirement")', 'test = &"%s"' % kv.pop("test")]
        for k, v in kv.items():
            k in ("share", "hit", "damage", "edge", "per_rank") or die("--requires: no field %s" % k)
            lines.append("%s = %s" % (k, literal(k, v) if k != "share" else (v if "." in v else v + ".0")))
        subs.append("\n".join(lines))
        props.append('requires = SubResource("Requirement_1")')
    if a.check:
        ext.append('[ext_resource type="Script" path="res://Scripts/SkillCheck.gd" id="%s"]' % CHECK_EXT)
        subs.append(check_section(dict(x.partition("=")[::2] for x in a.check.split())))
        props.append('check = SubResource("SkillCheck_1")')
    if not a.passive and not a.hand_priced:  # its AP and cost from the cost calculator (Scripts/Pricing.gd), by its profile
        text = a.cost or "even"
        try:
            prof = profile(text)
        except ValueError as e:
            die("--cost %s" % e)
        props.append('costs = "%s"' % text)
        if prof["only"]:
            ext.append('[ext_resource type="Resource" path="res://Reserves/%s.tres" id="7_needs"]' % prof["reserve"])
            props.append('needs = ExtResource("7_needs")')


CHECK_EXT = "6_skill_check"
CHECK_FIELDS = {"stat": "name", "against": "name", "save": "bool", "ranked": "bool", "edge": "int", "range_penalty": "int",
                "tags": "names", "drags_to": "name", "suspicion": "bool"}  # Scripts/SkillCheck.gd


def check_section(kv, ext=CHECK_EXT):  # a skill's declared check (Skill.check): --check "against=wisdom save=true ranked=true"
    lines = ['[sub_resource type="Resource" id="SkillCheck_1"]', 'script = ExtResource("%s")' % ext]
    for k, v in kv.items():
        kind = CHECK_FIELDS.get(k) or die("--check: no field %s (%s)" % (k, ", ".join(CHECK_FIELDS)))
        lines.append("%s = %s" % (k, '&"%s"' % v if kind == "name" else (names(v) if kind == "names" else v)))
    return "\n".join(lines)


def skill_tres(a):
    ext = ['[ext_resource type="Script" path="res://Scripts/Skill.gd" id="1_skill"]']
    subs, props = [], ['script = ExtResource("1_skill")', 'name = "%s"' % a.title]
    if not a.human:
        props.append("ai = true")  # an AI's design: shown "Name ??" until a human reviews it (CLAUDE.md)
    if a.glyph:
        props.append('glyph = "%s"' % a.glyph)
    if a.passive:
        props.append("passive = true")
    if a.tags:
        props.append("tags = Array[StringName]([%s])" % ", ".join('&"%s"' % t for t in a.tags.split(",")))
    if a.effect:
        ext.append('[ext_resource type="Script" path="res://Scripts/Effect.gd" id="2_effect"]')
        subs += [effect_section(i + 1, e, "2_effect") for i, e in enumerate(a.effect)]
        props.append('effects = Array[ExtResource("2_effect")]([%s])' % ", ".join('SubResource("Effect_%d")' % (i + 1) for i in range(len(a.effect))))
    terms_props(a, ext, subs, props)
    for key in ("ap", "cost", "radius", "radius_per_rank"):
        v = getattr(a, key)
        if key in ("ap", "cost") and not a.hand_priced:
            continue  # --cost is the profile, unless hand-priced
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


# An active skill's: runs as it lands. A passive's works through Behaviour's hooks instead (lets_word,
# hurt, healing, affinity, command_mod, ordered: Scripts/Behaviour.gd) - replace this with those it needs, or add a hook there.
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
    roots = [s for s in secs if s["kind"] in ("sub_resource", "resource") and "branches" in s["props"]]
    if a.after:
        aid = ext_id_for(secs, "res://Skills/%s.tres" % a.after) or die("%s: --after %s isn't on it" % (p, a.after))
        anchor = next((b for b, s in skill_refs(secs).items() if s == aid), None) or die("%s: no branch for %s" % (p, a.after))
        root = next((r for r in roots if 'SubResource("%s")' % anchor in r["props"]["branches"]), None) or die("%s: %s is on no root" % (p, a.after))
    else:
        root = next((r for r in roots if a.root in (None, r["props"].get("name", "").strip('"'))), None) or die("%s: no root %s" % (p, a.root))
        anchor = (items(root["props"]["branches"]) or [None])[-1]  # None: a new tree's first skill (role.py --tree)
    lines = ['[sub_resource type="Resource" id="%s"]' % bid, 'script = ExtResource("%s")' % branch, 'skill = ExtResource("%s")' % sk]
    if a.prereq:
        skill_ext = ext_id_for(secs, "res://Scripts/Skill.gd")
        if not skill_ext:  # a new tree (role.py) declares no Skill.gd yet: declare it
            skill_ext = free_id(secs, "skill")
            text = add_ext(text, '[ext_resource type="Script" path="res://Scripts/Skill.gd" id="%s"]' % skill_ext)
        pre = [ext_id_for(secs, "res://Skills/%s.tres" % x) or die("%s: --prereq %s isn't on it" % (p, x)) for x in a.prereq.split(",")]
        lines.append('after = Array[ExtResource("%s")]([%s])' % (skill_ext, ", ".join('ExtResource("%s")' % x for x in pre)))
    if a.branch_tier:
        lines.append("tier = %d" % a.branch_tier)
    if a.needs:
        lines.append("needs = %d" % a.needs)
    if anchor is None:  # the first branch: before the [resource] (or the root's own section), alone in its list
        at = re.search(r"^\[resource\]$", text, re.M) if root["kind"] == "resource" else \
            re.search(r'^\[sub_resource type="Resource" id="%s"\]$' % re.escape(root["attrs"]["id"]), text, re.M)
        text = text[:at.start()] + "\n".join(lines) + "\n\n" + text[at.start():]
        text, n = re.subn(r"^(branches = Array\[[^\]]*\]\(\[)\]\)", lambda mm: mm.group(1) + 'SubResource("%s")])' % bid, text, count=1, flags=re.M)
        n == 1 or die("%s: no empty branches list to start" % p)
        return p, add_ext(text, '[ext_resource type="Resource" path="%s" id="%s"]' % (path, sk))
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
        if "options = " not in text:  # a class with no roots of its own (the Warlock): at the end of its resource
            text = text.rstrip("\n") + '\noptions = Array[ExtResource("%s")]([%s])\n' % (skill_ext, item)
    return p, add_ext(text, '[ext_resource type="Resource" path="res://Skills/%s.tres" id="%s"]' % (sid, oid))


def new(a):
    sid = a.id
    re.fullmatch(r"[a-z][a-z0-9_]*", sid) or die("the id is a file name: lower_snake (kick, second_wind)")
    if a.ap and not a.passive and not a.hand_priced:
        die("--ap sets a hand price: add --hand-priced (and say why), or give a --cost profile (\"high mana, low ap\")")
    if a.hand_priced and a.cost and not re.fullmatch(r"\d+", a.cost):
        die("--hand-priced takes --cost as a number (Energy); a profile is for skills the calculator prices")
    a.title = a.title or sid.replace("_", " ").title()
    if os.path.exists(os.path.join(ROOT, "Skills/%s.tres" % sid)):
        die("Skills/%s.tres exists" % sid)
    if a.trait:  # declared here, never inferred: always on, no slot (Unit.equipped())
        a.passive = True
        a.tags = ",".join(filter(None, [a.tags, "trait"])) if "trait" not in (a.tags or "").split(",") else a.tags
        any(re.match(r"(toggle|hybrid)=true", x) for x in a.set) and die("--trait: a trait is a plain always-on passive (no toggle or hybrid)")
    a.tree or a.role or a.trait or a.lent or die("give --tree (and --after or --root) and/or --role, or nobody can learn it (a --trait may go to a unit instead: python3 Util/unit.py trait <unit> <id>) - or --lent, for a skill only an item lends (Item.skills)")
    out = [("Skills/%s.tres" % sid, skill_tres(a))]
    own_rule = a.test  # a test file only for a behaviour of its own (a new Behaviours/*.gd), or when asked: data-only skills ride the sweep (CLAUDE.md)
    for b in a.behaviour:
        if not os.path.exists(os.path.join(ROOT, "Behaviours/%s.gd" % b)):
            out.append(("Behaviours/%s.gd" % b, BEHAVIOUR_STUB % {"title": a.title, "stub": STUB}))
            own_rule = True
    if own_rule and not os.path.exists(os.path.join(ROOT, "Tests/%s_test.gd" % sid)):
        out.append(("Tests/%s_test.gd" % sid, TEST_STUB % {"title": a.title, "id": sid, "stub": STUB}))
    if a.tree:
        out.append(put_on_tree(a, sid))
    if a.role:
        out.append(put_in_options(a.role, sid))
    os.makedirs(os.path.join(ROOT, "Behaviours"), exist_ok=True)
    for p, text in out:
        write(p, text, a.dry_run)
    if not a.dry_run:
        import icon
        icon.skill_icon(sid, a.glyph)  # a placeholder of its mark: replace the PNG with art any time
    if a.dry_run:
        return 0
    if not a.no_import:
        print("importing (writes the .gd.uid files)...")
        subprocess.run(["godot", "--headless", "--path", ROOT, "--import"], capture_output=True)
    report("terms", sid)  # its channels, price and the modifiers it fits: none listed means too concrete
    print("\nnext: fill in the stubs, then `python3 Util/skill.py check` and the tests (CLAUDE.md)")
    own_rule or print("no test file: Tests/sweep_test.gd casts it; a rule of its own is tested where that rule lives")
    return check()


def set_cost(sid, text, ap=None, points=None, dry=False):
    """Set skill sid's cost profile (or text "hand": a hand price, ap and points): the costs line, its needs
    to match "X only", and no hand ap/cost lines beside a profile."""
    p = "Skills/%s.tres" % sid
    os.path.exists(os.path.join(ROOT, p)) or die("no %s" % p)
    whole = read(p)
    at = re.search(r"^\[resource\]$", whole, re.M) or die("%s: no [resource]" % p)
    head, body = whole[:at.end()], whole[at.end():]
    secs = sections(whole)
    res = next(x for x in secs if x["kind"] == "resource")
    res["props"].get("passive") != "true" or res["props"].get("hybrid") == "true" or die("%s is a passive: it costs nothing" % sid)
    body = re.sub(r"^(costs|priced|cost_per_rank|ap|cost) = .*\n", "", body, flags=re.M)
    if text == "hand":
        ap is not None and points is not None or die("hand: give --ap and --points")
        body = body.rstrip("\n") + "\nap = %s\ncost = %d\n" % (literal("ap", str(ap)), int(points))
    else:
        try:
            prof = profile(text)
        except ValueError as e:
            die("cost profile %s" % e)
        had = REF.search(res["props"].get("needs", ""))
        had_path = ext_ids(secs).get(had.group(2)) if had else None
        want = "res://Reserves/%s.tres" % prof["reserve"] if prof["only"] else None
        if had_path and had_path != want:
            die('%s needs %s: say "%s only" in the profile, or remove its needs line first' % (sid, had_path, os.path.basename(had_path)[:-5].replace("_", " ")))
        if want and not had_path:
            rid = ext_id_for(secs, want) or free_id(secs, "needs")
            if not ext_id_for(secs, want):
                head = add_ext(head, '[ext_resource type="Resource" path="%s" id="%s"]' % (want, rid))
            body = body.rstrip("\n") + '\nneeds = ExtResource("%s")\n' % rid
        body = body.rstrip("\n") + '\ncosts = "%s"\n' % text
    write(p, head + body, dry)


def set_trait(a):
    """Add (or with --off, take off) the trait tag on skill a.id: the one declaration of what always works with no slot."""
    p = "Skills/%s.tres" % a.id
    os.path.exists(os.path.join(ROOT, p)) or die("no %s" % p)
    text = read(p)
    res = next(x for x in sections(text) if x["kind"] == "resource")["props"]
    m = re.search(r"^tags = Array\[StringName\]\(\[(.*)\]\)$", text, re.M) or die("%s: no tags line to edit" % p)
    tags = re.findall(r'&"(\w+)"', m.group(1))
    if a.off:
        tags = [t for t in tags if t != "trait"]
    else:
        res.get("passive") == "true" or die("%s is not a passive: a trait is always on, with nothing to cast" % a.id)
        any(res.get(k) == "true" for k in ("toggle", "hybrid")) and die("%s is a toggle or hybrid: a trait can't be switched or used" % a.id)
        tags = tags if "trait" in tags else tags + ["trait"]
    write(p, text[:m.start()] + "tags = Array[StringName]([%s])" % ", ".join('&"%s"' % t for t in tags) + text[m.end():], a.dry_run)
    print("%s: %s" % (a.id, "no longer a trait: slotted again" if a.off else "a trait: always on, no hotbar slot (give it to a unit: python3 Util/unit.py trait <unit> %s)" % a.id))
    return 0 if a.dry_run else check()


def cost(a):
    set_cost(a.id, a.profile, a.ap, a.points, a.dry_run)
    if not a.dry_run:
        report("terms", a.id)
    return 0


def migrate(a):
    """Hand prices a profile reproduces exactly at every rank (Util/terms.gd infer) -> that profile."""
    r = subprocess.run(["godot", "--headless", "--path", ROOT, "-s", "Util/terms.gd", "--", "infer"], capture_output=True, text=True)
    kept = []
    for line in r.stdout.split("\n"):
        if "\t" not in line:
            continue
        sid, text = line.split("\t")
        if text == "-":
            kept.append(sid)
        else:
            set_cost(sid, text, dry=a.dry_run)
    print("kept hand-priced (no profile reproduces them at every rank): %s" % ", ".join(kept))
    return 0


def report(mode, *args):  # Util/terms.gd, headless: reads the skills as the game does
    r = subprocess.run(["godot", "--headless", "--path", ROOT, "-s", "Util/terms.gd", "--", mode] + list(args), capture_output=True, text=True)
    out = [l for l in r.stdout.split("\n") if l.strip() and not l.startswith("Godot Engine")]
    print("\n".join(out))
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    n = sub.add_parser("new", help="write a skill and wire it in")
    n.add_argument("id", help="file name: kick -> Skills/kick.tres")
    n.add_argument("--title", help="shown name (default: from the id)")
    n.add_argument("--human", action="store_true", help="a person named and designed it: no ai = true (no ?? on its name)")
    n.add_argument("--glyph", help="up to 2 characters for its placeholder icon (default: its initials)")
    n.add_argument("--tags", help="comma separated: physical,blunt,str,martial")
    n.add_argument("--passive", action="store_true")
    n.add_argument("--trait", action="store_true", help="a trait: an always-on passive (implies --passive, adds the trait tag) that takes no hotbar slot and sits at the hotbar's far right; may go on no tree (a unit's innate: unit.py trait)")
    n.add_argument("--ap", help="a hand price, with --hand-priced (default: the cost calculator's)")
    n.add_argument("--cost", help='its cost profile: "high mana, low ap", "very high ap, no cost, flat rank" (default "even"); with --hand-priced, the Energy cost')
    n.add_argument("--hand-priced", action="store_true", help="keep --ap/--cost (a number) rather than the cost calculator's price")
    n.add_argument("--intensity", help="its damage: low, moderate_low, moderate, high, extreme (writes its rank I tier unless --tier)")
    n.add_argument("--stat", help="with --intensity: the stat whose mod its damage adds (strength...)")
    n.add_argument("--impact", help="its unique effect beyond damage: tame or impactful (default: from its fields)")
    n.add_argument("--penalty", help="what it costs its user: minor, major, severe (default: from its fields)")
    n.add_argument("--requires", help='a contingency: "test=energy_above share=0.2 hit=2" (Scripts/Requirement.gd)')
    n.add_argument("--check", help='its check in place of the attack roll: "against=wisdom save=true ranked=true" (Scripts/SkillCheck.gd: stat, against, save, ranked, edge, range_penalty, tags, drags_to, suspicion)')
    n.add_argument("--radius", help="range before rank")
    n.add_argument("--range-per-rank", dest="radius_per_rank")
    n.add_argument("--tier", action="append", default=[], help="damage by rank: 1:1d4+strength, 3:2+1d6+direct")
    n.add_argument("--effect", action="append", default=[], help='"stat=luck amount=-1 per_rank=true name=Hexed"')
    n.add_argument("--behaviour", action="append", default=[], help="Behaviours/<name>.gd, stubbed if missing")
    n.add_argument("--test", action="store_true", help="stub Tests/<id>_test.gd though it has no behaviour of its own (a new behaviour always gets one)")
    n.add_argument("--set", action="append", default=[], help="any other Skill field: key=value (a .tres literal)")
    n.add_argument("--tree", help="Trees/<x>.tres or Roles/<x>.tres it goes on")
    n.add_argument("--after", help="the skill whose branch it goes beside (and whose root)")
    n.add_argument("--root", help="or: the root (by name) it goes at the end of")
    n.add_argument("--prereq", help="skills to learn first, comma separated (Branch.after)")
    n.add_argument("--needs", type=int, help="a capstone: how many of its root's other skills it needs (Branch.needs)")
    n.add_argument("--branch-tier", type=int, help="its tier on a general tree (Branch.tier)")
    n.add_argument("--role", help="Roles/<x>.tres it's offered by outright (Role.options)")
    n.add_argument("--lent", action="store_true", help="on no tree or role: an item lends it (Util/item.py new --skill), so nobody learns it")
    n.add_argument("--no-import", action="store_true")
    n.add_argument("--dry-run", action="store_true", help="print what it would write")
    tr = sub.add_parser("trait", help="declare an existing passive a trait (always on, no hotbar slot), or --off")
    tr.add_argument("id")
    tr.add_argument("--off", action="store_true", help="take the declaration off: it is slotted again")
    tr.add_argument("--dry-run", action="store_true")
    sub.add_parser("check", help="catch the wiring pitfalls")
    sub.add_parser("drift", help="hand-set prices against the cost calculator's (information)")
    sub.add_parser("modifiers", help="skills no modifier fits, and why (information)")
    t = sub.add_parser("terms", help="one skill's terms")
    t.add_argument("id")
    c = sub.add_parser("cost", help='set a skill\'s cost profile: cost kick "high ap, low cost" (or: cost kick hand --ap 4 --points 1)')
    c.add_argument("id")
    c.add_argument("profile", help='"high mana, low ap", "mana only", "very high ap, no cost, flat rank", "even"; or hand')
    c.add_argument("--ap", type=float, help="with hand: its AP")
    c.add_argument("--points", type=int, help="with hand: its Energy cost")
    c.add_argument("--dry-run", action="store_true")
    mg = sub.add_parser("migrate", help="hand prices a profile reproduces exactly at every rank -> that profile")
    mg.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    if a.cmd == "trait":
        sys.exit(set_trait(a))
    if a.cmd == "cost":
        sys.exit(cost(a))
    if a.cmd == "migrate":
        sys.exit(migrate(a))
    if a.cmd in ("drift", "modifiers"):
        sys.exit(report(a.cmd))
    if a.cmd == "terms":
        sys.exit(report("terms", a.id))
    sys.exit(new(a) if a.cmd == "new" else check(a))


if __name__ == "__main__":
    main()
