// 1px faction outline around a sprite. Grows the quad by `width` px so sprites that touch
// their texture edges still get a full outline. Assumes one texture per frame (no atlas regions).
// `shadow` paints the sprite itself black: a shape seen without telling who it is.
shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0);
uniform float width = 1.0;
uniform bool shadow = false;

void vertex() {
	vec2 grow = (UV * 2.0 - 1.0) * width;
	VERTEX += grow;
	UV += grow * TEXTURE_PIXEL_SIZE;
}

// 1 inside the texture, 0 in the grown border (TEXTURE can't be passed to helpers).
float inside(vec2 uv) {
	return step(0.0, uv.x) * step(0.0, uv.y) * step(uv.x, 1.0) * step(uv.y, 1.0);
}

void fragment() {
	// Inside the sprite COLOR already holds the textured pixel; only paint the ring around it.
	if (texture(TEXTURE, UV).a * inside(UV) < 0.5) {
		vec2 px = TEXTURE_PIXEL_SIZE * width;
		vec2 r = UV + vec2(px.x, 0.0), l = UV - vec2(px.x, 0.0);
		vec2 d = UV + vec2(0.0, px.y), u = UV - vec2(0.0, px.y);
		float near = max(max(texture(TEXTURE, r).a * inside(r), texture(TEXTURE, l).a * inside(l)),
				max(texture(TEXTURE, d).a * inside(d), texture(TEXTURE, u).a * inside(u)));
		COLOR = near > 0.5 ? color : vec4(0.0);
	} else if (shadow) {
		COLOR.rgb = vec3(0.03);
	}
}
