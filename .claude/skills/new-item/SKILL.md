---
name: new-item
description: Add an item to Gambeson - writes Items/<id>.tres (slot, rarity, rank, tags, enchanted or honed, lent skills, effects, an emblem) and its placeholder icon, optionally puts it in a loot table, and checks every item. Use for any new weapon, armor, trinket, consumable or emblem.
---

# Adding an item

1. **Pin down the design.** What it is in a line, then its fields (`Scripts/Item.gd`, each field's comment
   says what reads it):
   - **slot** - `armor`, `weapon`, `trinket` (one slot: emblems, rings, Heart Up compete for it) or
     `consumable` (used up: potions, a Heart).
   - **rarity** - how often it drops and what a rank costs (`Item.RARITY_WEIGHT`, `Item.RANK_COST`): common
     1, uncommon 1.5, rare 2, epic 3, legendary 4, mythic 5. **rank** - what its effects scale by.
   - **tags** - what it is. Each needs a colour; a new word is `mechanic.py tag` first (new-mechanic). The
     first coloured, non-plain tag trims it (`Item.trim()`). Prefer a tag the rules already read over a new
     field: a skill that asks for `&"fire"` then meets a fire item too.
   - **enchanted** or **honed** (never both) - rank +1 each; only `enchanted` is what Pray and Smite act on.
   - **lent skills** (`--skill`) - granted while worn, ranked by the item, never bought or raised
     (docs/plans/item-skills.md). The skill exists first (new-skill).
   - **an emblem** - a modifier on its wearer's skills: `--emblem` a symbol (`rho_up`, `sigma_down`,
     `lambda_up`...) or a coloured tag (`fire`, `execute`), `--scope` sigil (leftmost fitting skill),
     insignia (every skill), crest (actives) or badge (passives). The scope goes on as a tag.
   - **effects** on its wearer (`--effect "stat=max_hp per_mod=strength"`), and any other field with
     `--set key=value` (`heat=1`, `revives=0.5`, `restores=hp`). Something no field or Effect stat says is
     a rule: an Effect stat or tag (new-mechanic) or a skill's behaviour (new-skill), never a one-off
     `Item.gd` flag.
   Named by the user: `--human`; else it gets `??`.

2. **Write it:**
   ```
   python3 Util/item.py new hobnail_boots --name "Hobnail Boots" --slot trinket --rarity uncommon \
       --skill kick [--tags ...] [--enchanted | --honed] [--emblem ... --scope ...] [--effect "..."] \
       [--set key=value] [--loot alabaster:1] [--human] [--dry-run]
   ```
   It writes `Items/<id>.tres`, draws `Icons/Items/<id>.png` (`icon.py item <id>`: a placeholder by slot,
   kind and trim; art replaces the file), adds it to `Loot/<table>.tres` at the weight given, imports and
   checks. To redraw after changing its tags or slot: `python3 Util/icon.py item <id>`.

2b. **Lending a skill.** An item lends a skill the holder doesn't own: `python3 Util/item.py lend <skill> [--slot S] [--ids a,b]` puts it on items; a skill meant only to be lent is written with `python3 Util/skill.py new <id> --lent` (on no tree or role). `check` holds the wiring.

3. **Where it turns up.** A drop: `--loot <table>` (a unit's `loot`, `Loot.gd`: weight x rarity pull;
   what falls goes to `Battle.spoils`). A class's starting kit: `Role.items` (new-class).

4. **Test only a new rule.** An item made of existing fields and tags needs no test of its own: the
   rules' tests cover the fields and `item.py check` covers the wiring. A new rule it brings (a tag the
   rules newly read, an Effect stat) gets one test where that rule lives.

5. **Check, then run:** `python3 Util/item.py check` (icons, fields, slot, rarity, tags known and coloured,
   enchanted/honed, emblems, lent skills, loot tables; `skill.py check` runs it too),
   `python3 Util/skill.py check`, the tests.

6. **Record the calls you made** that the user didn't, for review (CLAUDE.md): every name you made up
   (with its ??), and each choice, in the todo docs as the other processes say (new-unit step 6).
