shader_type canvas_item;

// Drains a sprite's colour toward grey. 1.0 full colour, 0.5 half, 0.0 greyscale. The HUD turns it
// down on units that have been commanded this turn (Unit.set_saturation(), HUD.command_state()).
uniform float saturation : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float grey = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	tex.rgb = mix(vec3(grey), tex.rgb, saturation);
	COLOR *= tex;  // COLOR holds the node's modulate on entry; keep it
}
