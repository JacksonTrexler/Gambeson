#!/usr/bin/env python3
"""Gambeson item authoring: an item (Items/<id>.tres) with its placeholder icon, optionally in a loot table.

  python3 Util/item.py new hobnail_boots --name "Hobnail Boots" --slot trinket [--human] [--rarity uncommon] \\
      [--rank 1] [--tags gem,fire] [--enchanted | --honed] [--skill kick] [--effect "stat=max_hp per_mod=strength"] \\
      [--emblem rho_up --scope sigil] [--damage-tag slash] [--set heat=1] [--loot alabaster[:weight]] [--dry-run]
  python3 Util/item.py check

slot: armor, weapon, trinket or consumable (Item.slot). rarity: how often it drops and what a rank costs
  (Item.RARITY_WEIGHT, Item.RANK_COST). --enchanted / --honed: the quality tags (rank +1, never both).
--skill: a skill lent while it's worn (Item.skills: on loan, ranked by the item; docs/plans/item-skills.md).
--emblem: a modifier symbol (Modifiers.SYMBOLS: rho_up...) or a coloured tag (fire, execute), with --scope
  sigil, insignia, crest or badge (Modifiers.SCOPES); the scope goes on as a tag too, as on every emblem.
--effect: an Effect on its wearer (tres.effect_props: "stat=... amount=... per_rank=true").
--set: any other Item field, key=value (Item.gd's @export vars: heat=1, revives=0.5, restores=hp).
--loot: adds it to Loot/<table>.tres with this weight (default 1).
An AI-made name gets " ??" (CLAUDE.md); a name the user gave goes in with --human. The icon is drawn by
icon.py item <id> off the .tres (shape by slot and kind, trim by tag). .claude/skills/new-item has the process.
"""
import argparse, os, re, sys

from tres import Doc, ROOT, ai_name, die, exists, files, import_project, literal, names, read, sections, typed, write, add_ext, free_id
import tres
import icon

ITEM, SKILL, EFFECT = "res://Scripts/Item.gd", "res://Scripts/Skill.gd", "res://Scripts/Effect.gd"
QUALITIES = ("enchanted", "honed")  # Tags.QUALITIES: rank +1 each, never both


def enum(field):
    """The choices of an @export_enum field in Item.gd: slot, rarity."""
    m = re.search(r'@export_enum\(([^)]*)\) var %s\b' % field, read("Scripts/Item.gd")) or die("Item.gd: no enum %s" % field)
    return re.findall(r'"(\w+)"', m.group(1))


def fields():
    """Item.gd's @export vars: what an Items/*.tres may set."""
    return set(re.findall(r"^@export(?:_\w+)?(?:\([^)]*\))? var (\w+)", read("Scripts/Item.gd"), re.M))


def symbols():
    return re.findall(r'&"(\w+)": \[', re.search(r"const SYMBOLS := \{(.*?)\n\}", read("Scripts/Modifiers.gd"), re.S).group(1))


def scopes():
    return re.findall(r'&"(\w+)": &"\w+"', re.search(r"const SCOPES := \{(.*?)\}", read("Scripts/Modifiers.gd")).group(1))


def coloured():
    """Tags.coloured() as a test: its own colour or its parent's."""
    cols, parent, _ = icon.tag_table()
    return lambda t: t in cols or parent.get(t) in cols


def known():
    """Words the rules can ask about: any &"tag" in Scripts/ or Behaviours/ (the Glossary, Tags.PLAIN and the
    rules that read them all live there)."""
    out = set()
    for p in list(files("Scripts", ".gd")) + list(files("Behaviours", ".gd")):
        out.update(re.findall(r'&"(\w+)"', read(p)))
    return out


def item_tres(a):
    slots = enum("slot")
    a.slot in slots or die("--slot: one of %s" % ", ".join(slots))
    a.rarity in enum("rarity") or die("--rarity: one of %s" % ", ".join(enum("rarity")))
    tags = [t.strip() for t in (a.tags or "").split(",") if t.strip()]
    if a.enchanted or a.honed:
        q = "enchanted" if a.enchanted else "honed"
        q in tags or tags.append(q)
    all(q in tags for q in QUALITIES) and die("enchanted and honed exclude each other: pick one")
    if a.emblem or a.scope:
        a.emblem and a.scope or die("an emblem needs both --emblem and --scope")
        a.scope in scopes() or die("--scope: one of %s" % ", ".join(scopes()))
        a.emblem in symbols() or coloured()(a.emblem) or die("--emblem: a symbol (%s) or a coloured tag (mechanic.py tag ... --color)" % ", ".join(symbols()))
        a.scope in tags or tags.append(a.scope)
    ok = coloured()
    for t in tags:
        re.fullmatch(r"[a-z][a-z0-9_]*", t) or die("a tag is lower_snake: %r" % t)
        ok(t) or die('tag "%s" has no colour - make it first (python3 Util/mechanic.py tag %s ... / color %s "#rrggbb")' % (t, t, t))
    d = Doc('[gd_resource type="Resource" script_class="Item" format=3]')
    p = ["script = " + d.res("Script", ITEM), 'name = "%s"' % ai_name(a.name or a.id.replace("_", " ").title(), a.human).replace('"', '\\"'),
         'slot = "%s"' % a.slot]
    if tags:
        p.append("tags = " + names(",".join(tags)))
    if a.rank != 1:
        p.append("rank = %d" % a.rank)
    if a.rarity != "common":
        p.append('rarity = "%s"' % a.rarity)
    if a.damage_tag:
        a.damage_tag in ("slash", "pierce", "blunt") or die("--damage-tag: slash, pierce or blunt")
        p.append('damage_tag = &"%s"' % a.damage_tag)
    if a.skill:
        refs = []
        for sid in a.skill:
            exists("Skills/%s.tres" % sid) or die("--skill %s: no Skills/%s.tres (python3 Util/skill.py new ...)" % (sid, sid))
            refs.append(d.res("Resource", "res://Skills/%s.tres" % sid))
        p.append("skills = " + typed(SKILL, d, refs))
    if a.effect:
        refs = [d.effect("Effect_%d" % (i + 1), s, a.human) for i, s in enumerate(a.effect)]
        p.append("effects = " + typed(EFFECT, d, refs))
    if a.emblem:
        p += ['emblem = &"%s"' % a.emblem, 'scope = &"%s"' % a.scope]
    known_fields = fields()
    for kv in a.set:
        k, _, v = kv.partition("=")
        k in known_fields or die("--set %s: Item.gd has no such field" % k)
        p.append("%s = %s" % (k, literal(k, v)))
    d.props = p
    return d.text()


def add_to_loot(a, dry):
    table, _, w = a.loot.partition(":")
    path = "Loot/%s.tres" % table
    exists(path) or die("--loot %s: no %s" % (table, path))
    text = read(path)
    secs = sections(text)
    res = next(s for s in secs if s["kind"] == "resource")
    ids = tres.items(res["props"].get("items", ""))
    weights = re.findall(r"-?\d+(?:\.\d+)?", re.sub(r"^Array\[float\]", "", res["props"].get("weights", "")))
    weights += ["1.0"] * (len(ids) - len(weights))  # missing weights weigh 1 (Loot.weight())
    xid = free_id(secs, "%d_%s" % (sum(s["kind"] == "ext_resource" for s in secs) + 1, a.id))
    text = add_ext(text, '[ext_resource type="Resource" path="res://Items/%s.tres" id="%s"]' % (a.id, xid))
    m = re.search(r'^items = Array\[(ExtResource\("[^"]+"\))\]\(\[(.*)\]\)$', text, re.M) or die("%s: no items = Array[...]([...]) line" % path)
    refs = ", ".join(['ExtResource("%s")' % i for i in ids] + ['ExtResource("%s")' % xid])
    text = text[:m.start()] + "items = Array[%s]([%s])" % (m.group(1), refs) + text[m.end():]
    line = "weights = Array[float]([%s])" % ", ".join(literal("amount", x) for x in weights + [w or "1"])
    text = re.sub(r"^weights = .*$", line, text, flags=re.M) if re.search(r"^weights = ", text, re.M) else text.rstrip("\n") + "\n" + line + "\n"
    write(path, text, dry)


def new(a):
    re.fullmatch(r"[a-z][a-z0-9_]*", a.id) or die("the id is a file name: lower_snake (hobnail_boots)")
    exists("Items/%s.tres" % a.id) and die("Items/%s.tres exists" % a.id)
    write("Items/%s.tres" % a.id, item_tres(a), a.dry_run)
    if a.loot:
        add_to_loot(a, a.dry_run)
    if a.dry_run:
        print("(dry run: no icon drawn)")
        return 0
    icon.item_icon(a.id)  # a placeholder off the .tres: replace the PNG with art any time
    import_project()
    print("\nnext: what it does beyond its fields is a rule somewhere (a tag the rules read, an Effect stat: "
          "mechanic.py); then `python3 Util/item.py check`, `python3 Util/skill.py check` and the tests (.claude/skills/new-item)")
    return check()


def problems():
    """Everything wrong with Items/ and Loot/: the item rules no other tool owns (icons come from icon.py)."""
    out = list(icon.check_items())
    slots, rarities, have, syms, scs = enum("slot"), enum("rarity"), fields(), symbols(), scopes()
    ok, words = coloured(), known()
    for p in sorted(files("Items", ".tres")):
        text = read(p)
        res = next((s for s in sections(text) if s["kind"] == "resource"), None)
        if not res or 'path="%s"' % ITEM not in text:
            out.append("%s: not an Item resource" % p)
            continue
        pr = {k: v.strip().strip("&").strip('"') for k, v in res["props"].items()}
        for k in res["props"]:
            if k not in have and k not in ("script", "metadata/_custom_type_script"):
                out.append('%s: "%s" isn\'t an Item.gd field (renamed?)' % (p, k))
        if pr.get("slot", "armor") not in slots:
            out.append('%s: slot "%s" isn\'t one of %s' % (p, pr["slot"], ", ".join(slots)))
        if pr.get("rarity", "common") not in rarities:
            out.append('%s: rarity "%s" isn\'t one of %s' % (p, pr["rarity"], ", ".join(rarities)))
        tags = re.findall(r'&"(\w+)"', res["props"].get("tags", ""))
        for t in tags:
            if t not in words:
                out.append('%s: tag "%s" is nowhere in Scripts/ (a typo? python3 Util/mechanic.py tag %s ...)' % (p, t, t))
            elif not ok(t):
                out.append('%s: tag "%s" has no colour (python3 Util/mechanic.py color %s "#rrggbb")' % (p, t, t))
        if all(q in tags for q in QUALITIES):
            out.append("%s: enchanted and honed together - pick one (they exclude each other)" % p)
        em, sc = pr.get("emblem", ""), pr.get("scope", "")
        if bool(em) != bool(sc):
            out.append("%s: an emblem needs both emblem and scope" % p)
        if em and em not in syms and not ok(em):
            out.append('%s: emblem "%s" is neither a symbol (%s) nor a coloured tag' % (p, em, ", ".join(syms)))
        if sc and sc not in scs:
            out.append('%s: scope "%s" isn\'t one of %s' % (p, sc, ", ".join(scs)))
        ext = tres.ext_ids(sections(text))
        for i in tres.items(res["props"].get("skills", "")):
            if not (ext.get(i) or "").startswith("res://Skills/"):
                out.append("%s: a lent skill (%s) isn't a Skills/ file" % (p, ext.get(i) or i))
        for path in ext.values():
            if path and not exists(path[len("res://"):]):
                out.append("%s: %s is missing" % (p, path))
    for p in sorted(files("Loot", ".tres")):
        text = read(p)
        secs = sections(text)
        ext = tres.ext_ids(secs)
        res = next((s for s in secs if s["kind"] == "resource"), {"props": {}})
        ids = tres.items(res["props"].get("items", ""))
        for i in ids:
            path = ext.get(i) or ""
            if not path.startswith("res://Items/") or not exists(path[len("res://"):]):
                out.append("%s: %s isn't an item in Items/" % (p, path or i))
        if not ids:
            out.append("%s: drops nothing (no items)" % p)
        n = len(re.findall(r"-?\d+(?:\.\d+)?", re.sub(r"^Array\[float\]", "", res["props"].get("weights", ""))))
        if n > len(ids):
            out.append("%s: %d weights for %d items" % (p, n, len(ids)))
    for top in ("Scripts", "Scenes", "Roles", "Races"):  # every res://Items/ path anything names is a file
        for f in sorted(list(files(top, ".gd")) + list(files(top, ".tres")) + list(files(top, ".tscn"))):
            for m in set(re.findall(r'res://(Items/\w+\.tres)', read(f))):
                if not exists(m):
                    out.append("%s: %s is missing" % (f, m))
    return out


def check(_a=None):
    ps = problems()
    for p in ps:
        print(p)
    print("item.py check: %s" % ("%d problem(s)" % len(ps) if ps else "ok"))
    return 1 if ps else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    n = sub.add_parser("new", help="an item: Items/<id>.tres and its icon, optionally in a loot table")
    n.add_argument("id", help="file name: hobnail_boots -> Items/hobnail_boots.tres")
    n.add_argument("--name", help="shown name (default: from the id; gets ?? unless --human)")
    n.add_argument("--human", action="store_true", help="a person named it: no ??")
    n.add_argument("--slot", required=True, help="armor, weapon, trinket or consumable")
    n.add_argument("--rarity", default="common", help="common, uncommon, rare, epic, legendary, mythic")
    n.add_argument("--rank", type=int, default=1)
    n.add_argument("--tags", help="comma separated; each needs a colour (mechanic.py)")
    q = n.add_mutually_exclusive_group()
    q.add_argument("--enchanted", action="store_true", help="the enchanted tag: rank +1, what Pray and Smite act on")
    q.add_argument("--honed", action="store_true", help="the honed tag: rank +1, nothing else")
    n.add_argument("--skill", action="append", default=[], help="a skill it lends while worn: Skills/<id>.tres")
    n.add_argument("--effect", action="append", default=[], help='an Effect on its wearer: "stat=max_hp per_mod=strength"')
    n.add_argument("--emblem", help="a modifier symbol (rho_up...) or a coloured tag (fire)")
    n.add_argument("--scope", help="sigil, insignia, crest or badge")
    n.add_argument("--damage-tag", help="a weapon's blows: slash, pierce, blunt")
    n.add_argument("--set", action="append", default=[], help="any other Item field: key=value")
    n.add_argument("--loot", help="Loot/<table>.tres to add it to: table[:weight]")
    n.add_argument("--dry-run", action="store_true")
    sub.add_parser("check", help="every item and loot table sound")
    a = ap.parse_args()
    sys.exit({"new": new, "check": check}[a.cmd](a))


if __name__ == "__main__":
    main()
