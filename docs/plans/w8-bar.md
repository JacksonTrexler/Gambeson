# Free lends and the band (w8-bar, ?214, 2026-11-20)

The user (answers-2026-11-20c): "armor passives are similar to innate passives: they both should be grayed out and not take a
numbered hotbar slot unless activatable. The skills provided by innates / equipment *may* be considered "equippable" but are free
and auto-equipped by default while eligible for the innate / equipping the related item (e.g. if a robe provides "Igna B" as an
optional slot in skill, some units will elect not to slot it, whereas a harpy hauberk might provide a toggle skill Hollow Bones:
double dex ap generation and gain flight, halve defense.)"
Baseline suite: 10547 checks, 0 failed (993 tests).

## Readings and calls

1. **A lend is free by default** (`Item.link()` -> `&"free"`): no hotbar slot, equipped while worn, for any kind of skill (the
   w6-link rule "innate means nothing on an active or toggle" is gone). **`optional` is the link that "says so"**: the skill takes
   its slots (`slots_taken()`) and isn't put on the bar by itself; the wearer slots it or not (the user's "Igna B ... optional slot
   in skill"). Call: "optional slot-in" read as costing a slot (that's why a unit would elect not to); there is no longer a link
   that costs a slot *and* auto-equips (the old plain lend). Two items lending one skill: free beats optional.
2. **`Item.innate` removed** (it equalled the new default): dropped from the nine armors, `item.py` (`--skill x:innate`,
   `lend --as innate` gone; `check` fails a leftover `innate` list, an `optional` equipment skill or trait). No Skill.gd field.
3. **Existing plain lends become free** (call, the user's "free by default"): Broadsword's Strike, Hobnail Boots' Kick, the Coyote
   Scepter's and Charm's skills now sit in the band, usable, instead of a slot. To keep one costing a slot:
   `item.py lend <skill> --ids <item> --as optional`. A skill learned as well as lent is still its own and takes its slot
   (w6-link 4c kept); so fighters' own Strike is unchanged.
4. **"Innates" read as the unit's traits** (already free). Skills a role or species gives (`Unit.innate`, `_role_slots`: a
   villager's Strike) still take slots: making those free would empty most bars. Question for the user.
5. **Optional and setting up** (call, "some units will elect not to slot it"): a unit setting up (`_fill_bar()`, NPCs and a fresh
   bar) slots an optional lend last, into a slot left over; one with a full bar doesn't. Auto-equip and auto-fill leave it (the
   player elects), and a saved bar keeps whatever the player chose.
6. **The band** (`HUD.band()`, the trait row after the hotbar): `Unit.traits()` now lists every slotless skill (traits and free
   lends; Armor itself still unlisted, as before). Activatable ones (anything not `SkillSlot.muted()`) come first and take the
   number keys after the bar's (bar 1-5 -> band 6, 7...), and are used by key or click exactly as a hotbar slot
   (`use_slot(hotbar.size() + k)`): arm, aim, toggle (dot and dim when off), primary attack for a click on a foe, tooltip
   "[6] ...". Always-on passives follow, unkeyed (diamond), tooltip "Trait" or "Free", with the item's ring ("Lent by ...").
   Keys exist only up to hotbar_10, as for the bar itself.
7. **Orders** (call): an ally's band is open to the leader's orders as its first slot is (`Command.slot_open`, `may_use`).
8. **Disabling and suppression unchanged for slotless skills**: a free lend, like a trait, can't be disabled and stops while
   traits are suppressed (w6-link's call for innate passives, now for free actives too).
9. **Sigil** reaches the band: the leftmost eligible skill on the hotbar, then past it (a free lent skill can carry it).
10. **Hollow Bones** (`--human`, lent only, `Skills/hollow_bones.tres`, data only): a toggle passive, on as it comes; `dex_ap` +1
    (the dex pool's dex mod twice over: "double dex AP generation"), `defense` mul 0.5, tag `flight`. `no_density`: nothing scales.
    Tags `flight, dex` (call: not `defensive`).
11. **Flight** was missing (Druid's `floating` waits, unbuilt): the user's word, so the tag `flight` (`--human`, kind condition as
    `aquatic`, Glossary "Aloft: every step costs it 1 movement whatever the ground below, and deep water neither slows nor drowns
    it"). Read in `Battle._cost()` (1 + its own move_cost stat per step, ground ignored) and `submerged()` (not under deep water;
    one held under by a grappler on its tile still is). Not done: flying over walls or units, ground traps/marks skipping a flyer,
    the AI weighing flight, height. Calls: what flight means is a question.
12. **A toggle's tags count only while it's on** (`Unit.has_tag()`, was: while equipped): otherwise a switched-off Hollow Bones
    still flew. Applies to every toggle (Sweet Nothings, Discipline, Brood, Mana...); no test or rule relied on the old reading.
13. **Halving Defense** needed a mul to reach armor: `Unit.stat()` takes a `base`, and `defense()` passes its armor's (and armor
    mind, spent hearts) through it, so any `defense` mul scales the whole of it. Adds still add; rounding is now of the total.
14. **Harpy Hauberk** (`--human`, `Items/harpy_hauberk.tres`): rare medium mail armor, lends Armor and Hollow Bones (both free).
    No loot table (call: adding a drop shifts every seeded drop); `item.py` drew the icon.
15. The AI never switches Hollow Bones (it switches only mist and reserve toggles): an NPC wearing it flies at half Defense always.

## As built

- `Scripts/Item.gd` (`innate` gone, `link()`), `Scripts/Unit.gd` (`link`, `slot_cost`, `traits`, `_fill_bar`, `armor_skills`,
  `has_tag`, `stat(base)`, `defense`), `Scripts/Command.gd` (`slot_open`, `may_use`), `Scripts/HUD.gd` (`band`, `_skill_in`,
  `_works`, `_slot_key`, `use_slot`, `_primary`, `_slot_usable`, `armed`, `_refresh_traits`, `_use_band`), `Scripts/Battle.gd`
  (`_cost`, `submerged`), `Scripts/Modifiers.gd` (Sigil), `Scripts/SkillEntry.gd`, `Scripts/Skill.gd` (comments), `Scripts/Guide.gd`,
  Glossary/Tags (`flight`), nine armor `.tres`, `Skills/hollow_bones.tres`, `Items/harpy_hauberk.tres`, icons, `Util/item.py`,
  `Util/skill.py` (docstrings).
- **SkillSlot changes (minimal):** `keyed()` (a band slot whose skill isn't muted shows its number instead of the diamond);
  `_tag()` says "Free" for a slotless non-trait. No drawing beyond the diamond/number switch.
- Tests: `equip_test.test_hauberk` (rules: free toggle, dex pool, whole Defense halved, flight cost and flood, off undoes all, gone
  with the item) and `test_band` (HUD: order, keys after the bar, tooltip leads, no drag, key switches, click arms Kick and kicks,
  ally orders). Updated to the new model: `lent_test.test_links` (rewritten: free/optional/free beats optional/setup slots
  optional), `lent_test` lender and Armor checks, `lent_test.test_lent_prerequisites` (gift lent optional so a disabling reaches
  it), `item_skills_test` (Kick in the band; Sigil over band then bar), `equip_test.test_multi_slot` (free vs optional), `test.gd`
  `bulwark()`. Sweep: every toggle switched off is inert with its tags gone; every lend free or for a slot by its link.
- Mutation spot-checks (each failed, reverted): slot_cost ignoring free (10 fail), band keys stop at the bar (4), has_tag ignoring
  on (1 here; 12 in the sweep), Defense mul on adds only (1), flyer submerged (1), band closed to orders (1), setup skipping optional
  (1), Sigil skipping the band (1).
- Screenshots: `S/shot_w8-bar/01_band.png` (6 Hollow Bones on, 7 Kick, Darkvision unkeyed; DF 5), `02_bones_off_kick_armed.png`
  (Hollow Bones off and dim, Kick armed, DF 10). Seen: the band wraps into three columns in one row at 16:9 (w7-wide's fit) and
  cuts names ("Hollo", "Darkvi"); left as is.
