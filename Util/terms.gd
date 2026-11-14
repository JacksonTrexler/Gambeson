extends SceneTree

# Reports on skill terms (SkillTerms), run by Util/skill.py: information, never a failure.
#   godot --headless --path . -s Util/terms.gd -- drift       hand-set AP / cost vs the cost calculator's (Pricing), at rank I
#   godot --headless --path . -s Util/terms.gd -- modifiers   skills no modifier is eligible for, and why (Modifiers.why_not())
#   godot --headless --path . -s Util/terms.gd -- terms <id>  one skill's terms


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
		if not s.priced and (ap != s.ap or cost != s.price(1)):
			off += 1
		print("%-22s %-14s %-18s %s%s" % [_id(s), "-" if s.priced else hand, "%s/%d" % [Skill.num(ap), cost], Skill.num(snappedf(Pricing.points(s, 1), 0.1)), " *" if s.priced else ""])
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


func _terms(s: Skill) -> void:
	var t := SkillTerms.of(s)
	print("%s: intensity %s, impact %s, penalty %s, damage %s, check %s, conditions %s, ground %s" % [_id(s), t.intensity, t.impact, t.penalty, t.damage, t.check, t.conditions, t.ground])
	for c in SkillTerms.CHANNELS:
		print("  %s: %s" % [c, ", ".join(t.channels[c])])
	for x in t.contingencies:
		print("  contingency: %s (share %s%s)" % [x[0], Skill.num(snappedf(x[1], 0.01)), ", helps" if x[2] else ""])
	print("  points %s -> AP %s, cost %d" % [Skill.num(snappedf(Pricing.points(s, 1), 0.1)), Skill.num(Pricing.ap(s, 1)), Pricing.energy(s, 1)])
	print("  modifiers: %s" % ", ".join(Modifiers.words().filter(func(w): return Modifiers.eligible(w, s))))
