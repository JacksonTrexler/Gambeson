# Todo: systems

`[ ]` to do · `(?N)` waits on open question N (numbered across all todo files) · *Now:* what the game does today. Done items and decided rules: `docs/done/`. Index: `todo.md`.

Build roughly in this order; the content below depends on them.

- [ ] **Checks and contests.** Skill-defined checks with `offensive` / `defensive` tags, advantage/disadvantage, per-skill range penalties. Needed by Jugular, Interject, Interdict, Gallantry, Turtle Tactics, Snapping Turtle, the Siren's Charm.
- [ ] **Equipment.** Two slots per unit for now: **armor** and **weapon**. Armor sets Defense; a weapon can change the attack mod and carry effects of its own (Burning Blade). *Now:* both slots exist and are set in the editor (Unit → Equipment). The items are Gambeson, Plate, Robe and a Rapier (dex for strength attacks). There's no way to equip them in play, and no item effects yet. (?9)
- [ ] **Shared tier 1 row**: tabs sharing a static tier 1 row, already unlocked (Warlock: a tab per patron, with Hex and Sweet Nothings). (?17)
- [ ] **Equipping.** Learned vs equipped; slots shared by actives and passives, passives filling from the bottom of the hotbar; auto-equip (on by default); losing slots. (?7) *Now:* the hotbar has 4 + level / 4 slots (+ `extra_slots`), then slots skills grant (typed slots built: `slots` effects), then the clover slot. Only actives and switched passives go on it, and every learned passive works.
- [ ] **Disabled skills.** Skills switched off for a number of turns, greyed out in the hotbar (Silent Strike).
- [ ] **Vision through the leader, plus Synergy.** *Now:* you see the clearest view any of your units has.
- [ ] **Skill categories and resources.** `martial` / `magical` / `specialist` tags on skills and trees; new resources (Stamina, Rage, Focus, Sweet Nothings, Power, Hype, Clout, Gold). *Now:* the category tags are on Strike and Wary (martial), the Magic spells and Hex (magical), and Snare, Hazard Expert and Darkvision (specialist). Only Mana exists, so Field Experience and Everyman have nothing to work with yet. Skills can be cheaper paid with a reserve (`cost_with`), once a passive opens that reserve up to their tier (`opens`: Mana). Classes can start with reserves (Wizard: 10 Mana).
- [ ] **Reactions and interrupts.** Units acting outside their turn: Interject, Gallantry, Final Act. *Now:* only the side whose turn it is acts (and traitors posing in its party).
- [ ] **Facing and direction**, for Shields Up!.
- [ ] **Effect strength set when cast**, for Rejuvinate's distance decay. *Now:* a timed effect's strength is fixed.
- [ ] **One-use tile effects laid by skills**, triggered on entry (Warcry). *Now:* only traps and zones.
- [ ] **Teleport**, for Send Off.
- [ ] **Pushes**: forced movement away (pulls and drags exist).
- [ ] **Investigating on contact**: units coming into contact with hidden units investigate them, with the same roll. A deceiving skill's effects keep its roll for this.
- [ ] **Damage for moving**: effects that hurt a unit when it moves, which Meander can ward off at a higher rank.
- [ ] **Hard to read, by debuffs**: Haluca exists; others to come. *Now:* negative cha.
- [ ] **Fear, shove and entrance effects**: ways to make a grappler let go (or move) besides breaking free.
- [ ] **Commitment to the bit**: skills that let a traitor follow through on attacking its real allies rather than whiff (a Cultist, Oath or Devotee tree).
- [ ] **More ways suspicion wears off.** *Now:* a Siren's Sing and Pray to Eros, a stack at a time. No decay for now.
- [ ] **Divinity trees**: one per god, each with Pray at tier 1: Ramut (war, power), Eros (love, healing), Sol (light, fire), Urlo (magic, energy), Luun (dark, jovial), Drael (water, air), Vetruvis (earth, music). *Now:* Pray is a Paladin option; the Paladin worships Eros.
- [ ] **Urlo's enchantments, the rest**: trinkets (after weapon and armor), skills on items (their own enchantment effect, else +1 rank), and skipping items that can't be scaled (Heart +1). Needs equipment skills and a trinket slot. *Now:* weapon and armor, +1 or the item's own enchanted form.
- [ ] **More contextual clues for searching**. *Now:* the AI weighs what it finds suspicious and enemies' debris.
- [ ] **Rangers**: Observe belongs on their tree too, once they exist.
- [ ] **Dissonance by how far the lie is**: harder to pretend to be something you very much aren't (a wolf in sheep's clothing, not a scary dog). *Now:* a tally of what the persona puts forward.
- [ ] **Persona descriptors** for unique units: intention and strategy, beside adjectives, nouns and dissonance (Astral Princess). (?22)
- [ ] **Power**: a resource that replaces a unit's Energy, usable wherever Energy is. A yellow bar tinted orange with a star icon, pulsing white above 75% and blue at 100%. It never recovers on its own; tools, items, skills and tiles give it back. (?22)
- [ ] **Hearts**: extra lives. On taking mortal damage, a unit with a heart left revives to full health at the end of the current side's turn. A faction counts its max and consumed lives. (?22)
- [ ] **Channeled skills**: cast once to pay AP, cost and start channeling; cast again for a small AP and cost to act (Metea). (?22)
- [ ] **Energy damage**: skills that hit Energy (or Power), carrying over to HP (Smite). (?22)
- [ ] **Pillar skills** (`pillar`): sit in the last sure slot, the easiest to disable; disabling one disables every pillar skill. Needs Disabled skills. (?22)
- [ ] **Equipment skills and a trinket slot**: items carrying skills (Starblade, Heart Up-Link, Heart Up). (?9 ?22)
- [ ] **Drops**: rewards with chances, from units as they fall. (?22)
- [ ] **Uncontrolled allies**: units on the player's side the player doesn't command (shades). (?22)
- [ ] **Unbounded maps, camera control, spawning mid-battle**, for Infernal Meadows (and Regeneration Probes).

21. Evidence: "14 is mid": I made 10–14 the middle band (2–3 debris, 1–3 tiles off) and 9 or less poor. Right floor for "mid"? Debris from hiding and from moving despawn by the same rule (placement range + dex mod). Right?
