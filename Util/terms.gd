extends SceneTree

# Reports on skill terms (SkillTerms), run by Util/skill.py: information, never a failure.
#   godot --headless --path . -s Util/terms.gd -- drift       hand-set AP / cost vs the cost calculator's (Pricing), at rank I
#   godot --headless --path . -s Util/terms.gd -- modifiers   skills no modifier is eligible for, and why (Modifiers.why_not())
#   godot --headless --path . -s Util/terms.gd -- density     skills Density can't trade on (SkillTerms.density_why()) and their declared reason
#   godot --headless --path . -s Util/terms.gd -- density-check   the same, as problems: an ineligible skill with no Skill.no_density, or one declared that is eligible
#   godot --headless --path . -s Util/terms.gd -- terms <id>  one skill's terms
#   godot --headless --path . -s Util/terms.gd -- infer       hand-priced actives a cost profile reproduces exactly at every rank (docs/plans/w2-cost.md)


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var mode: String = args[0] if not args.is_empty() else "drift"
	var skills: Array[Skill] = []
	for f in ResourceLoader.list_directory("res://Skills/"):
		if f.ends_with(".tres"):
			var s: Skill = load("res://Skills/" + f)
			if s and not s.stub:
				skills.append(s)
	match mode:
		"drift":
			_drift(skills)
		"modifiers":
			_modifiers(skills)
		"infer":
			_infer(skills)
		"density":
			_density(skills, false)
		"density-check":
			_density(skills, true)
		"terms":
			for s in skills:
				if args.size() > 1 and s.resource_path.get_file().get_basename() == args[1]:
					_terms(s)
	quit(0)


static func _id(s: Skill) -> String:
	return s.resource_path.get_file().get_basename()


func _drift(skills: Array[Skill]) -> void:
	print("skill                  hand AP/cost   computed AP/cost   points  (rank I; priced skills marked *)")
	var off := 0
	for s in skills:
		if s.passive and not s.hybrid:
			continue
		var ap := Pricing.ap(s, 1)
		var cost := Pricing.energy(s, 1)
		var hand := "%s/%d" % [Skill.num(s.ap), s.price(1)]
		if not s.priced() and (ap != s.ap or cost != s.price(1)):
			off += 1
		print("%-22s %-14s %-18s %s%s" % [_id(s), "-" if s.priced() else hand, "%s/%d" % [Skill.num(ap), cost], Skill.num(snappedf(Pricing.points(s, 1), 0.1)), " *" if s.priced() else ""])
	print("drift: %d hand-priced skill%s differ from the calculator (information, not a failure)" % [off, "" if off == 1 else "s"])


func _modifiers(skills: Array[Skill]) -> void:
	var none := 0
	for s in skills:
		var t := SkillTerms.of(s)
		var ok := Modifiers.words().filter(func(w: StringName): return Modifiers.eligible(w, s))
		if ok.is_empty():
			none += 1
			var why: PackedStringArray = []
			for w in [&"rho_up", &"rho_down", &"sigma_down", &"sigma_up", &"lambda_up"]:
				why.append("%s: %s" % [Modifiers.SYMBOLS[w][0], Modifiers.why_not(w, s)])
			why.append("tags: no damage, check, effects or tile")
			print("%-22s %s" % [_id(s), "; ".join(why)])
		elif not t.scales():
			print("%-22s tags only (%s): no rank or stat scaling for a symbol" % [_id(s), ", ".join(ok.filter(func(w): return w not in Modifiers.SYMBOLS).slice(0, 4))])
	print("modifiers: %d skill%s eligible for no modifier at all - parameterize them (docs/plans/skill-modifiers.md)" % [none, "" if none == 1 else "s"])


# Density's eligibility, the one rule (SkillTerms.density_why()) against each skill's declared reason
# (Skill.no_density): a report, or (problems) only where the two disagree.
func _density(skills: Array[Skill], problems: bool) -> void:
	var off := 0
	for s in skills:
		var why := SkillTerms.of(s).density_why()
		if problems:
			if why and not s.no_density:
				print("Skills/%s.tres: Density can't trade on it (%s): parameterize it, or say why in no_density" % [_id(s), why])
			elif s.no_density and not why:
				print("Skills/%s.tres: no_density says \"%s\", but Density fits it (trades %s): clear it" % [_id(s), s.no_density, ", ".join(SkillTerms.of(s).trades())])
		elif why:
			off += 1
			print("%-22s %-55s %s" % [_id(s), why, s.no_density if s.no_density else "(no reason declared)"])
	if not problems:
		print("density: %d skill%s ineligible for Density and Diluted (docs/plans/w4-density.md)" % [off, "" if off == 1 else "s"])


func _terms(s: Skill) -> void:
	var t := SkillTerms.of(s)
	print("%s: intensity %s, impact %s, penalty %s, damage %s, check %s, conditions %s, ground %s" % [_id(s), t.intensity, t.impact, t.penalty, t.damage, t.check, t.conditions, t.ground])
	for c in SkillTerms.CHANNELS:
		print("  %s: %s" % [c, ", ".join(t.channels[c])])
	for x in t.contingencies:
		print("  contingency: %s (share %s%s)" % [x[0], Skill.num(snappedf(x[1], 0.01)), ", helps" if x[2] else ""])
	print("  points %s -> AP %s, cost %d" % [Skill.num(snappedf(Pricing.points(s, 1), 0.1)), Skill.num(Pricing.ap(s, 1)), Pricing.energy(s, 1)])
	var by_rank: PackedStringArray = []
	for r in range(1, 4):
		by_rank.append("%s: %s AP, %d cost" % [Skill.roman(r), Skill.num(Pricing.ap(s, r)), Pricing.energy(s, r)])
	if s.priced():
		var p := Pricing.profile(s.costs)
		print("  profile \"%s\"%s -> %s" % [s.costs, (" (%s)" % p[&"error"]) if p[&"error"] else "", "; ".join(by_rank)])
	else:
		print("  hand-priced: %s AP, %s cost (as a profile \"even\" it would be %s)" % [Skill.num(s.ap), s.price(1), "; ".join(by_rank)])
	print("  density: %s" % ("trades rank impact against %s" % ", ".join(t.trades()) if not t.density_why() else "%s (%s)" % [t.density_why(), s.no_density if s.no_density else "no reason declared"]))
	print("  modifiers: %s" % ", ".join(Modifiers.words().filter(func(w): return Modifiers.eligible(w, s))))


# Hand-priced actives (not cost x rank, not hybrids) whose AP and cost a profile reproduces exactly at
# every rank 1..max (5 uncapped): "<id>\t<profile>" each, for skill.py migrate; the rest "<id>\t-".
const LEVELS := [[0.0, "no"], [0.5, "low"], [1.0, ""], [1.5, "high"], [2.0, "very high"]]


func _infer(skills: Array[Skill]) -> void:
	for s in skills:
		if s.passive or s.priced() or s.cost_per_rank:
			continue
		var top := s.max_rank if s.max_rank > 0 else 5
		var found := ""
		for flat in [false, true]:
			for a in LEVELS:
				for c in LEVELS:
					var text := _profile_text(s, a, c, flat)
					s.costs = text
					var same := true
					for r in range(1, top + 1):
						if Pricing.ap(s, r) != s.ap or Pricing.energy(s, r) != s.price(r):
							same = false
							break
					s.costs = ""
					if same and not found:
						found = text
		print("%s\t%s" % [_id(s), found if found else "-"])


static func _profile_text(s: Skill, a: Array, c: Array, flat: bool) -> String:
	var out: PackedStringArray = []
	if a[1]:
		out.append("%s ap" % a[1])
	var res := "cost"
	if s.needs:
		res = s.needs.resource_path.get_file().get_basename().replace("_", " ") + " only"
	if c[1] or s.needs:
		out.append(("%s %s" % [c[1], res]).strip_edges())
	if flat:
		out.append("flat rank")
	return ", ".join(out) if out else "even"
