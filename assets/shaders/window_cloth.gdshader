shader_type canvas_item;
render_mode unshaded;
varying vec4 cloth_tint;
uniform vec2 window_size = vec2(819.0, 1456.0);
uniform vec2 field_offset = vec2(0.0);
void vertex() { cloth_tint = COLOR; }
void fragment() {
	// One continuous wool surface, with the same fibre scale at every aspect ratio.
	vec2 p = UV * window_size - field_offset;
	vec2 uv = p * 1.6 / vec2(textureSize(TEXTURE, 0));
	vec3 wool = texture(TEXTURE, uv).rgb;
	COLOR = vec4(mix(vec3(0.76, 0.65, 0.52), wool, 0.65), 1.0) * cloth_tint;
}
