shader_type canvas_item;
render_mode unshaded;
uniform float shade : hint_range(0.0, 1.0) = 0.0;
// Sample prefiltered mip levels, then smooth locally with a Gaussian kernel.
// Wide offsets on the full-resolution texture produce visible duplicate edges.
uniform float blur : hint_range(0.0, 8.0) = 0.0;
void fragment() {
	vec4 base;
	if (blur < 0.01) {
		base = texture(TEXTURE, UV);
	} else {
		vec2 step_uv = TEXTURE_PIXEL_SIZE * exp2(blur) * 0.75;
		base = textureLod(TEXTURE, UV, blur) * 0.25;
		base += textureLod(TEXTURE, UV + vec2(step_uv.x, 0.0), blur) * 0.125;
		base += textureLod(TEXTURE, UV - vec2(step_uv.x, 0.0), blur) * 0.125;
		base += textureLod(TEXTURE, UV + vec2(0.0, step_uv.y), blur) * 0.125;
		base += textureLod(TEXTURE, UV - vec2(0.0, step_uv.y), blur) * 0.125;
		base += textureLod(TEXTURE, UV + step_uv, blur) * 0.0625;
		base += textureLod(TEXTURE, UV - step_uv, blur) * 0.0625;
		base += textureLod(TEXTURE, UV + vec2(step_uv.x, -step_uv.y), blur) * 0.0625;
		base += textureLod(TEXTURE, UV + vec2(-step_uv.x, step_uv.y), blur) * 0.0625;
	}
	COLOR = vec4(mix(base.rgb, vec3(0.10, 0.15, 0.12), shade), base.a);
}
