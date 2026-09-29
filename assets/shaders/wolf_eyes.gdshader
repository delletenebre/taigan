shader_type canvas_item;
uniform float night = 0.0;
varying vec4 tint;
void vertex() { tint=COLOR; }
float iris(vec4 pixel) {
 // Only the amber irises: cream paws and muzzle have much more blue.
 return smoothstep(0.04,0.20,pixel.r-1.9*pixel.b)
      *smoothstep(0.20,0.45,pixel.r)
      *smoothstep(0.02,0.12,pixel.r-pixel.g)*pixel.a;
}
void fragment() {
 vec4 wool=texture(TEXTURE,UV);
 float eye=iris(wool);
 vec2 step_uv=TEXTURE_PIXEL_SIZE*3.0;
 float halo=iris(texture(TEXTURE,UV+vec2(step_uv.x,0.0)))
           +iris(texture(TEXTURE,UV-vec2(step_uv.x,0.0)))
           +iris(texture(TEXTURE,UV+vec2(0.0,step_uv.y)))
           +iris(texture(TEXTURE,UV-vec2(0.0,step_uv.y)));
 float amount=smoothstep(0.35,0.90,night);
 vec3 amber=vec3(1.0,0.63,0.14)*(eye*0.85+halo*0.045)*amount;
 COLOR=vec4(wool.rgb*tint.rgb+amber,wool.a*tint.a);
}
