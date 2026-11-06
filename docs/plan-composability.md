# Plan: composable skills, rolls, tiles and attributes

*A design-and-architecture plan for the next stretch. Written because Gambeson is heading
toward many skills and effects with heavy interactions, short roguelike runs, and emergent
combos we didn't explicitly design. The goal is to make the common cases composable so new
content is data + small pieces, not new branches in `Battle.gd`. DRY where interactions
concentrate; KISS everywhere else. Index: `todo.md`. Open questions live in `docs/todo/`.*

## Where we are, honestly

The engine works and is well-tested (330 tests), but four systems have grown by accretion
and now resist new content:

1. **`Skill.gd` is a flag bag.** ~90 `@export` booleans/values, each read by a bespoke
   branch in `Battle.cast()` / `describe()`. Adding a mechanic means a new flag + a new
   branch in two places. Interactions between flags are implicit and untested. This is the
   single biggest drag on "add a skill in an afternoon."
2. **Rolls are scattered.** `d20 + mod vs Defense` (attack), `d20+mod vs d20+mod` (contest),
   the save variant, Level Down, Death, initiative, investigate — each is hand-rolled inline
   in `Battle.gd` with its own crit/advantage/bonus handling. The Glossary *names* them
   (Attack, Save, Contest, Check, Last Stand) but nothing in code enforces one definition.
3. **Tiles are single-layer.** One `Terrain` per cell in the TileSet, plus parallel dicts in
   `Battle` for snares/zones/earthworks/starpanes. There's no notion of a stack, so "leaves
   over the real ground" (and future tar/snow/water-over-X) has nowhere to live.
4. **Derived stats aren't a pipeline.** `max_hp` is a flat value on each unit; there's no
   function turning (con, level, class, rank) into HP. So Hardy, respec, Self-reflection,
   Humble and asphyxia each poke `refit()` or `max_hp` directly. Attribute-driven abilities
   (Actualization) have no clean seam.

None of these is on fire. All four are about to be asked to carry a lot more weight.

## The five seams, by leverage

Ranked by **(ease of win) × (long-term value)**. Each is independently shippable and
backward-compatible with the current tests.

### 1. `Check` — one roll resolver *(high value, medium ease — do first)*

A single value type + resolver for every d20 contest, mirroring the Glossary terms players
already read. One definition, one crit rule, one place to add advantage/bonuses/luck.

```
class Check:  # a d20 roll about to happen
    attacker, defender: Unit
    kind: Attack | Save | Contest | Check | LastStand   # the Glossary term
    stat: StringName           # whose/which mod drives the roll
    vs: int or Callable        # Defense, a DC, or the defender's own roll
    advantage, rank, flat: modifiers
Battle.resolve(check) -> Result { total, target, hit, crit, margin }
```

- **Why first:** every offensive skill, save, drag, grip, Level Down, Death and the Overlay
  forecast funnel through it. Fixes the "what do most offensive weapons act on?" question by
  construction: *Attack* always means `d20 + attack_mod(skill) + check_bonus(offensive)` vs
  `defender.defense(hit_tags)`. Players learn one rule and it holds everywhere.
- **Defense side** becomes equally legible: `defense(tags)` is the one number attacks target,
  already tag-aware (physical/magical). Standardizing the attack side lets us surface the
  forecast identically for every skill.
- **Migration:** wrap the existing inline rolls one call site at a time; the resolver returns
  the same numbers, so tests stay green. Delete the hand-rolled versions as they're covered.
- **Unlocks:** Elemental/Brutal/Decisive riders, crit-doubling, advantage sources, and later
  Affinity-on-rolls all attach to `Check` instead of re-deriving the roll.

### 2. Tile stacks — layered terrain *(high value, medium ease — do second)*

Make a cell a **stack** of terrain layers, top to bottom, instead of one `Terrain`.

```
Battle.stack[cell] : Array[TileLayer]   # topmost first
TileLayer: terrain + state (transparent?, turns_left, source)
```

- A layer may **mask** those beneath it: `masks := true` means lower layers don't present
  (their effects, their move cost, their concealment) and the unit interacts only with the
  top. Leaves mask; a snare under leaves is hidden until the leaves clear.
- Resolution order for "what happens when U is here" walks the stack top-down, stopping at the
  first masking layer, composing the rest. The tile panel reads the same walk.
- The parallel `snares/zones/earthworks/starpanes` dicts collapse into layers over time (not
  required for v1 — new layers go through the stack; old dicts can stay until migrated).
- **Leaves** become the proof of concept, and the template for tar, snow, shallow water:
  - `+0.1` enter cost; `masks` the stack (obscures what's below).
  - Checks the hidden tile imposes are rolled at **disadvantage** (you can't see the trap).
  - **Advantage to concealment** checks while in them.
  - `transparent` while a unit stands on the cell — reveal the layer below for that unit.
  - `flammable`: a `fire`-tagged hit converts the layer to a Flame layer.
  - `windswept`: a `wind`-tagged hit removes the layer.
  - Flammable/windswept generalize to a **reaction** list on a layer: `[damage_tag -> become
    | remove]`, which is the first bite of the effect-composition idea below.

### 3. Skill behaviours — from flags toward verbs *(highest value, lowest ease — incremental)*

The big one, and the reason runs will feel fresh. Don't rewrite `Skill.gd` — **grow a second
spine beside the flags** and move mechanics onto it as they're touched.

```
class Behaviour:   # one composable verb a skill performs
    func apply(ctx: Cast) -> void
    func describe(ctx) -> String        # its own Glossary markup, so DRY with execution
Skill.behaviours: Array[Behaviour]      # runs in order; flags lowered as they migrate
```

- `Cast` carries caster, target(s), rank, the `Check` result, and a scratch bag behaviours
  read/write — so "deal damage", "then heal the overage" (Irradiate), "then burn" (Sol) chain
  without knowing about each other. This is where **emergent combos** come from: a behaviour
  reacts to the `Cast` bag, not to a named skill.
- **describe() co-locates with apply()** — the current bug risk (a skill does X but says Y)
  disappears because one object owns both. The Glossary markup helpers already make this cheap.
- **Migration policy:** new skills author behaviours; when a flag's branch is edited for any
  reason, lift it into a behaviour and delete the flag. No big-bang. Target the dense clusters
  first: the Strike chain (already semi-isolated in `_chain`), damage+rider skills (Smite, Sol,
  Irradiate), and heals.
- **KISS guard:** a behaviour is only worth extracting when ≥2 skills share it or it reacts to
  another. One-off mechanics stay as a flag until a second user appears (the "lore keeper"
  hybrid, Q8).

### 4. Context tags — offensive / defensive / supportive *(medium value, high ease)*

Make the use-context a first-class, derived tag so Affinity, Reckless Abandon and future
"while defending" bonuses compose.

- At cast time, tag the `Cast` with its posture: **offensive** (used to attack an enemy),
  **defensive** (to protect oneself), **supportive** (to help an ally). Derived from
  target+intent, per the Berserker spec — *any* skill is all three depending on use.
- A skill's authored tags still apply always; the context tag applies for this use only.
  Investing points "under certain circumstances" (Berserker) = a per-context rank, read when
  the `Cast`'s posture matches.
- **Why high ease:** it's a pure function of (caster, skill, target) and plugs into `Check`
  (offensive) and the rank-cost function (Affinity) without touching execution.

### 5. Derived-stat pipeline — attributes → HP, slots, respec *(medium value, medium ease)*

One ordered pipeline from base attributes to final stats, so attribute-driven features stack
instead of fighting over `refit()`.

```
Unit.derive():
    stats  = base ± respec ± buffs/curses (level effects)
    max_hp = hp_formula(con_mod, level, class_tag, hardiness_rank)   # see below
    then the existing refit() bonuses (max_hp effects, asphyxia, humble) apply on top
```

- **HP formula (new, replacing flat `max_hp` for class units):**
  `((con_mod · (1 + hardy_rank)) + class_base) · level`, where `class_base` is 1 for
  base-tag casters, 2 for specialists/generalists, 3 for martialists, and `hardy_rank` is 0
  unless Hardy multiplies the con scaling. Hand-authored bosses keep their flat `max_hp`
  (a `max_hp` override wins), so golems/uniques aren't disturbed.
- **Respec / Self-reflection / Meditate** then become: edit `base` (within ±rank) and
  re-`derive()`. Self-knowledge (info levels on oneself) gates the respec UI. Hardy is just
  `hardy_rank > 0` feeding the formula. All four stop poking `max_hp` directly.
- **Open:** the exact class_base per tag and whether respec is combat-only need a confirm
  (see the backlog). The formula above is the one from the Berserker/Hardy brief.

## Roll philosophy — attack vs defence vs world

The thing that makes rolls *feel* like one system rather than three:

- **Attack (offensive):** the player's lever. `d20 + their mod + their bracing` vs a defender
  number they can forecast. Always visible, always the same shape. Most weapons/offensive
  skills act on **the attacker's governing mod vs the defender's `defense(tags)`** — one
  contract. Riders (crit, element, brutal) modify the *result*, never the *shape*.
- **Defence:** a number to understand and invest in, not a roll to sweat each hit — set by
  armor weight + dex/con + bracing + tagged bonuses (robe's wis-as-magical, Hydera's +1). The
  player builds it up; the attacker rolls against it. This asymmetry is deliberate: offence is
  active and swingy, defence is a stat you grow.
- **World / social rolls** (checking an ally isn't full of themselves, seeing through a
  persona, reading the board): these are the risky ones for *feel*. Guidelines:
  - **Fun when:** the roll gates *information or opportunity* (you learn something, or get an
    opening), and failure costs a turn/tempo, not your build.
  - **Frustrating when:** it's adversarial to your own team with no upside, or a point sink
    that can whiff. So world rolls should mostly be **checks you passively accrue** (perception
    tiers, info levels) rather than active gambles — and where they're active (Coordinate,
    Personify), success should *add* rather than failure *punish*.
  - **The "unless it's funny" clause:** teammate-adversarial outcomes are fine when they're
    comedic and low-stakes (a bard's botched boast), not when they tax a serious build.
  - Self-reflection/Meditate lean into the *good* version: you roll to know yourself, and
    knowing yourself lets you respec — strictly upside, paid in AP+movement.

## Backlog — this batch, sequenced

Each item maps to the seam it rides on. ✅ = shipped this pass.

**Do-now, low-risk (shipped this pass):**
- ✅ Adventurer stats 16 across the board (Actualization sandbox).
- ✅ Robe is unique: no dex for defence, +wis mod as magical defence (Q47).
- ✅ Item `rarity`; mundane armor common, effect-bearing armor rare; `Loot` weights by it.
- ✅ Boss commanders in heavy armor where it fits (Alabaster → Brigandine).
- ✅ Confirm Fighter/Paladin already start in medium (half plate); kept.

**Seam 5 — derived stats:** Hardy, the HP formula, respec. Blocks Actualization t3 and Hardy.
- Actualization tree (Martial-category): t1 **Self-reflection** (rank info levels on self),
  t3 **Meditate** (AP paid with movement *and* AP; info levels; respec ±rank per stat, modal).
- **Hardy** passive (Alabaster borrows): multiply con HP-scaling by rank via the formula.

**Seam 4 + 3 — context tags + Affinity:** the Berserker.
- 3 martial-prowess tabs + a Berserker class tab.
- **Reckless Abandon** trait: skip defensive/support skills; **Offender** (+1 offensive
  Affinity), **Unsupportive** (−1 supportive), **Indefensible** (−1 defensive).
- **Affinity → rank-cost:** `−1↓: n^(2−eff)`, `0: n²`, `+1: n·log n`, `+2: n`. Re-costing
  live in combat may rank a skill up/down immediately.

**Seam 2 — tile stacks:** layerable terrain + **Leaves** as the template (flammable, windswept,
transparent-while-stepped, mask, disadvantage on hidden checks, advantage to concealment).

**UX (mostly independent of the seams):**
- Remove the "too far to hear you" tip; instead **gray out** the hotbar/ineligible orders and
  **raise the prominence** of commandable units.
- Commanded units **desaturate progressively** (100%→50% sat, then grayscale when tapped).
- **Default orders** for low-info commanders (0 cha XOR low wis/info): ATTACK / DEFEND / HELP,
  shown only if the unit has a relevant skill; all three with `?` when `cmdr wis mod + report
  cha mod ≤ −5`; an ineligible pick wastes the order and locks that unit for the faction turn.
- **Tile panel:** hide `Move 1`; render move cost as a **walker pictogram** + signed number
  (`🚶 −2`) not "Mv"; suspicious tiles end their list with `?` (after the move cost); drop the
  `Effects:` header row.
- **Suspicious-tile overlay:** translucent grit for disturbed earth; translucent `?` placeholder
  elsewhere.
- **Accessibility options:** "all suspicious tiles use `?`"; "high contrast" (double allied glow,
  thicker faction borders, full-white body text).

## Principles to hold the line

- **New content is data + a behaviour, never a new `Battle` branch** once a seam exists.
- **Describe where you execute** — one object owns both, so the tooltip can't lie.
- **Migrate on touch** — don't refactor cold; lift a flag into a seam when you're already in it.
- **Name it in the Glossary first** — if players will read it, it's a term before it's code.
- **A combo you didn't design is a feature.** Behaviours react to the `Cast` bag, not to each
  other by name, so interactions emerge instead of being enumerated.
