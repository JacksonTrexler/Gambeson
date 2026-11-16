# Equipping skills (x-equip, 2026-11-15)

Plan.md Phase 4 item 12; systems.md "Equipping skills"; classes.md "If a skill that grants slots is
unequipped, its slots disappear". ?3 (the Adventurer's centre slot) kept as built, as answered.
Baseline suite: 8070 checks, 0 failed (838 tests).

## Readings and calls

1. **One query.** `Unit.equipped(s)`: inherent skills (Starkind, Reckless Abandon: "takes no slot") always;
   anything else only while on the hotbar, in a slot a level curse hasn't sealed. `on_passives` (so `passives`,
   `hooks()`, `_gather_effects`/`stat()`, `granted_slots()`, `runs_on()`, `opened()`, Downed, `Battle.reactions_of`)
   and `actives` (so `kit`, the AI) both filter through it. Direct `slots` readers of what a passive does were
   moved onto it: `efficiency()` (Behaviour.affinity), `dissonance_penalty()`, `candid()`, `has_tag()` (a passive's
   tags only while equipped; an active's always: what it knows), `pools()`, `spends()`, `giver_rank()`,
   `_opener()`/`lapsed()` (a waiver unequipped lapses what it waived), `_take_looks()`, `AI` vapor and switch
   toggles, Sigil's leftmost-eligible (`Modifiers._reaches`). Learning-side readers (`missing`, `magic_learned`,
   Illusionist's count, rank/raise) still read every learned skill. Call: **actives too** need equipping (the
   hotbar is the equipped set); before, the AI could use any active it had.
2. **What goes on the bar.** `Skill.fits_bar()` is now "not inherent": always-on passives go on the bar. Call:
   **always-on passives can't sit in the clover slot** (it comes and goes with luck and is filled on the unit's
   own turn); toggles still can.
3. **Default bar** (`_fill_bar`, every unit, not a setting): pillars in the last sure slots, actives and toggles
   from the left, always-on passives from the right; actives win a shortage. Call: **NPCs carry extra_slots
   for the rest**: `Util/unit.py check` now flags a unit scene whose learned skills (less inherent ones)
   outnumber 4 + level / 4 + extra_slots, and `unit.py new` sets extra_slots itself. Siren `extra_slots = 2`,
   Undine `1` (Tonefoolery, Alluring and Well Up would have been inert).
4. **Auto-equip** (`Unit.auto_equip`, static; the Settings toggle "Auto-equip new skills", on by default, saved
   as Prefs `auto_equip`). A skill the unit hasn't had before (learned, unlocked, lent by an item) goes where
   it would by default, if there's room; slots that appear (a level, a granting skill) fill with learned skills
   left off. A full bar leaves a new skill off (no displacing). A slot emptied by hand is never refilled.
   Detection is lazy (`_sync_new()`, on a cheap signature of the skill entries), so a skill appended to
   `learned` (tests, scripts) is caught on the next read. Calls: **the toggle is global**, NPCs included
   (their bars are set at setup regardless); **passives auto-fill sure slots first**, typed granted slots only
   after, so one granting skill rarely ends up in another's slot.
5. **Losing slots.** Granted slots are keyed by their source (`_grants()`: [type, skill], items pooled as
   `item` since an enchantment swaps the copy). Unequipping a granting skill (`bar_clear`, `bar_place` moving
   it, `set_equipped`) re-sorts the bar (`_arrange()`, repeated till stable): its slots go, skills and all,
   cascading if one of them was itself a granting skill. Skills that come off are announced on
   `Unit.lost_skills` (Battle ends a channel on one), as item-lent ones already were.
6. **Growing the bar.** New sure slots go in above the passives and pillars at the bottom (they stay at the
   bottom); a clover slot turning plain keeps its skill. Call.
7. **Pillars** still can't be moved or unequipped; one off the bar may go into an empty sure slot.
8. **Brainfog's order** (`disable_order`): pillars, then the hotbar right to left. Unequipped skills don't work,
   so aren't reached (before: all always-on passives, then the bar, then every other active).
9. **Skills screen.** Drag a skill the unit has from the wheel or grid onto the hotbar (`SkillSlot.drag_learned`);
   the screen hides while the drag lasts so the bar beneath takes the drop, and comes back. The detail line
   says "Equipped" or "Not equipped: drag it onto the hotbar"; an unequipped skill's rank numeral is dulled.
   Using an always-on passive's slot says it works while equipped. The Guide's Hotbar page says all this.
10. **Grid scroll** (screenshot pass note): a grid tab opens with its lowest filled tier at the bottom of the
    view (`SkillGrid.floor_y()`), not on empty T0/T1 rows.
11. **Settings layout**: its options row was an HBox overflowing the panel at both edges; now an HFlowContainer.
12. **Save** (x-save's hooks): `Game.equipped` (the starter's bar) is kept as edited (HUD), as levels auto-equip
    (`Battle._pay`), written as skill ids by `Save._equipped_out()`, read back by `_equipped_in()`, and put on
    the starter as it's set up (`Battle.starter()`, `Unit.set_equipped()`). `get_equipped()`/`set_equipped()`
    are the getter and setter. Learned skills themselves aren't saved yet (points are re-earned), so this mostly
    keeps the class's skills' arrangement.

Seen: always-on passives on the bar show the green "on" dot toggles use (is_on). Left as is; a question.

## As built

- Scripts: Unit.gd (equipping section: `equipped`, `_sync_new`, `_skill_sig`, `equip_skill`, `_auto_slot`,
  `auto_fill`, `get/set_equipped`, `_settle`, `_grants`, `_slot_keys`, `_arrange` by key, readers), Skill.gd
  (`fits_bar`), AI.gd, Modifiers.gd, HUD.gd (Setting, `_keep_bar`, passive slot use, bar sync), SkillSlot.gd,
  SkillWheel.gd, SkillGrid.gd, SkillTree.gd, SkillDetail.gd, Guide.gd, Game.gd, Save.gd, Battle.gd, Entry.gd;
  Scenes/UI/hud.tscn, Scenes/siren.tscn, Scenes/undine.tscn; Util/unit.py.
- Tests: new `equip_test.gd` (3 tests: equip/unequip incl. actives, reactions and hooks; auto-equip, the
  Setting and the skills-screen drag; losing slots by source, cascade, lost_skills). `sweep_test.test_passives`
  now unequips every non-pillar passive and checks every stat it moved is back (91). `save_test` round-trips
  the equipped set onto a starter. `Test.roomy(u, n)` gives a unit spare slots; used where a test hands a full
  bar more skills (actualization, adventurer, ai_support, ai_tactics, borrowed_time, capstones, derived, focus,
  general, hogel, hud, illusionist, last_stand, mindless_fury, modifiers, persona, reaction, stamina, warlock).
  Rewritten to the new rule: adventurer `test_starting_skills`, `test_typed_slots`; command `test_default_bar`,
  `test_bar_place`; hud `test_spellbook_and_bar`, `test_typed_slot_bar`; route/modifiers place the Sigil skill
  without wiping the bar.
- Mutation spot-checks: on_passives without `equipped()` -> 69 failures (sweep, equip_test); granted-slot keys
  by type only -> "the second keeps Hex" fails; `_sync_new` ignoring `auto_equip` -> 2 failures.
- Visual: shot_x-equip/a (frame 100 the bar with passives at the bottom; 122 Sola learned, not equipped; 138
  mid-drag with the screen aside; 163 Sola equipped; 184 Settings), shot_x-equip/r (108 Specialist tab on T2).
- Not done: Skill Slot +1 (?3) is still a stub; the per-unit (player-only) scope of the toggle; NPC-side
  equipping choices beyond extra_slots.
