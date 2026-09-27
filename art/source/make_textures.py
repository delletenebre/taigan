"""Original, deterministic seamless textile PBR maps. No external assets."""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
import math, random

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets' / 'textures'
OUT.mkdir(exist_ok=True)
N = 1024
rng = np.random.default_rng(2809)

def noise(scale):
    a = rng.integers(0, 256, (scale, scale), dtype=np.uint8)
    # Tiled 3x3 then crop the middle gives continuous wrap interpolation.
    im = Image.fromarray(np.tile(a, (3,3))).resize((N*3,N*3), Image.Resampling.BICUBIC)
    return np.asarray(im.crop((N,N,2*N,2*N)), dtype=float) / 255

def save(name, h, color, rough):
    h = np.clip(h,0,1)
    base = np.array(color)[None,None,:] * (0.75 + h[:,:,None]*0.46)
    Image.fromarray(np.uint8(np.clip(base,0,255))).save(OUT/f'{name}_color.png')
    dx=(np.roll(h,-1,1)-np.roll(h,1,1))*2.4
    dy=(np.roll(h,-1,0)-np.roll(h,1,0))*2.4
    normal=np.stack((-dx,dy,np.ones_like(h)),axis=-1)
    normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
    Image.fromarray(np.uint8((normal*.5+.5)*255)).save(OUT/f'{name}_normal.png')
    rr=np.clip(rough+(h-.5)*.1,0,1)
    Image.fromarray(np.uint8(rr*255)).save(OUT/f'{name}_roughness.png')

random.seed(120)
fiber=Image.new('L',(N,N),128)
d=ImageDraw.Draw(fiber)
for _ in range(26000):
    x,y=random.uniform(0,N),random.uniform(0,N)
    a=random.uniform(0,math.tau); length=random.uniform(5,30)
    pts=[(x+math.cos(a+t*.1)*length*t/5,y+math.sin(a+t*.1)*length*t/5) for t in range(6)]
    gray=random.choice([65,85,110,150,175,205])
    for ox in (-N,0,N):
        for oy in (-N,0,N):
            if -32<x+ox<N+32 and -32<y+oy<N+32:
                d.line([(px+ox,py+oy) for px,py in pts],fill=gray,width=random.choice([1,1,2]))
f=np.asarray(fiber,dtype=float)/255
h=.45*f+.22*noise(160)+.18*noise(24)+.15*noise(5)
palette={
    'wool_ivory':(231,221,193),'wool_snow':(242,235,214),
    'felt_charcoal':(47,45,40),'felt_ash':(121,119,103),
    'felt_wolf':(100,102,94),'felt_muzzle':(185,181,160),
    'felt_tan':(155,112,69),'felt_ochre':(151,131,47),
    'felt_meadow':(92,112,46),'felt_sage':(116,133,71),
    'felt_pine':(34,86,76),'felt_teal':(48,107,98),
    'felt_rust':(143,60,48),'felt_gold':(182,145,56),
    'felt_red':(125,27,32),'felt_linen':(213,192,151),
    'felt_water':(53,108,120),'felt_water_light':(102,156,163),
    'felt_rose':(168,116,104),'felt_soil':(121,95,67)
}
for name,c in palette.items(): save(name,h,c,.91)
y,x=np.mgrid[0:N,0:N]/N
wood=.36*noise(12)+.25*noise(90)+.18*(np.sin(x*math.tau*37+noise(8)*7)*.5+.5)+.21*f
save('wood',wood,(142,103,65),.83)
stone=.30*noise(7)+.25*noise(35)+.20*noise(150)+.25*f
save('stone',stone,(140,141,129),.94)
weave=(np.sin(x*math.tau*160)*np.sin(y*math.tau*160)*.5+.5)
save('rope',.6*weave+.4*h,(215,192,148),.88)
save('leather',.6*noise(32)+.4*noise(170),(61,46,34),.80)
print(f'Wrote {len(palette)+4} original materials / {(len(palette)+4)*3} PNG maps')
