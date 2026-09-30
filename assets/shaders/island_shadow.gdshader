shader_type canvas_item;
render_mode unshaded;
uniform sampler2D silhouette : filter_linear_mipmap, repeat_disable;
uniform float opacity : hint_range(0.0, 1.5) = 1.0;
const vec2 SOURCE_SIZE = vec2(941.0, 1672.0);
const float SHADOW_MARGIN = 120.0;
float luminance(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }
void vertex() {
	// The original photo clips the cast shadow at its left edge. Give the
	// reconstructed shadow room to fade beyond the source rectangle.
	vec2 expansion = (UV * 2.0 - 1.0) * SHADOW_MARGIN;
	VERTEX += expansion;
	UV += expansion / SOURCE_SIZE;
}
void fragment() {
	float outside = 1.0 - texture(silhouette, UV).a;
	if (outside < 0.001) {
		COLOR = vec4(0.0);
	} else {
		// Recover the painted shadow in place, relative to the unshadowed cloth
		// in the four empty corners. No offset or duplicated island silhouette.
		float top_left = luminance(textureLod(TEXTURE, vec2(0.025, 0.018), 5.0).rgb);
		float top_right = luminance(textureLod(TEXTURE, vec2(0.975, 0.018), 5.0).rgb);
		float bottom_left = luminance(textureLod(TEXTURE, vec2(0.025, 0.982), 5.0).rgb);
		float bottom_right = luminance(textureLod(TEXTURE, vec2(0.975, 0.982), 5.0).rgb);
		vec2 source_uv = clamp(UV, vec2(0.0), vec2(1.0));
		float cloth = mix(mix(top_left, top_right, source_uv.x), mix(bottom_left, bottom_right, source_uv.x), source_uv.y);
		// Smooth the old cloth fibres without bleeding dark island pixels into
		// the exterior. A plain mip sample would create a false halo at the edge.
		float painted = 0.0;
		float weight = 0.0;
		for (int y = -2; y <= 2; y++) {
			for (int x = -2; x <= 2; x++) {
				vec2 delta = vec2(float(x), float(y));
				vec2 sample_uv = UV + delta * 8.0 * TEXTURE_PIXEL_SIZE;
				vec2 bounded_uv = clamp(sample_uv, vec2(0.0), vec2(1.0));
				vec2 distance_outside = (sample_uv - bounded_uv) / TEXTURE_PIXEL_SIZE;
				float continuation = exp(-dot(distance_outside, distance_outside) / (2.0 * 28.0 * 28.0));
				float exterior = 1.0 - smoothstep(0.0, 0.02, textureLod(silhouette, bounded_uv, 1.5).a);
				float sample_weight = exp(-dot(delta, delta) * 0.4) * exterior;
				float source_light = luminance(textureLod(TEXTURE, bounded_uv, 1.5).rgb);
				painted += mix(cloth, source_light, continuation) * sample_weight;
				weight += sample_weight;
			}
		}
		painted = weight > 0.001 ? painted / weight : cloth;
		float shade = max(0.0, 1.0 - painted / max(cloth, 0.01) - 0.05) / 0.95;
		shade *= smoothstep(0.005, 0.035, shade);
		COLOR = vec4(vec3(0.0), clamp(shade * outside * opacity, 0.0, 0.85));
	}
}
