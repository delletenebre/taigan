shader_type canvas_item;
varying vec4 tint;

void vertex() { tint = COLOR; }

void fragment() {
	vec4 cloth = texture(TEXTURE, UV);
	// Atlas region of the existing stitched panel; preserve its dark seam.
	vec2 panel = (UV / TEXTURE_PIXEL_SIZE - vec2(36.0, 285.0)) / vec2(1464.0, 450.0);
	float aspect = 1464.0 / 450.0;
	vec2 point = vec2((panel.x - 0.5) * aspect, panel.y - 0.5);
	float radius = length(vec2(max(abs(point.x) - (aspect * 0.5 - 0.5), 0.0), point.y));
	float interior = 1.0 - smoothstep(0.34, 0.39, radius);
	float grain = dot(cloth.rgb, vec3(0.299, 0.587, 0.114));
	vec3 cream = vec3(0.94, 0.83, 0.65) * (0.80 + grain);
	cloth.rgb = mix(cloth.rgb, cream, interior * 0.94);
	COLOR = cloth * tint;
}
