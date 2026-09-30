shader_type canvas_item;
uniform sampler2D silhouette : filter_linear, repeat_disable;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	// Only the generated alpha is used; all visible colour stays source-exact.
	vec4 original = texture(TEXTURE, UV);
	float alpha = texture(silhouette, UV).a;
	COLOR = vec4(original.rgb, alpha) * tint;
}
