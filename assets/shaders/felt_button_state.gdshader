shader_type canvas_item;
render_mode unshaded;
uniform float inactive : hint_range(0.0, 1.0) = 0.0;
varying vec4 wool_tint;
void vertex() { wool_tint = COLOR; }
void fragment() {
	vec4 wool = texture(TEXTURE, UV);
	float luminance = dot(wool.rgb, vec3(0.299, 0.587, 0.114));
	vec3 muted = vec3(luminance) * vec3(0.80, 0.78, 0.73);
	COLOR = vec4(mix(wool.rgb, muted, inactive), wool.a) * wool_tint;
}
