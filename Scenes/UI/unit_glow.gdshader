shader_type canvas_item;

// A unit's glow: the radial gradient behind its sprite (Unit.glow). COLOR comes in as the gradient times the
// node's modulate, which Unit.set_glow() and the HUD set (side colour, strength, targeting): this shader only
// shapes it, and with every uniform at its default draws the plain glow, so targeting reads as it always did.
// One uniform per thing the glow can say, set through Unit.glow_param(); a new one is an addition here and a
// line in Unit, nothing else moves.

// Where the unit faces, for a viewer wise enough to read it (Unit.HEADING_SIGHT): a direction (screen space,
// y down) whose length is how much stronger the glow is on that side, a share of its alpha. Zero: even all round.
uniform vec2 heading = vec2(0.0);

// How much stronger the whole glow is: 1 plain, 2 at the flash of a level up (Unit.FLASH), settling back to 1.
uniform float flash = 1.0;
// How large the glow is, against the plain size: a little over 1 for a unit above the level of the viewer's
// side, under 1 below it (Unit.level_reach()). The quad itself grows, so the gradient isn't clipped.
uniform float reach = 1.0;

void vertex() {
	VERTEX *= reach;
}

void fragment() {
	COLOR.a *= flash;
	vec2 from_centre = UV - vec2(0.5);
	float strength = length(heading);
	if (strength > 0.0 && length(from_centre) > 0.001) {
		// 1 straight ahead, fading to nothing a little past square-on, so it leans rather than pointing
		float lean = smoothstep(-0.1, 1.0, dot(normalize(from_centre), heading / strength));
		COLOR.a *= 1.0 + strength * lean;
	}
}
