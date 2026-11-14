# Gods: one god system for class trees

## Readings (before building)

- Trees are chosen today through `TreeChoice` boxes on a class's own tab (`Role.choices`): the Cleric's
  God (Luun, Sol, Eros tabs, pick 1), the Paladin's Prowess (six tabs, gated per god by `SkillRoot.gods`),
  the Warlock's Patron (Elmon, Hogel, pick 1). `Unit.pick()` stores "Choice/Tab" in `Unit.picked`; units
  authored with a tree's skills and no picks count that tree picked. There is no save file: picks only live
  on units in a run, so "existing saves" means the tests and authored scenes.
- Whom a unit serves is already one value, `Unit.deity()`: its own `god`, else its picked devoting tab's
  god, else its class's (Paladin: eros). The god system hangs off that.
- "Efficiency" in the user's answers is the existing Affinity (cost curve of `Unit.worth`/`rank_for`):
  +1 Affinity makes rank-ups cheaper. A guest tree's -1, Natural Talent's +1 up to a tier, and the
  `Behaviour.affinity()` hook (Illusionist) already exist; an efficiency stack is +1 Affinity on a tree's
  skills up to a tier, through those.

## Calls

- **God as data.** `Scripts/God.gd`, one `Gods/<id>.tres` per god and patron (`patron = true` for Elmon and
  Hogel: "one god system"). A god has its own tree (`own`: Divinity: Luun, Patron: Hogel) and a `pool` of
  SkillTabs it offers; each tab's `kind` is its slot kind (Prowess, Divinity, School...). `Unit.GODS` /
  `GOD_TAGS` (domains, damage tag) stay where they are for now: moving them is churn with no new behaviour.
- **Slots are TreeChoices.** A choice with `kinds` is a god slot: its trees are its picker's god's (own +
  pool) of those kinds. `TreeChoice.all()` is the union over every god, so choice boxes, `choice_of`,
  borrowing (the Wizard's Domain) keep working; `Unit.suits()` now asks the god's pool. `SkillRoot.gods`
  is gone: the prowess alignment (?69) moved into the god files unchanged.
- A choice with `gods = true` offers each god's own tree of its kinds (Cleric: Divinity; Warlock: Patron):
  picking it is choosing the god (deity() reads it, as before).
- **No choice, no pick:** a slot whose god offers no more trees than it may pick opens them without one
  ("if there's choice at all"). `grants = true` opens every tree of its kinds (the Cleric's domains).
- **Cleric:** God (pick 1, a level 1 choice on its own tab) then Domain, granted: the god's School-kind
  domain caster trees. Pools: Sol offers Radiance (light), Luun Shadow (dark), Drael Currents, Vetruvis
  Stone, Urlo Stars, Eros and Ramut none yet. So a Sol Cleric gets Divinity: Sol and School: Radiance.
  Mage-only skills on them stay Mage-only (Skill.classes).
- **Paladin:** Prowess (its god's prowesses), Domain (its god's Divinity), Flex (any prowess, divinity or
  school its god offers). Divinity: Eros moves off its own tab into the Domain slot; with one Divinity per
  god it opens with no pick, so an Eros Paladin still has it from the start. Idealism: Chivalry stays on its
  own tab (call: moving it to Flex would cost every Paladin it; "specialist leadership" flex trees can be
  added to pools later).
- **Warlock:** Patron (pick 1 of the patrons' own trees) plus Flex, 2 slots, after Bargaining: another
  patron's tree as a pact, or a burned slot. A burn is a tab in the Flex box mirroring the unit's patron
  tree's name, drawn darkened with the disabled look; picking it is a flex slot spent on +1 Affinity to the
  patron tree.
- **Efficiency stack, one mechanic:** `Unit.efficiency(s, t)`: +1 per stack reaching tree t at s's tier.
  Sources: a learned passive with `Behaviours/efficiency.gd` (kinds or names of trees it reaches; its rank
  is the tier cap), and burned flex slots (all tiers: call, "up to rank tier" read as no cap for a burn since
  a burn has no rank). Bargaining (t5) and Acceptance (t10) are the same behaviour on the Warlock's own tab,
  reaching kind Patron, stacking. Ranger capstones use it too.
- **Ranger (81):** three midpoint capstones, one per root, each opening a guest choice (`by`), at -1 like
  guest trees, and each an efficiency stack on its guest trees up to its rank:
  - Bounty -> lighter martial prowess: reuses **Prowess: Slayer** (hunting).
  - Scout -> survival specialist tree: a new **Survival ??** tree (stub skills to fill).
  - Forester -> nature caster tree: the existing **Nature** choice (Druid biomes, Natural Talent), now
    opened by the capstone instead of from the start.
- **Domain-general skills (Heal, Megaheal: "t8 cleric, life, love domain general"):** they belong on a
  domain tree in the pool of each god of that domain (a skill on several trees is one skill), so a Cleric
  gets them through its god, and a Paladin or Wizard taking that tree as a flex or domain gets them too.
  Until a Life tree exists, the Cleric's own tab (beside Pray and Renew) is the place; a-recover decides.

## As built
- `Scripts/God.gd`, `Gods/<id>.tres` for the seven gods and the two patrons; shared pool tabs in
  `Gods/tabs/` (the six prowesses, five Mage-school trees). Ramut, Urlo, Drael and Vetruvis have no own tree
  yet (no Divinity tree exists for them), so a Cleric can't choose them yet - unchanged from before.
- `TreeChoice`: `kinds`, `gods`, `grants`, `burns`, `after`; `all()` unions every god's offer for a slot;
  `own()` is what a class lends the Wizard (god-slot trees aren't lent, so no School tab picks up the
  Cleric's Pray and Renew). `Role.choices_of()`: a tree may sit in two slots.
- `Unit.offered()`, `picks()` (no-choice and `grants` opening), `pick_missing()` (slots' "Picked" for a tree
  open through another slot; burns count against the slots), `burnable()`, `burned()`, `efficiency()`;
  `suits()` asks the god; `SkillRoot.gods` removed from the script and six trees.
- Order changed: gods by file name, so the Cleric's box reads Eros, Luun, Sol (was Luun, Sol, Eros), and the
  Paladin's Prowess box Havoc, Slayer, Protector... in god-file order, filtered by its god as before.
- Skills screen: each slot a box; a slot leaves out trees already open through another; a tree in two boxes
  gets an entry in each; the Warlock's Flex shows its own patron once, as the burn: darkened, glyph at a
  quarter, quivering once burned (the hotbar's cursed look), "xN" burns in the corner, tooltip saying so.
- Warlock: Bargaining (t5) and Acceptance (t10) as the user named them, `options` on its own tab, tier by
  `min_tier` ("investment in the general warlock tree" read as skills learned: call), max rank 5 each,
  passives with `Behaviours/efficiency.gd` reaching kind Patron. Their stack reaches every patron tree the
  Warlock holds, pacts too ("patron trees", plural: call). Flex: 2 picks after Bargaining; picking its own
  patron burns a slot (both may be burned).
- Ranger: capstones Quarry ?? (Bounty, needs 2), Survivalist ?? (Scout, needs 2), Wildcaller ?? (Forester,
  needs 1: half of each root), passives, max rank 5. Quarry opens Prowess: Slayer (a new Ranger choice, -1),
  Survivalist the new Survival ?? tree (kind Path, -1, one stub skill Forage ?? waiting on ?81), Wildcaller the
  existing Nature choice (no longer open from the start). Each is an efficiency stack on its tree up to its rank.
- Tooling: `role.py god` (a god or patron, or more pool trees), `--god` reads `Gods/`, `check` checks gods;
  `skill.py new --needs` (capstones) and options on a class with no roots. `.claude/skills/new-class` isn't
  edited (house rule): it should mention `role.py god`.
- Tests changed to the new rule: casters_test (Wizard's tree order, borrowed roots read off God files),
  hogel_test (Cleric picks by God), general_test, sol_test, warlock_test (patrons by God), paladin_test
  (slots, prowess order), hud_test (Domain tab, the boxes, species tab index), progress_test (Paladin offer
  order), nature_test (Nature waits on Wildcaller; its stack). New: god_slots_test, bargaining_test,
  acceptance_test, quarry_test, survivalist_test, wildcaller_test, forage_test.
- Undone / open: Paladin "specialist leadership" flex trees (none exist; Idealism stays on its own tab);
  Unit.GODS/GOD_TAGS not moved into God files; Survival ?? needs real skills; a burn's tier cap (read as
  none).
