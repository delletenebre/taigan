shader_type canvas_item;
render_mode unshaded;
uniform sampler2D silhouette : filter_linear_mipmap, repeat_disable;
uniform float opacity : hint_range(0.0, 1.5) = 1.0;
float luminance(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }
void fragment() {
	// Recover the painted shadow in place, relative to the unshadowed cloth
	// in the four empty corners. No offset or duplicated island silhouette.
	float top_left = luminance(textureLod(TEXTURE, vec2(0.025, 0.018), 5.0).rgb);
	float top_right = luminance(textureLod(TEXTURE, vec2(0.975, 0.018), 5.0).rgb);
	float bottom_left = luminance(textureLod(TEXTURE, vec2(0.025, 0.982), 5.0).rgb);
	float bottom_right = luminance(textureLod(TEXTURE, vec2(0.975, 0.982), 5.0).rgb);
	float cloth = mix(mix(top_left, top_right, UV.x), mix(bottom_left, bottom_right, UV.x), UV.y);
	// Average only the fine fibres; preserve the source's contact and falloff.
	float painted = luminance(textureLod(TEXTURE, UV, 3.8).rgb);
	float shade = max(0.0, 1.0 - painted / max(cloth, 0.01) - 0.05) / 0.95;
	shade *= smoothstep(0.005, 0.035, shade);
	float outside = 1.0 - texture(silhouette, UV).a;
	float near_island = smoothstep(0.01, 0.10, textureLod(silhouette, UV, 6.0).a);
	vec2 border = min(UV, vec2(1.0) - UV) / TEXTURE_PIXEL_SIZE;
	float image_edge = smoothstep(0.0, 24.0, min(border.x, border.y));
	COLOR = vec4(vec3(0.0), clamp(shade * outside * near_island * image_edge * opacity, 0.0, 0.85));
}
