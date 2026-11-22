# w9-undead: undead tag, Restless Dead ??, noticing, laid to rest, summon soft cap

## Goal
User (answers-2026-11-22c, -22): skeletons/zombies are `undead`; undead + Disturbed = behaviour "Restless Dead ??": attack nearest visible
non-undead, allies on ties; allies who notice (medium-easy check) treat it as a foe; Disturbed/hostile allies act after cognizant ones;
removing Disturbed from an undead eliminates it; necro summon soft cap = rank + stat mod, excess Disturbed (trait) furthest first.

## Readings
- Tag `undead` exists (Tags.gd colour, Skeleton scene tags [undead, summon], Perception identity, PersonaPanel TAGS). No zombie unit exists: none added (record).
- Read.attitude(o) is the one foe/ally seam (AI _foe, _targeting, _strike, Battle.teammates/_trusts all read it).
- No brainwash model; "brainwashed / hostile allies" = Disturbed (Command.idle already lists them; uncontrolled shades act alone too).
- Persona check: Battle.doubt() is the wis-vs-persona check; noticing uses a wisdom check (tags inquire, as doubt) vs DC approachable ("moderate low" = medium easy, flat 8).
- Trait = Applied.lasting (no expiry).

## Decisions
- No Undead faction: a restless unit keeps its side (acts on its side's turn, after cognizant allies; "allies on ties" needs the side). A faction switch would show its side to every reader at once (no room for the noticing check), add a turn-order entry mid-battle and block victory checks. Attitude is per-reader instead.
- Seam: Unit.restless() = disturbed() and has_tag(undead) (any source of either: status, item, trait, persona-free). Battle._read sets Read.dead_eye (observer restless: judges by perceived tags, so a persona tagged undead fools the dead) and Read.restless (target restless and this observer noticed). attitude(): dead_eye -> ally if undead in tags else foe; restless -> foe.
- AI mode: AI.act branch on u.restless() (generic: tag + status, not unit) -> _restless(): nearest (tiles) located, seen foe-by-attitude; tie -> same faction; strikes it (_strike on that one read), else walks to it (_approach).
- Noticing: Scripts/Undead.gd (static, no class_name) settle(b, caster) runs at the outermost cast's end (Battle._done_casting) and at end_turn after ticks. A restless caster that acted: each awake ally (Faction.friends) that reads it located+seen and hasn't noticed rolls once per witnessed action.
- Laid to rest: Battle.restless dict (unit -> observers that noticed) holds every restless unit seen at a settle; one no longer Disturbed (dispel, expiry) but still undead and alive is slain (Unit.slay: the one instant death).
- Order: Command.cognizant_first(units) (stable: Disturbed last), used by HUD._act_alone.
- Soft cap (summon_per_rank.gd): cap = impact rank + cast stat mod (as keeps()); summoner's raised (Unit.raised_by), alive, not Disturbed, over cap -> Disturbed lasting, furthest from summoner first. Read as a one-way process ("until the cap is satisfied" = keep disturbing until controlled count <= cap): Disturbed summons don't count, the cap never lifts it (lifting would slay it by the removal rule).
- SUMMON_CAP removed: bodies() returns only the bodies that stay under control (min(count, cap - controlled)), so AI._summon prices the over-cap ones at 0; summon_test "side full" -> "cap full".

## Done

## Next
code, tests, mutations, sims, checks
