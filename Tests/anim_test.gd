extends Test

# Unit animation states (Unit.ANIMS, animate(); frames from Util/anim.py, requirements.md "Animation"):
# a state plays its animation, else waiting, else default (a lone base image); a one-shot comes back
# to waiting. Its pace (anim_pace(), moods()): wounded and slowed play slower, hasted and frightened faster.


func frames(names: Array) -> SpriteFrames:
	var f := SpriteFrames.new()
	var tex: Texture2D = v(1).sprite.sprite_frames.get_frame_texture(&"default", 0)
	for n: StringName in names:
		if n != &"default":
			f.add_animation(n)
		f.set_animation_loop(n, n in [&"default", &"waiting"])
		f.add_frame(n, tex)
	return f


func test_state_picks_animation() -> void:
	villagers_only()
	var u := soak(v(1))
	var was := u.sprite.sprite_frames
	var lone := frames([&"default"])
	u.sprite.sprite_frames = lone
	ok(u.animate(&"attacking") == &"default" and u.animate() == &"default", "a lone base image plays for every state")
	u.sprite.sprite_frames = frames([&"default", &"waiting", &"attacking", &"hit"])
	ok(u.animate(&"investigating") == &"waiting", "a state its frames lack: it waits")
	ok(u.animate(&"attacking") == &"attacking", "attacking plays its own")
	u.hit(3.0, [])
	ok(u.sprite.animation == &"hit", "a blow that lands plays hit")
	u.sprite.animation_finished.emit()
	ok(u.sprite.animation == &"waiting", "a one-shot over: back to waiting")
	v(3).learned.append(slot(strike)); v(3).sync_bar()
	stage(nemes, {u: Vector2i(4, 3), v(3): Vector2i(5, 3)})
	ok(b.cast(v(3), strike, u) and u.sprite.animation in [&"hit", &"waiting"], "cast on: it reels or waits")
	v(3).sprite.sprite_frames = u.sprite.sprite_frames
	v(3).refresh()
	ok(b.cast(v(3), strike, u) and v(3).sprite.animation == &"attacking", "a cast: the caster strikes")
	u.sprite.sprite_frames = was
	v(3).sprite.sprite_frames = was


func test_pace_from_moods() -> void:
	villagers_only()
	var u := soak(v(2), 20)
	u.timed.clear()
	ok(u.moods().is_empty() and is_equal_approx(u.anim_pace(), 1.0), "fresh: plain pace")
	u.hp = 9
	ok(u.moods() == [&"wounded"] and u.anim_pace() < 1.0, "under half its HP: wounded, slower")
	u.hp = 20
	u.afflict(effect("movement", -2), 3)
	ok(u.moods() == [&"slowed"] and u.anim_pace() < 1.0, "a status lowering movement: slowed, slower")
	u.timed.clear()
	u.afflict(Unit.HASTE, 3)
	ok(u.moods() == [&"hasted"] and u.anim_pace() > 1.0, "Haste: hasted, faster")
	u.afflict(effect("fear", 1), 1)
	ok(&"frightened" in u.moods() and u.anim_pace() > Unit.ANIM_PACE[&"hasted"], "frightened on top: faster still")
	u.animate()
	ok(is_equal_approx(u.sprite.speed_scale, u.anim_pace()), "the sprite plays at its pace")
	u.timed.clear()
