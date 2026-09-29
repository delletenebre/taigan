shader_type canvas_item;
uniform float night = 0.0;
varying vec4 tint;
void vertex() { tint=COLOR; }
void fragment() {
 vec4 wool=texture(TEXTURE,UV);
 vec2 texel=TEXTURE_PIXEL_SIZE;
 // Light stays inside the original alpha, so wool keeps its soft silhouette.
 float inner_edge=max(0.0,wool.a-texture(TEXTURE,UV+vec2(-5.0,-4.0)*texel).a);
 float fibre_light=smoothstep(0.18,0.52,dot(wool.rgb,vec3(0.2126,0.7152,0.0722)));
 vec3 cool=wool.rgb*vec3(0.64,0.79,0.98);
 cool+=vec3(0.25,0.43,0.61)*(inner_edge*0.34+fibre_light*0.07);
 COLOR=vec4(mix(wool.rgb,cool,night),wool.a)*tint;
}
