shader_type canvas_item;

uniform float sleep_amount : hint_range(0.0, 1.0) = 0.0;
varying vec4 tint;

// Eye centres in each 362 px atlas cell, in coat/direction order.
const vec2 EYE_A[12] = vec2[12](
	vec2(273,210), vec2(83,108), vec2(156,261), vec2(-100),
	vec2(272,209), vec2(81,99), vec2(159,239), vec2(-100),
	vec2(273,195), vec2(84,74), vec2(153,225), vec2(-100)
);
const vec2 EYE_B[12] = vec2[12](
	vec2(-100), vec2(-100), vec2(207,261), vec2(-100),
	vec2(311,192), vec2(-100), vec2(209,239), vec2(-100),
	vec2(315,177), vec2(-100), vec2(203,229), vec2(-100)
);

void vertex() { tint = COLOR; }

vec3 closed_eye(vec3 color, vec2 point, vec2 centre, vec3 felt) {
	vec2 delta = point - centre;
	float patch = 1.0 - smoothstep(0.7, 1.0, length(delta / vec2(10.0, 13.0)));
	// Borrow actual felt just above the eye, preserving each coat's texture.
	float arc = 2.5 * (1.0 - pow(clamp(delta.x / 8.0, -1.0, 1.0), 2.0));
	float lid = (1.0 - smoothstep(1.0, 2.3, abs(delta.y - arc)))
		* (1.0 - smoothstep(6.0, 9.0, abs(delta.x)));
	felt = mix(felt, vec3(0.10, 0.085, 0.07), lid);
	return mix(color, felt, patch * sleep_amount);
}

void fragment() {
	vec4 wool = texture(TEXTURE, UV);
	vec2 cell = UV / TEXTURE_PIXEL_SIZE / 362.0;
	vec2 point = fract(cell) * 362.0;
	int direction = clamp(int(cell.x), 0, 3);
	int coat = clamp(int(cell.y), 0, 2);
	int frame = coat * 4 + direction;
	float lift = coat == 2 ? 24.0 : (coat == 1 ? 12.0 : 0.0);
	// Follow the underside of the fleece instead of filtering by colour:
	// cream wool shadows must stay opaque while all four paws tuck away.
	float belly;
	if (direction == 0) {
		belly = 287.0 - pow(point.x - 211.0, 2.0) * 0.0041;
	} else if (direction == 1) {
		belly = 304.0 - pow(point.x - 220.0, 2.0) * 0.005;
	} else if (direction == 2) {
		belly = 306.0 - pow(point.x - 182.0, 2.0) * 0.008;
	} else {
		belly = 301.0 - pow(point.x - 182.0, 2.0) * 0.008;
	}
	float paws = smoothstep(belly - lift - 1.0, belly - lift + 1.0, point.y);
	wool.a *= 1.0 - paws * sleep_amount;
	vec3 felt_a = texture(TEXTURE, UV + vec2(0.0, -17.0 - (point.y - EYE_A[frame].y) * 0.8) * TEXTURE_PIXEL_SIZE).rgb;
	vec3 felt_b = texture(TEXTURE, UV + vec2(0.0, -17.0 - (point.y - EYE_B[frame].y) * 0.8) * TEXTURE_PIXEL_SIZE).rgb;
	wool.rgb = closed_eye(wool.rgb, point, EYE_A[frame], felt_a);
	wool.rgb = closed_eye(wool.rgb, point, EYE_B[frame], felt_b);
	COLOR = wool * tint;
}
