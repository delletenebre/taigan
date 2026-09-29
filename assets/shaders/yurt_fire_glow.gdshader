shader_type canvas_item;
render_mode unshaded;
uniform float glow = 0.0;
uniform float spill = 0.0;
void fragment() {
 vec4 source=texture(TEXTURE,UV);
 vec3 ember=mix(source.rgb,vec3(1.0,0.53,0.18),spill);
 float opacity=mix(source.a,source.r*0.24,spill)*glow;
 // Emitted firelight must remain visible under the parent's night modulation.
 COLOR=vec4(ember,opacity);
}
