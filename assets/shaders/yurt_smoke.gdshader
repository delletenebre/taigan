shader_type canvas_item;
uniform sampler2D clean_plate : source_color, filter_linear;
uniform float clock = 0.0;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
    vec2 size = vec2(textureSize(TEXTURE, 0));
    vec2 p = UV * size;
    vec2 local = (p - vec2(810.0, 85.0)) / vec2(95.0, 100.0);
    // Keep the existing wool plume, bending progressively above its fixed base.
    float height = clamp((183.0 - p.y) / 85.0, 0.0, 1.0);
    vec2 source = p;
    source.x += height * (5.0 * sin(clock * 0.85 - height * 3.5) + 1.7 * sin(clock * 1.4 - height * 8.0));
    source.y += height * 2.8 * sin(clock * 1.2 + height * 10.0);
    vec3 wool = texture(TEXTURE, source / size).rgb;
    vec3 behind_wool = texture(clean_plate, source / size).rgb;
    float alpha = clamp((wool.b - behind_wool.b - 0.012) / max(0.95 - behind_wool.b, 0.15), 0.0, 1.0);
    alpha *= smoothstep(0.0, 0.035, alpha);
    vec3 foreground = clamp((wool - behind_wool * (1.0 - alpha)) / max(alpha, 0.001), vec3(0.0), vec3(1.0));
    vec2 edge = min(local, 1.0 - local);
    float patch = smoothstep(0.0, 0.09, edge.x) * smoothstep(0.0, 0.04, edge.y);
    COLOR = vec4(foreground, alpha * patch) * tint;
}
