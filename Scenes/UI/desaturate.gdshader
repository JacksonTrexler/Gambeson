shader_type canvas_item;

// Drains a sprite's colour toward grey of the same brightness: 1.0 full colour, 0.5 half, 0.0
// greyscale. The HUD turns it down a little on the player's units as their AP runs low, and all the
// way once they can't take another order this turn (Unit.set_saturation(), HUD.command_sat()).
// COLOR comes in already holding the texture times the node's modulate: sampling the texture again
// would square every colour, darkening the sprite.
uniform float saturation : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float grey = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = mix(vec3(grey), COLOR.rgb, saturation);
}
