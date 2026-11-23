# w16-ire: Ramut's Ire on a tree
User 2026-11-23: Ire belongs on Ramut's tree.
Found: Skills/ramuts_ire.tres on no tree (Battle._ire applies it on a stall); Ramut had a god file, pool only, no own tree.
Calls:
- New tree needed: Trees/ramut.tres (root "Ramut", tag physical, --human) via `role.py tree`, wired as Ramut's own Divinity tab in Gods/ramut.tres (same shape as Luun/Eros).
- Ire at tier 2: branch `after` Pray, as Luun's Level Down. Pray stays tier 1 via Role.shared (not a branch). Only skill on the tree, so no sibling to rank against; it is a rank-per-stall defeat of own concealment (a drawback-ish effect), so no higher.
- Hand-edited tree for an existing skill (skill.py new only makes new ones).
- Oddity for review: learned, Ire's effect lands on its holder (self ire = own concealment defeated); no cost/ap fields, system-applied. Left as is.
- Tests updated (Ramut now offers Divinity): god_slots_test.test_cleric/test_paladin, hogel_test.test_cleric. No new test: sweep + checks cover.
