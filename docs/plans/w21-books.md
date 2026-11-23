# w21-books: self-help books modify a unit's bio
Goal (user): four common consumable books; Read = medium cha check + medium int check; success -> pick one tweak
(behaviour+, preference+, deity+); AI picks automatically. Two new tempers Compliant, Hungry (+ Pragmatic if absent).
Baseline suite: 11564 checks, 0 failed (1081 tests).

## Readings
- Exist: tags love/int/con (Tags.gd), `book` (Strategy Guide trinket), drain/siphon; temper flirty; gods eros/urlo/ramut/drael (Gods/*.tres; tags love/energy/physical/water).
- Missing: temper `pragmatic` (only `Unit.tends = pragmatic`, a heal style: skips heals wasted on a nearly-whole unit, adds level to its want).
- Bio has no deity field; Unit.god = one prayer target (Pray, tree gating). "Persona" = Bio.
- Items have no description field. Player units have no bio and Bio isn't saved.
- Checks: `Battle.check(u, &"charisma", null, Difficulty.dc(&"medium")).won` (Difficulty.word -> standard, flat DC 12).
- Items used: CharacterSheet "Use" -> used_up -> HUD._on_used_up -> Battle.use_item. Picker: HUD._choose(title, [[label, callable]]).

## Calls
1. Items: four consumables, tag `book` (existing; no new tag), common, names `--human`, subtitles verbatim in new field `Item.blurb`. New Item fields (Book group): `blurb`, `temper` (a Bio.BEHAVIOURS word), `leans` (a Bio.prefers word), `favours` (a God id). Tool: item.py check holds them (book tag + consumable, known temper, god exists); `--set temper=&"x"` writes them.
2. Loot: all four added to `Loot/alabaster` (the Meadows champion: the early scenario drop) at weight 1 each (a Heart is 4); no test pins that table's contents (the emblem tests only count symbol items).
3. Life by the Gavel has no preference+ (the user gave none): two tweaks, behaviour+ and deity+. Others three.
4. Read = `Battle.study(u, it)`: AP like any item (1), both checks always rolled (`Battle.check` vs `Difficulty.dc(&"medium")` = standard, flat DC 12: charisma then intelligence), pass = both. Returns {passed, tweaks, cha, int}; the HUD (`_read`) erases the book from the stash either way (call: consumed on pass or fail), logs it, and on a pass opens `HUD._choose` (Cancel = take none, book still gone). `use_item` refuses a readable book. CharacterSheet button says "Read". Between battles (PartyPanel) books can't be read: no battle for the checks (`not between` gate kept).
5. Tweaks are plain bio data: `Bio.tweaked(bio, {kind, word})` returns a COPY (scene bios are shared among units); behaviour+ = lead temper if the bio has none (so a behaviourless unit leaves the ordinary-turn shortcuts and its temper runs), else appended to `also`; preference+ appends to `prefers`; deity+ to NEW `Bio.favours`.
6. Persistence: the player's unit had no bio and none was saved. `Unit.to_dict` now writes `bio` (`Bio.kept()`: behaviour, also, prefers, favours) and `from_dict` reads it (`Bio.from_kept`), only if present. Save format gains an optional key.
7. Deity+ (best guess): no "favoured deities" existed. `Bio.favours` = gods it holds dear. Rules reading it: `Unit.deity()` falls back to the first favoured when it has no god, devotion or class god (so a godless unit can Pray); `spec_options` adds each favoured god's domain tag (`God.tag`: eros love, urlo energy, ramut physical, drael water) to its preferences, so autospec leans that way. A class god is unchanged (favouring Eros on a Paladin: no effect beyond the lean).
8. AI picks: `Unit.fancy(offered)` = first tweak its bio lacks, skipping a god it already serves. Nothing makes AI units read books on their turn (no AI "use item" turn exists; `Battle.study` + `fancy` are the seam). Flag.
9. Tempers: Bio.BEHAVIOURS + TEMPERS gained `pragmatic`, `compliant`, `hungry` (Guide lists them, unit.py BEHAVIOURS mirrored).
   - Pragmatic did not exist as a temper (`Unit.tends = pragmatic` is a heal style). Call: temper pragmatic IS that heal style: `AI._heal` reads `u.tempered(pragmatic)` as tends pragmatic (skip heals wasted on a nearly whole ally, weigh level). Small; the user gave no definition. "Hate"/aura blindness ("bad person is good") not done.
   - Compliant: `AI._orders(u, t)` joins `_hunted` (feeds `_strike` and `_targeting`): ORDERED 4.0 for the leader's (`u.follows`) aim (the meta `aim` _strike/_full already set for drilling followers) while it stands and is alive; leader with no aim: half for a foe within 2 tiles of the leader (estimate of what it would want first). No leader: 0.
   - Hungry: `AI._hungry` after `_smitten` in `_strike`: a skill tagged `siphon` or `drain` (existing tags; reuses `siphon` of w20) is worth + GAIN 0.5 x hit chance (`_chance`: low Defense -> likelier) x min(avg damage, what the target has: HP, or for siphon the Energy read). Other skills unchanged. Only `_strike` weighs it (not the walking target pick). No lifesteal skill exists yet; `drain` tag = future ones join.
10. Item names `Applied Charizzmatics` etc.: `--human`, no `??`. Icons: tool's consumable placeholder (a brown book).
11. `int`/`Con`: tags `int` and `con` exist (Tags.gd), used as-is.

## As built
Files: Scripts/Bio.gd (BEHAVIOURS, favours, holds/tweaked/kept/from_kept), Item.gd (Book group, readable, tweaks, describe), Unit.gd (tweak, fancy, deity, spec_options, to_dict/from_dict), Battle.gd (study, use_item), HUD.gd (_read, _on_used_up), CharacterSheet.gd (Read label), AI.gd (_orders, _hungry, pragmatic heal, consts), Util/item.py (book checks + doc), Util/unit.py (BEHAVIOURS), Items/{applied_charizzmatics,sensible_approaches,life_by_the_gavel,dungeoneer_delicacies}.tres + Icons/Items/*, Loot/alabaster.tres, Tests/books_test.gd.
Tests: new Tests/books_test.gd, 4 tests: test_read (table over every readable Item: pass both / fail cha / fail int, via the HUD: consumed, picker, tweak lands), test_tweaks (copy, god, kept round trip), test_compliant, test_hungry. Existing tests changed: none.
Mutations (each fails books_test): passed = int only; _orders aim 0; _hungry off; tweaked without duplicate; stash erase dropped (13 fails).
Visual: S/shot_w21-books/ (Read buttons on books in the stash; picker "behaviour+ Flirty / preference+ Love / deity+ Eros / Cancel").
Undone: no Pragmatic test (heal style shared; tends untouched), no AI turn that reads books, no between-battles reading, no HUD sign for the new tempers, `Bio.line` shows favours nowhere.
