shader_type canvas_item;
render_mode unshaded, blend_add;
uniform float clock = 0.0;
uniform float night = 0.0;
float beam(vec2 p,vec2 direction,float width) {
 vec2 axis=normalize(direction);
 float along=dot(p,axis);
 float across=abs(p.x*axis.y-p.y*axis.x);
 float spread=0.012+max(along,0.0)*width;
 return exp(-pow(across/spread,2.0))*smoothstep(0.015,0.14,along)*(1.0-smoothstep(0.38,0.90,along));
}
void fragment() {
 vec2 source=vec2(0.42,0.34)+vec2(0.006*sin(clock*0.31),0.004*sin(clock*0.23));
 vec2 p=UV-source;
 float sway=0.034*sin(clock*0.37)+0.012*sin(clock*0.61+1.4);
 float rays=beam(p,vec2(0.38+sway,0.92),0.10)*0.68;
 rays+=beam(p,vec2(0.68+sway,0.73),0.065)*0.42;
 rays+=beam(p,vec2(0.02+sway,1.0),0.08)*0.26;
 float halo=exp(-length(p*vec2(1.0,1.3))*12.0)*0.35;
 float edge=(1.0-smoothstep(0.84,1.0,UV.x))*(1.0-smoothstep(0.84,1.0,UV.y));
 float breath=0.94+0.04*sin(clock*0.53)+0.02*sin(clock*0.91+0.7);
 float strength=(rays*0.30+halo)*edge*night*breath;
 COLOR=vec4(vec3(0.48,0.65,0.84),strength);
}
