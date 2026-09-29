shader_type canvas_item;
render_mode unshaded;
uniform float clock = 0.0;
uniform float night = 0.0;
uniform float layer = 0.0;
uniform float density = 0.30;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float fbm(vec2 p) {
 return 0.57*noise(p)+0.28*noise(p*2.03+4.1)+0.15*noise(p*4.07+9.2);
}
void fragment() {
 vec2 drift=vec2(clock*0.048,-clock*0.019);
 vec2 p=UV*vec2(3.1,5.6)+drift+layer*7.3;
 vec2 curl=vec2(fbm(p*0.65+vec2(0,clock*0.017)),fbm(p*0.7+3.7));
 float cloud=fbm(p+curl*1.8);
 float wisp=fbm(p*vec2(1.25,2.5)-drift*0.75+curl);
 // Broken low ribbons, not a uniform screen overlay.
 float bands=0.70*smoothstep(0.25,0.64,cloud)+0.30*smoothstep(0.32,0.70,wisp);
 float edge=1.0-smoothstep(0.48,1.0,length((UV-vec2(0.50,0.56))*vec2(2.0,2.0)));
 float ground=0.70+0.30*smoothstep(0.18,0.65,UV.y);
 float lit_cloud=fbm(p+curl*1.8+vec2(-0.13,-0.20));
 float volume=clamp(0.68+(lit_cloud-cloud)*3.4,0.28,1.0);
 float moon=exp(-length((UV-vec2(0.39,0.30))*vec2(2.4,1.8))*2.0);
 vec3 tint=mix(vec3(0.88,0.91,0.86),mix(vec3(0.24,0.33,0.46),vec3(0.43,0.55,0.69),moon),night);
 tint *= mix(mix(0.68,1.12,volume),mix(0.66,0.96,volume),night);
 COLOR=vec4(tint,min(0.78,bands*edge*ground*density*mix(0.80,0.85,night)));
}
