# Cost identity: cost profiles over the computed price (w2-cost, 2026-11-18)

The user (?131): "skill cost is part of its identity (ap heavy / resource heavy / specific resource needed or
preferred). Skills *should* have an algorithm they can use looking at which tags are included, which
parameters are scaled how far (rank may scale cost, potentially a lot) as a baseline. Consider expanding
how skill costs can be configured. a natural language description: "high mana cost, low ap cost" should be
trivial for a sonnet or haiku model to implement via skill".
Read: skill-modifiers.md, param.md, param-rest.md, ai-prices.md, Pricing.gd, SkillTerms.gd, Util/skill.py.

## Readings and calls (for review)

1. **Baseline = Pricing's points.** The computed price (Pricing.points(): intensity, tags/terms, rank
   and stat scaling, contingencies) stays every skill's budget. A profile only skews how that budget is
   spent: AP against the resource cost, which resource, and how steeply rank grows it. No TABLE number
   changes, so no balancing.
2. **Stored as words, in place of `priced`.** `Skill.priced: bool` becomes `Skill.costs: String`, the
   profile as written ("high mana, low ap"); "" = hand-priced (ap/cost as set), as `priced = false` was.
   `Skill.priced()` is now a func. Field count unchanged (103); FLAG_CEILING 104 -> 103, the true count
   (the `inherent` field already went). A declarative field every skill shares, replacing one: no net flag.
   The three priced skills (poach, skeleton, warcry) become `costs = "even"` (the baseline), priced exactly as before.
3. **Vocabulary** (Pricing.TABLE `levels`, `dims`, `rank`; mirrored in skill.py, which checks them):
   - clauses split on commas, ";" and "and": each is `[level] [only|needs|prefers] <dimension>`, or
     `<flat|scaled|steep> rank`, or `even`. Filler words "cost", "costs" after a dimension are ignored
     ("high mana cost, low ap cost" reads as "high mana, low ap").
   - levels: none / no / free 0; low / light / cheap 0.5; moderate / medium / normal / even 1 (also the
     default with no level); high / heavy 1.5; very high / very heavy 2.
   - dimensions: `ap`; the resource cost: `cost` / `energy` / `resource` (whatever pays, by its tags), or a
     reserve by id: `mana`, `stamina`, `focus`, `sweet_nothings` ("sweet nothings" too).
   - a reserve named plainly or with `prefers`: **preferred**: `Unit._funding()` tries it first (after a
     needed one) when its holder has it and it can pay (a generic hook: the skill's identity, read off
     the profile). `only` / `needs`: **needed**: written as the existing `Skill.needs` field by the tool
     (one source at run time; check keeps them in step).
   - at most one resource (a skill has one cost); `health` / `hp` / `life` are refused: no HP costs exist yet
     (a mechanic for new-mechanic first).
   - unstated dimensions are moderate (absolute, not complementary: "high mana" alone is dearer overall;
     "high mana, low ap" spends the same budget differently). Call: absolute words, so a model writes what it reads.
4. **Weights to costs.** With p(r) = points at rank r under its modifiers, rank growth g (flat 0, scaled 1,
   steep 2): q = p(1) + g x (p(r) - p(1)); **AP = clamp(round(ap_base + q x ap_per x w_ap), 1, ap_max)**,
   **cost = round(q x energy_per x w_cost)** (round half away from zero, as before). "even" reproduces the old
   priced rule exactly. "none ap" still costs ap_base (1 AP, the floor for an active).
5. **Rank.** Rank already scales the baseline where a skill's terms scale (dice by rank, per-rank hit and
   damage, other per-rank terms). `steep rank` doubles that growth past rank I; `flat rank` prices every rank
   as rank I (what a flat hand cost is). Call: a rank word on the whole price, not per dimension (small).
6. **Migration (mechanical, no balancing).** `godot -s Util/terms.gd -- infer` tries every hand-priced active
   (not cost_per_rank, not hybrid) against every level pair (and a `flat rank` where its points grow with
   rank), keeping a profile only if it reproduces the hand AP and cost **exactly at every rank 1..max (5 if
   uncapped)**; `skill.py migrate` writes those with `skill.py cost`. Anything else stays hand-set (listed below).
   Resource word: `only <reserve>` where it has `needs`; otherwise the generic `cost` (no preference written,
   so funding order is unchanged). Under emblems a migrated skill now prices via the profile instead of
   hand x points ratio: small differences, only with emblems on (call: accepted as rounding).
7. **Tool.** `skill.py new --cost "high mana, low ap"` (default "even"; `--hand-priced --ap 4 --cost 2`
   still sets a hand price: with --hand-priced, --cost is a number) and `skill.py cost <id> "<profile>"` (or
   `skill.py cost <id> hand --ap 4 --points 2` to go back): writes
   `costs`, drops the hand ap/cost lines, sets or clears `needs` to match `only`, prints AP and cost at ranks I-III.
   `check` parses every profile and checks `only X` against `needs`.

## Tests (one per seam)
- `modifiers_test.test_priced` updated: `s.costs = "even"` for `s.priced = true`.
- New `Tests/costs_test.gd`: profile -> cost table test (words to weights, AP/cost at ranks, steep/flat,
  synonyms, refusals); every skill's profile parses and its named reserve can pay it; preference in funding.
- skill.py check: profile parse + only/needs (tool check).
- Mutations: listed in "As built".
