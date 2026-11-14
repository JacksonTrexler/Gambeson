# Tag colours and item trim (m-colors, 2026-11-14)

The user: "associate a color with each tag. Accessories associated with tag has trim color (eg banner
with color insignia)". And: "the less actual text they have to read the better".

## Readings

- "Each tag": every word things carry - Glossary terms (Glossary.TERMS), Tags.PARENT's children and
  parents, and every word on a skill, item, unit, tile, property or effect (`tags = ...` in .tres/.tscn).
- Colour already exists in three uncoordinated tables: Glossary.ELEMENTS ({x:fire} damage tags),
  Glossary.KINDS (term links by kind), SkillSlot.TINTS (the hotbar stripe by a skill's first tinted tag).
  They disagree (magical #b49ae6 vs #a179f2). One table replaces the colour part of all three.
- Equipment isn't composed on the sprite (one PNG per unit; Bio.appearance is text), so trim on the
  sprite is a small drawn banner, not a recoloured part.

## Calls

1. **One table, in Tags.gd: `Tags.COLOR := {&"word": Color("#rrggbb")}`.** Not a fourth field on
   Glossary.TERMS: most coloured words aren't Glossary terms (magical, metal, cha), siblings add TERMS
   lines in parallel, and a flat dict keyed by StringName takes m-core's symbols (rho_up...) later
   unchanged. Glossary.ELEMENTS and SkillSlot.TINTS go; Glossary.KINDS stays as the kind palette.
2. **One reader, `Tags.color(word) -> Color`:** its own entry, else its parent's (Tags.PARENT), else
   `Tags.NEUTRAL` (#c9ccd4, Glossary.TAG's grey).
3. **Every existing word gets an explicit entry**, except PARENT children that inherit (slash, pierce,
   blunt: physical; foundation: pillar). The palette, as one system:
   - elements keep the colours Glossary.ELEMENTS already gave them (fire #f08a55, water #68aee8, light,
     dark, earth, energy #6fd8e4 = Overcharge, love #ee95c0 = Eros); new elements by convention (ice pale
     cyan, wind/air pale green-white, nature green, sound #4fc1b0 and sight #62b6e8 from the old TINTS);
   - disciplines take their typed-slot hues brightened (SkillTab.GENERAL): martial #d27a70, specialist
     #82b86e, magical #a98bdb;
   - resources match their Reserve colours (stamina yellow-green #cce04d, mana, focus violet);
   - divine / holy / bless / radiant gold (Paladin/Sol family); curse and malevolent a sick violet-red;
     astral the Astral faction gold-cream; demon/abyssal the Demons faction crimson;
   - conditions with an identity take it (burning: fire; soaked, flood, submerged, drowning, aquatic:
     water; asleep: HUD.SLEEP; suspicion: HUD.SUSPICION; darkness: dark; overcharge: energy);
   - generic Glossary terms keep their kind colour (attack, save: check gold; foe, ally: target grey), so
     term links look as they did; the difficulty ladder (trivial ... impossible) runs green to red;
   - materials take their material's colour (iron, wood, glass...), stats a hue each.
4. **`mechanic.py tag ... --color "#rrggbb"`: required unless `--parent`** (a child inherits, no entry
   written). Not derived from the kind: a kind colour for every new tag would make the table grey mush.
   `mechanic.py color <word> "#rrggbb"` sets or changes any word's colour (one carried by things without
   a Glossary term, and retuning).
5. **`mechanic.py check` fails** a Glossary term, a PARENT parent, or any word on a .tres/.tscn with no
   colour of its own or through its parent; and a malformed colour.
6. **Trim: `Tags.mark(tags) -> StringName`, the first tag (parents expanded) with a colour that isn't in
   `Tags.PLAIN`** - materials, forms (ring, potion, book, blade...), weights, qualities (enchanted,
   honed), stats, generic categories (offensive, unique...). `Item.trim() -> Color` reads it (alpha 0:
   no trim). A new coloured tag marks items out of the box; a new plain word must join PLAIN. No
   override field: none needed by today's items; an emblem (Fire Insignia) carries its tag in tags.
   The hotbar stripe uses the same Tags.mark on a skill's tags (it was "first tag in TINTS").
7. **Where colour shows (no new text):** {k:term} links and {x:tag} words take Tags.color; damage
   floaters take the damage tag's colour; character sheet rows get a trim swatch; the unit card a small
   pennant per equipped item with trim; the unit's sprite a tiny banner with an insignia in its
   trinket's trim colour (trinkets only: one banner per unit, restraint).

## As built

(filled in below as stages land)
