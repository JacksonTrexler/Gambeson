# Stamina, and exhaustion by tree

The user's ruling (verbatim):

> if a task is from a caster, martial, specialist tree, it should inherit as such as a tag
> truly general skills applies less exhaust on *everything*
> passive Stamina: Stamina as a resource: more fit specialists get it like rogue and ranger general class trees as well as agile prowesses / berserkers. Stamina base property is it cuts exhaustion / rank+1. Stamina is yellow tinted green.
> It can't be used for most caster skills.
> Adventurers don't need stamina to leverage additional skill effects using the tag (e.g. move rank additional tiles if paid with stamina), but not the benefits of stamina itself as those are provided by the passive and resource itself.

Builds on `docs/plans/exhaustion.md`.

## Readings and calls (written before building)

1. **Kind by tree.** A skill's kinds are derived once, at first ask, from every tree it sits on
   (`Skill.kinds()`): the tag of each class root holding it (`SkillRoot.tag`), the category of each
   general tree (`SkillTab.category`), `general` for the base General tree. A skill on no tree (listed
   outright or innate only - Hex; a monster's Sing) keeps its own category tags. Tree beats tag: Strike,
   tagged martial but on the base General tree, is general.
   - *Call:* a skill on trees of two kinds (Snare, First Aid: specialist roots and the Druid's magical
     Sylvan) gets both, as the exhaustion plan's call 2 already said: it shares with either kind, and any
     one qualifying kind lets a reserve pay for it. A per-holder reading (the tree that unit learned it
     on) would be finer but isn't derivable at load.
   - *Call:* the kinds are not written into `Skill.tags`. "Inherit as a tag" is read as: wherever the
     rules ask a skill's broad kind - exhaustion sharing, which reserves may pay (`Reserve.only`), what
     Energy counts as (`energy_as`) - they ask `Skill.tagged()`, tags plus derived kinds. Typed slots,
     the skills screen, damage tags and the rest still read the .tres tags. A consequence: mana now pays
     for the Sol and Eros skills a Wizard holds (they're magical by tree).
2. **General skills.** A general skill's use counts `GENERAL` 0.25 against every other skill,
   one way (other skills' uses don't weigh on it beyond its own). *Call:* 0.25, half the same-kind share,
   because it lands on every skill rather than one kind's, and four uses (one Strike III turn's worth
   at most is one) add one use to everything, which one turn's recovery clears.
3. **Stamina, the reserve** (`Reserves/stamina.tres`): yellow tinted green `Color(0.8, 0.88, 0.3)`.
   `only`: martial, specialist, general, physical - it pays for anything of those kinds and no purely
   magical skill. *Call - the exceptions ("most caster skills"):* a magical skill also tagged
   `physical` (a body-borne blow: Waterstrike, Terestera) can be paid with stamina; none else.
4. **Stamina, the passive** (`Skills/stamina.tres`, `--human`): gives the reserve, max
   (con mod + 2) x rank (*call*: `Reserve.base` 2, a new Reserve field, so a con-10 Rogue still gets 2 at
   rank I), and the Effect stat `stamina` 1 a rank: the holder's exhaustion counts (the uses weighing on
   each skill) are divided by rank + 1. The reserve fills at battle start like every reserve; nothing
   refills it mid-battle (*call*).
   - *Who:* the Rogue's own tree (root Blade), the Ranger's own tree (root Scout), the Fury root (the
     Berserker's, and a Paladin's Fury Prowess), and the Slayer root (a Paladin's Slayer Prowess).
     *Call:* Slayer is the agile Prowess (Gank, Jugular, Silent Strike: quick, light finishing);
     Fury is the Berserker's own rage (Frenzy, Second Wind) - "berserkers". Protector, Vanguard, Brawn
     and Havoc are heavy or commanding. Slayer is a shared root, so a Fighter's Slayer offers it too (a
     side effect of keeping it data on the root).
5. **Paying with stamina.** *Call:* automatic - stamina is a reserve dedicated to tags (`only`), so the
   existing `Unit.funding()` order already spends it before Energy, as mana is for magical skills.
   Nothing in the HUD offers a choice of payment today (every reserve is picked automatically and the
   cost forecast names it: "2 AP, 1 Stamina"), so this is the smallest clear choice.
6. **The `stamina` tag and Move.** There is no Move skill (walking is native), so the proof is a new
   active skill **Move ??** on the base General tree, tier 1: 2 AP, 1 cost, on itself, tagged `stamina`;
   it gains rank tiles of movement this turn (move AP and stride), and rank more if paid with stamina.
   Behaviour `Behaviours/move.gd`; whether a payment counted as stamina is `Unit.paid_as()`, from what
   `pay_for()` last used.
7. **Adventurers.** Their innate Field Experience (martial) and Everyman (specialist) already make Energy
   count as another reserve for skills of those kinds (`energy_as`, `Unit.pays_as()`); with stamina in
   play that reserve is stamina, so an Adventurer paying Energy gets a `stamina` skill's extra effect.
   *Call:* a general skill counts as whatever kind an Energy-as passive names, so an Adventurer's Move
   gets it too. The exhaustion cut is the passive's alone: an Adventurer gets it only by learning Stamina
   (it isn't on the Adventurer's trees, so as things stand it can't).

## As built

(filled in after building)
