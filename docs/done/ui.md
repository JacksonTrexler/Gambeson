# Done: UI and styling

`[x]` done · `(?N)` an open question in `docs/todo/` that may still change it · *Now:* what the game does today. Index: `completed.md`.

- [x] Faction look on the map: a faint glow of the side's primary colour replaces the outline. HP, then 2px each of the main reserve and Energy, sit in one block with a darkened faction trim.
- [x] Tooltips over icons after 1 s.
- [x] Settings (cog) with the **Guide**: the instructions from the old hint line and key legend. The hint line now only shows status and notes.
- [x] Typed hotbar slots: dull red / purple / green, tinted and trimmed like the clover slot; an empty one says what it holds ("magic only").
- [x] Skills screen as trees, radial for the Adventurer: a wheel with Skill Slot +1 at the centre, a core ring (starting skills, Hex, the slot skills), and the three roots in their slot colours. Learned skills are filled and ranked, learnable ones ringed (gold while there's a point), stubs dashed with their question number. Clicking a skill shows it beside the wheel, with Unlock or Rank up. *Now:* other classes still get lists, until their trees exist.
- [x] Entry screen defaults: name **Shrike** (muted in the empty name box, used until something else is typed), faction **Lancin**, class **Adventurer**. Enter starts the demo at once.
- [x] Effect icons on the unit card: one per skill or condition timed on it, green if it helps; the tooltip says what it does and how long it has left. A roll it was put on with shows small in the top right, when Self-evaluation saw it. (?20)
- [x] Personify's panel (`PersonaPanel`): pickers for vibe words and identity tags (type to filter, Enter takes the top match, chips to take one off), stance, claimed level and name; "Changes: n / rank", Done off past it; a held **Clear**.
- [x] The **character sheet** (the dock's character icon; `CharacterSheet`): the selected unit's weapon, armor and trinket (hover for what each does), its hearts, and the stash, with Equip, Take off and Use while it can change them, each showing its AP in battle ("Equip · 3 AP"). A potion in the trinket slot has Use.
- [x] The victory screen lists the **spoils** the player's side takes home.
- [x] Disabled skills on the hotbar: dimmed, the tooltip saying for how many turns; using one says so. Cursed ones (Brainfog), and slots a level curse sealed, quiver gently. Pillar skills can't be dragged.
- [x] The clover slot disappears from the hotbar while its unit is unlucky, and comes back with its skill.
- [x] **Power** bars: yellow tinted orange, pulsing white above 75% and blue when full; cards say PW for it.
- [x] Unit cards: a unit's hearts left ("2 hearts left") and a **Down** chip; downed units show faded on the map. An insightful read adds what a unique unit intends and whom it goes for.
- [x] The entry screen picks a **scenario**: the Museum or the Astral Envoy.
