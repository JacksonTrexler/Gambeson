# Recovery: Energize, burnout (Recovery Endurance), Heal and Megaheal

The user's design (verbatim):

> Energize is a basic AP -> energy t4 general skill. no energy cost but quite expensive AP cost. Grants 1
> energy per 2 AP spent, up to rank energy can be puchased. May overcharge by 20% * rank total resource
> (mana, stamina, sweet nothings + energy etc.)
> General mechanic burnout: units recovering energy from means other than waiting or resting will
> eventually burn out. This is deferred by con mod recovery uses. Con mod deferall only recovers mid-combat
> if unit rests at full resource. con mod deferall is (`Recovery Endurance` or RE). Units that recover
> energy or health without remaining RE pass con checks or lose (10% * (1 + abs(RE)) * recovered resource/
> (recovered hp over RE threshold trigger), it goes negative))) max hp/resource. Basically units that abuse
> recovery mechanics without sufficient constitution will gradually lose maximum HP / resource. For any
> singular heal, units healed above con mod * 20% health in a single skill use make a con check against the
> difference. -1 RE on a failure. Reenergizing *always* consumes RE.
> t8 cleric, life, love domain general: Heal: Applies a medium heal + caster mod + rank. Megaheal: Applies a
> very large heal + caster mod + rank. More expensive than Heal

## Readings and calls (written before building)

1. **One place.** Every recovery that isn't regen already passes `Unit.heal()` (HP) or
   `Unit.grant_energy()` (Energy). Both now report what actually came back through one signal,
   `Unit.recovered(u, pool, n)`; Battle listens and hands it to `Scripts/Burnout.gd`, the rule's one
   home (the rolls need Battle's rng: `Battle.resolve()`). A future heal or grant joins by calling
   `heal()`/`grant_energy()`; one that fills something else calls `Unit.note_recovery(pool, n)`.
   Regen (`recover()`) never reports. Outside a battle nothing listens: no burnout out of combat.
2. **RE** (`Unit.endurance`): starts each battle at max(con mod, 0) (*call*: no floor above 0 - a con 10
   unit has none to spare; negative con doesn't start in debt). Its card shows "RE n".
3. **Energy grants always spend 1 RE**, once per grant, even at 0 or below (so it runs negative).
   Reserve restores (a Mana potion) and Overcharge count as Energy: "energy replacements". A grant that
   gives nothing (full bar) spends nothing.
4. **Depleted** (RE 0 or below as a recovery starts): a con check (d20 + con check mod, DC 12, the flat
   `standard` rung: *call*). Failing cuts the max of that pool by 10% x (1 + |RE|) x the amount
   recovered, rounded, at least 1, and an HP recovery takes 1 RE more (an Energy one has already spent
   its 1). *Departure:* the parenthetical "(recovered hp over RE threshold trigger)" is read loosely: HP
   loss is reckoned on all the HP recovered, as Energy's is, so small heals still burn a depleted unit.
5. **Big single heal**: healed more than max(con mod, 0) x 20% of max HP in one heal, a con check with DC
   = the excess (*call*: the raw HP number, no 10 +). Failing: -1 RE.
6. **Refill**: on a resting turn ended with its Energy (or the reserve it runs on) full, RE goes back to
   its starting value (*call*: all of it, not +1).
7. **Lost max lasts** (*call*): `Unit.burnt` (pool -> points) sits on the unit past the battle - "gradually
   lose maximum HP". HP is cut in `refit()` (the derived-stat pipeline), Energy straight off
   `max_energy`, a reserve in `pools()`. The card shows "-n burnt" beside HP / EN / a reserve.
8. **Energize** (`--human`): tier 4 on the base General tree, 0 Energy, 2 AP (one pair); then it spends
   every further pair of AP it can, up to rank pairs in all (*call*: the smallest clear control - no
   amount picker), only as many pairs as there is room for. Each pair gives 1 Energy (`grant_energy`:
   Power to a powered unit); past a full bar, the rest is Overcharge, up to 20% x rank of its total
   resource (max Energy + every reserve's max) held at once, for rank turns.
9. **Heal / Megaheal** (`--human`): Cleric's only love/healing tree is Eros (`Trees/eros.tres`, "Divinity:
   Eros"); there's no life tree. Both on Eros at branch tier 8. One shared behaviour
   (`Behaviours/heal.gd`): heals the skill's tier dice x its `dice_scale` magnitude + its tier stat's mod
   + rank. Heal: 1d8 x moderate (1.5 x rank, rounded up) + wis mod + rank, 4 AP, 4 Energy. Megaheal:
   1d8 x extreme (3 x rank) + wis mod + rank, 6 AP, 9 Energy. Range 3 (*calls*). wis: the Cleric's
   swaps put cha/int on wis.
