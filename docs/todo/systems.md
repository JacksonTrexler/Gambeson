# Todo: systems

`[ ]` to do · `(?N)` waits on open question N (numbered across all todo files) · *Now:* what the game does today. Done items and decided rules: `docs/done/`. Index: `todo.md`.

Build roughly in this order; the content below depends on them.

- [ ] **Checks and contests.** Skill-defined checks with `offensive` / `defensive` tags, advantage/disadvantage, per-skill range penalties. Needed by Jugular, Interject, Interdict, Gallantry, Turtle Tactics, Snapping Turtle, the Siren's Charm. *Now:* each contest is its own field (Drown's `drags_to`, Sing's `resisted`, Haluca's and Brainfog's `save`).
- [ ] **Equipping skills.** Learned vs equipped; slots shared by actives and passives, passives filling from the bottom of the hotbar; auto-equip (on by default); losing slots. *Now:* the hotbar has 4 + level / 4 slots (+ `extra_slots`), then slots skills grant, then the clover slot (filled on its unit's turn; hidden while it's unlucky, remembering its skill). Only actives and switched passives go on it, and every learned passive works. Disabling (Brainfog) treats always-on passives as filling the bar from the bottom. Unequipping a slot-granting skill should make its slots disappear.
- [ ] **Real trees for Fighter, Paladin and Wizard**: their tab is their options by tier for now.
- [ ] **Bracing in more checks**: investigations, hiding and last stands don't take it yet.
- [ ] **More resources**: Stamina, Rage, Focus, Hype, Clout, Gold. *Now:* Mana, Sweet Nothings and Power exist, so Field Experience and Everyman still have nothing to work with.
- [ ] **Reactions and interrupts.** Units acting outside their turn: Interject, Gallantry, Final Act. *Now:* only the side whose turn it is acts (and traitors posing in its party).
- [ ] **Facing and direction**, for Shields Up!.
- [ ] **Effect strength set when cast**, for Rejuvinate's distance decay. *Now:* `Unit.Applied.scale` exists and multiplies an effect's amount, but nothing sets it below 1 yet; arcs (wauaw) climb and fall by the turn.
- [ ] **One-use tile effects laid by skills**, triggered on entry (Warcry). *Now:* traps, zones, debris and earthworks, each its own kind.
- [ ] **Teleport**, for Send Off.
- [ ] **Pushes**: forced movement away (pulls and drags exist).
- [ ] **Investigating on contact**: units coming into contact with hidden units investigate them, with the same roll. A deceiving skill's effects keep its roll for this.
- [ ] **Damage for moving**: effects that hurt a unit when it moves, which Meander can ward off at a higher rank.
- [ ] **Hard to read, by debuffs**: Haluca exists; others to come. *Now:* negative cha.
- [ ] **Fear, shove and entrance effects**: ways to make a grappler let go (or move) besides breaking free.
- [ ] **Commitment to the bit**: skills that let a traitor follow through on attacking its real allies rather than whiff (a Cultist, Oath or Devotee tree).
- [ ] **More ways suspicion wears off.** *Now:* a Siren's Sing and Pray to Eros, a stack at a time. No decay for now.
- [ ] **Divinity trees**: one per god, each with Pray at tier 1: Ramut (war, power), Eros (love, healing), Sol (light, fire), Urlo (magic, energy), Luun (dark, jovial), Drael (water, air), Vetruvis (earth, music). *Now:* Pray, Renew and Coordinate are Paladin options; the Paladin worships Eros. The shared tier 1 row (`Role.shared`) is built, for a tab per god.
- [ ] **Urlo's enchantments, the rest**: trinkets, skills on items (their own enchantment effect, else +1 rank), and skipping items that can't be scaled (Heart +1). *Now:* weapon and armor, +1 or the item's own enchanted form; the trinket slot exists but Urlo skips it.
- [ ] **Skills on items**: an item carrying a skill its wearer can use while it's equipped. *Now:* items carry effects, hearts and their own fields (Starblade's refill), not skills.
- [ ] **Last stands elsewhere**: the general defensive check (`Battle.last_stand()`) is meant to come up again; only Level Down and Death use it now.
- [ ] **Execute, more**: other skills tagged `execute` should cut a foe's defensive checks by how hurt it is, as Death does. *Now:* only Death.
- [ ] **Shops** (later): another way to get items.
- [ ] **Saving**: the stash, the starter's outfit and hearts last only until the game closes.
- [ ] **More contextual clues for searching**. *Now:* the AI weighs what it finds suspicious and enemies' debris.
- [ ] **Rangers**: Observe belongs on their tree too, once they exist.
- [ ] **Dissonance by how far the lie is**: harder to pretend to be something you very much aren't (a wolf in sheep's clothing, not a scary dog). *Now:* a tally of what the persona puts forward.
- [ ] **Unbounded maps, camera control, spawning mid-battle**, for Infernal Meadows. *Now:* units can be summoned onto a fixed map (`Battle.summon()`: Regeneration Probes).

21. Evidence:  "14 is mid": I made 10–14 the middle band (2–3 debris, 1–3 tiles off) and 9 or less poor. Right floor for "mid"? Debris from hiding and from moving despawn by the same rule (placement range + dex mod). Right?

## Composability seams (see `docs/plan-composability.md`)

- [x] **`Check` resolver** - done; see `docs/done/systems.md`. Next on it: Affinity and context tags hook in here.
- [ ] **Tile stacks**: a cell becomes an ordered stack of terrain layers; a masking layer hides those below. Collapses the snare/zone/earthwork dicts over time. (?59)
- [ ] **Behaviour spine for skills**: grow `Skill.behaviours` (compose verbs that read a shared `Cast` bag) beside the flags; lift flags into behaviours on touch, densest clusters first (Strike chain, damage+riders, heals). Describe-where-you-execute. Answers ?55.
- [ ] **Context tags**: tag each cast offensive / defensive / supportive by use, feeding `Check` and the Affinity rank-cost. Enables Berserker and "invest under circumstances".
- [ ] **Derived-stat pipeline** (`Unit.derive()`): base ± respec ± buffs -> HP formula -> refit bonuses. HP = `((con mod · (1 + hardy)) + class_base) · level`; hand-authored bosses keep flat `max_hp`. Enables Hardy, Meditate respec, Self-reflection.
