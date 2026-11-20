# Preparation uses: Surveyor, Evaluator, Inquisitor (w7-prep, 2026-11-20)

The user (docs/agents/answers-2026-11-20b.md, "Preparing. Studies left..." / specialist general): three low-tier Specialist skills, each a rank
of a preparation use and a +rank on its kind of check in battle. Read first: docs/plans/w7-studies.md (the top box, `HUD.prep_uses`).

## Readings and calls

1. **One table, `Prep.USES`** (`Scripts/Prep.gd`): a use has `of` (target kinds tile / ally / foe), `intel`, `suspicion`, `edge`, and its count
   (`mod`: Study's stat mod; none: the Effect stat `prep_use` tagged with the use's id). Five rows: `study_ally` (cha mod, intel), `study`
   (wis mod, foes and tiles, intel + suspicion), `survey` (tiles, intel, advantage), `evaluate` (units, intel, advantage), `inquire` (units,
   suspicion, advantage). Study is "two rows" because it has two pools (ally by cha, foe or tile by wis), as before. `Battle.study()` became
   `Battle.prepare()`, returning the use spent (&"" for none); `studied_allies` became `Battle.prepped` (use id -> targets).
2. **The tag is the use and the check.** One tag per skill (`survey`, `evaluate`, `inquire`, new Glossary terms, kind check, named with ?? as AI
   names). The skill's two Effects share it: `prep_use` (per rank: the count) and the in-battle bonus (`check` tagged the same). A later skill
   can add to either by the tag.
3. **What a click spends** (`Battle.prep_use()`): the first row, in table order, that fits the target's kind, has one left, wasn't spent on it,
   and still gives it something (intel it hasn't had, or, for an inquire row, suspicion). Study first (intel and a look), then the skills' rows;
   a studied unit goes to an Inquisition if there is one, else "Already studied". The player can't pick which use a click spends (no HUD for it).
4. **Outcomes.** Intel: the target is read a recon level better (`studied`, once per target across uses: a Survey after a Study of the same tile
   is refused, not stacked). Suspicion: a tile is inspected (`inspect(..., edge)`); a unit that fools the leader (`read.deceived`) is doubted
   (`doubt(..., edge)`), as Study's foe look did. An Inquisition on an honest unit spends the use for nothing (nothing to see; and no wrongful
   suspicion of an honest ally). Inquisitions fit allies and foes both: a foe passing as an ally is the point.
5. **Advantage on an intel-only use is data with nothing to roll** (call, ?). Intel is a level, not a check, so a Survey's or an Evaluate's
   `edge` is carried by the table but changes nothing; an Inquisition's `edge` is a real advantage on its `doubt()`. If intel should roll, say so.
6. **In-battle channels** (the user: "rank bonus to checks"):
   - Surveyor: `inspect()` (a check to learn of a tile and what hides there) carries `survey`.
   - Inquisitor: `doubt()` (overcoming trickery) and `investigate()` (seeing through what a skill hid) carry `inquire`, and so does the
     forecast `seen_odds()`. doubt's other side carries none (`their_tags = []`): a trickster's own Inquisition doesn't help it lie.
   - Evaluator: sizing a unit up is not a roll in this game, it is recon (`Perception.unit()`: net = recon minus concealment). So the bonus is
     `recon` tagged `evaluate`, asked with `Perception.sizing(t)` (the unit's tags plus `evaluate`; also in `fools()`). Call: that recon also
     counts against trickery, as every point of recon does. Tiles are not sized up this way (they have `survey`).
7. **Placement.** All three on Specialist (`general_specialist`) at tier 2 ("low": the tree runs 1-7, Synergy and Decisive Strike are 2; Resuscitate
   "mid" is 4), no prerequisite. Offered outright (Role.options, as Discipline is the Paladin's): Surveyor to Fighter and Druid, Evaluator to
   Fighter, Inquisitor to Cleric and Paladin. Druid and Cleric had no `options` yet; `skill.py new --role` now takes several
   (`fighter,druid`) and adds the Skill type to a role that has none.
8. **Names.** The skill names, ranks and the user's words are as given (`--human`: Surveyor, Evaluator, Inquisitor; labels "Surveys",
   "Evaluates", "Inquisitions"). Mine, with ??: the tags (`survey ??`, `evaluate ??`, `inquire ??`) and the stat `prep_use` (shown "Preparation").
9. **HUD.** Each skill-granted row gets a line in the top box via `prep_uses` ("Surveys: 2 tiles", "none left" once spent; none at all for a
   leader who never had one). The log says "X surveys / evaluates / inquires about Y". The magnifier is open while a click would spend something.

## Tests (Tests/prep_test.gd, extended; no new file; the three skills ride the sweep)

`test_uses` (Survey: intel without an inspection; Inquisition: doubt of a unit that fools, no intel, once per target; counts by rank),
`test_use_order` (Study, then Evaluate; a studied unit takes the Inquisition, not an Evaluate), `test_check_channels` (+rank only on the tagged
check; recon `evaluate` in a read; `inspect`, `doubt`, `investigate` each count a 30-point tagged bonus), `test_hud_uses` (lines, countdown, log).
Existing study tests: `b.study(...)` calls became `b.prepare(...) == &"study"` and the like (same rules).
Mutation spot-checks (each failed a test, reverted): `inspect` without the survey tag; `doubt` without its tags; `investigate` without inquire;
`Perception.unit` without `sizing`; Survey given suspicion; `prep_use` without the "already had" skip. Not covered: `their_tags = []`, and
Inquisition's advantage (doubt's edge is covered in suspicion_test).
