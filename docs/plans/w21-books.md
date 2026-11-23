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
