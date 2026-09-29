shader_type canvas_item;
render_mode unshaded;
uniform float clock = 0.0;
uniform float night = 0.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
 vec2 p=UV*vec2(3.2,6.0)+vec2(clock*0.035,-clock*0.018);
 float n=noise(p)*0.65+noise(p*2.1)*0.25+noise(p*4.2)*0.10;
 float edge=1.0-smoothstep(0.35,1.0,length((UV-vec2(0.5,0.53))*vec2(2.0,2.0)));
 float ribbons=smoothstep(0.38,0.76,n);
 COLOR=vec4(mix(vec3(0.88,0.91,0.85),vec3(0.67,0.82,1.0),night),ribbons*edge*mix(0.17,0.28,night));
}
