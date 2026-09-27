"""Author editable .tscn scene files; never executed by the game."""
from pathlib import Path
import random, math, json
R=Path('/Users/sergei/projects/games/taigan')
for d in ['scenes/levels','scenes/actors','scenes/world','scenes/ui']: (R/d).mkdir(parents=True,exist_ok=True)
class Scene:
    def __init__(self):self.ext=[];self.sub=[];self.nodes=[];self.ids={}
    def resource(self,path,kind='PackedScene'):
        if path not in self.ids:
            i=str(len(self.ext)+1);self.ids[path]=i;self.ext.append(f'[ext_resource type="{kind}" path="res://{path}" id="{i}"]')
        return f'ExtResource("{self.ids[path]}")'
    def node(self,name,type='Node3D',parent=None,props='',instance=None):
        header=f'[node name="{name}"'
        if not instance:header+=f' type="{type}"'
        if parent is not None:header+=f' parent="{parent}"'
        if instance:header+=f' instance={instance}'
        self.nodes.append(header+']\n'+props)
    def save(self,path):
        (R/path).write_text(f'[gd_scene load_steps={1+len(self.ext)+len(self.sub)} format=3]\n\n'+'\n\n'.join(self.ext+self.sub+self.nodes)+'\n')

def vec(x,y,z):return f'Vector3({x:.5f}, {y:.5f}, {z:.5f})'
# Each animal is a real reusable Godot scene with a model and defined role.
for id,kind in [('sheep_ivory','sheep'),('sheep_whiteface','sheep'),('taigan_dog','dog'),('wolf_gray','wolf')]:
    s=Scene();script=s.resource('scripts/herd_actor.gd','Script');model=s.resource(f'assets/models/{id}.glb')
    s.node(id,props=f'script = {script}\nkind = "{kind}"')
    s.node('Visual',parent='.',instance=model)
    s.save(f'scenes/actors/{id}.tscn')
# Level geometry is directly visible and editable in Godot, with separate semantic groups.
s=Scene();script=s.resource('scripts/level_builder.gd','Script')
s.node('FeltValley01',props=f'script = {script}')
for group in ['Terrain','River','Cliffs','Camp','Foliage','Boulders','CollisionMap','Herd','Spawns']:s.node(group,parent='.')
count={};collisions=[]
def prop(id,x,z,y=0,yaw=0,scale=1,group='Terrain',name=None):
    count[id]=count.get(id,0)+1
    s.node(name or id+'_'+str(count[id]),parent=group,instance=s.resource(f'assets/models/{id}.glb'),props=f'position = {vec(x,y,z)}\nrotation = {vec(0,yaw,0)}\nscale = {vec(scale,scale,scale)}')
def collider(x,z,w,d):
    idx=len(collisions);collisions.append((x,z,w,d))
    res=f'Collision{idx}'
    s.sub.append(f'[sub_resource type="BoxShape3D" id="{res}"]\nsize = {vec(w,1.3,d)}')
    s.node(res,'StaticBody3D','CollisionMap',f'position = {vec(x,.65,z)}\nmetadata/extent = Vector2({w}, {d})')
    s.node('Shape','CollisionShape3D','CollisionMap/'+res,f'shape = SubResource("{res}")')
for ix in range(6):
    for iz in range(10):
        id='path_tile_4m' if ix==2 or (iz==4 and ix>1) else ('sage_tile_4m' if (ix+iz)%3==0 else 'meadow_tile_4m')
        prop(id,-10+ix*4,-18+iz*4)
for ix in range(6):
    for z in [-20,20]:prop('cliff_embroidered_4m',-10+ix*4,z,yaw=0 if z>0 else math.pi,group='Cliffs')
    prop('river_straight_4m',-10+ix*4,-4,y=.11,yaw=math.pi/2,group='River')
for iz in range(10):
    for x in [-12,12]:prop('cliff_embroidered_4m',x,-18+iz*4,yaw=math.pi/2 if x>0 else -math.pi/2,group='Cliffs')
for x in [-6,6]:prop('bridge_rope_4m',x,-4,y=.02,group='River')
for x in [-3.25,3.25]:
    for z in [-16.5,-13.5]:prop('wall_straight_3m',x,z,yaw=math.pi/2,group='Camp')
    collider(x,-15,.52,6.15)
for x in [-1.5,1.5]:prop('wall_straight_3m',x,-18.1,group='Camp')
collider(0,-18.1,6.2,.52)
for x in [-2.2,2.2]:
    prop('wall_straight_3m',x,-12,scale=.62,group='Camp');collider(x,-12,1.9,.45)
prop('gate_openable',0,-12,group='Camp',name='Gate')
prop('yurt_embroidered',7.6,-15.2,yaw=-.3,group='Camp',name='Yurt');collider(7.6,-15.2,3.3,3.3)
prop('rug_shyrdak',7.4,-12.8,y=.03,yaw=-.3,group='Camp')
prop('barrel_large',9.3,-13.8,group='Camp');prop('barrel_small',9.9,-14.1,group='Camp')
r=random.Random(28092026)
for i in range(18):
    x=r.uniform(8.8,11.1)*(-1 if i%2 else 1);z=r.uniform(-18,18)
    if math.hypot(x-7.6,z+15.2)<4:continue
    size=r.uniform(.55,1.15);prop('boulder_large' if i%3==0 else 'boulder_medium',x,z,yaw=r.random()*math.tau,scale=size,group='Boulders');collider(x,z,size*(1.5 if i%3==0 else .75),size*(1.5 if i%3==0 else .75))
for i in range(76):
    x=r.uniform(-11.4,11.4);z=r.uniform(-19,19)
    if abs(z+4)<1.35 or (abs(x)<4 and z<-11):continue
    if abs(x)<6 and i%3!=0:continue
    if math.hypot(x-7.6,z+15.2)<2:continue
    prop(['shrub_pine','shrub_teal','shrub_ochre','shrub_rust','grass_tuft','flowers_daisy'][i%6],x,z,yaw=r.random()*math.tau,scale=r.uniform(.6,1.2),group='Foliage')
for i in range(18):prop('river_reeds',-11+i*1.3,-4+(1.2 if i%2 else -1.2),yaw=r.random()*math.tau,group='Foliage')
for i in range(18):
    center=[(-5,10),(5,4),(-5,-8)][i%3];p=(center[0]+r.uniform(-1.7,1.7),center[1]+r.uniform(-1.7,1.7));size=r.uniform(.86,1.04)
    s.node('Sheep'+str(i+1),parent='Herd',instance=s.resource('scenes/actors/sheep_whiteface.tscn' if i%4==0 else 'scenes/actors/sheep_ivory.tscn'),props=f'position = {vec(p[0],.03,p[1])}\nscale = {vec(size,size,size)}')
s.node('Dog',parent='.',instance=s.resource('scenes/actors/taigan_dog.tscn'),props='position = Vector3(0, 0.03, 14)')
for i,(x,z) in enumerate([(-11,-8),(11,6),(-11,17)]):s.node('WolfEntry'+str(i+1),'Marker3D','Spawns',f'position = {vec(x,0,z)}')
s.node('PenCenter','Marker3D','Spawns','position = Vector3(0,0,-15)')
s.save('scenes/levels/level_01.tscn')
# All lighting is explicitly authored in a separate scene, including warm night pools.
s=Scene()
s.sub.append('''[sub_resource type="Environment" id="Environment"]
background_mode = 1
background_color = Color(0.46, 0.37, 0.27, 1)
ambient_light_source = 3
ambient_light_color = Color(0.75, 0.79, 0.85, 1)
ambient_light_energy = 0.48
reflected_light_source = 2
tonemap_mode = 2
adjustment_enabled = true
adjustment_brightness = 1.02
adjustment_contrast = 1.06
adjustment_saturation = 0.92''')
s.sub.append('''[sub_resource type="StandardMaterial3D" id="Ember"]
albedo_color = Color(1, 0.66, 0.27, 1)
emission_enabled = true
emission = Color(1, 0.40, 0.09, 1)
emission_energy_multiplier = 2.0''')
s.sub.append('''[sub_resource type="SphereMesh" id="Flame"]
material = SubResource("Ember")
radius = 0.10
height = 0.26
radial_segments = 16
rings = 8''')
s.node('Lighting')
s.node('WorldEnvironment','WorldEnvironment','.', 'environment = SubResource("Environment")')
s.node('EveningSun','DirectionalLight3D','.',f'rotation = {vec(math.radians(-36),math.radians(-34),0)}\nlight_color = Color(1, 0.76, 0.48, 1)\nlight_energy = 1.5\nlight_angular_distance = 1.4\nshadow_enabled = true\nshadow_bias = 0.03\ndirectional_shadow_max_distance = 55.0\ndirectional_shadow_mode = 2')
s.node('SkyFill','DirectionalLight3D','.',f'rotation = {vec(math.radians(-58),math.radians(145),0)}\nlight_color = Color(0.67, 0.79, 1, 1)\nlight_energy = 0.32')
s.node('Moon','DirectionalLight3D','.',f'rotation = {vec(math.radians(-47),math.radians(32),0)}\nlight_color = Color(0.55, 0.69, 1, 1)\nlight_energy = 0.0\nshadow_enabled = false\ndirectional_shadow_max_distance = 48.0')
for name,p,energy,range_ in [('YurtLight',(7.3,1.5,-13.7),2.5,7),('PenLight',(-1.0,1.4,-11.8),1.4,5),('YurtInside',(7.6,1.2,-15),1.0,3)]:
    s.node(name,'OmniLight3D','.',f'position = {vec(*p)}\nlight_color = Color(1, 0.52, 0.21, 1)\nlight_energy = 0.12\nomni_range = {range_}.0\nomni_attenuation = 1.5\nmetadata/night_energy = {energy}')
    s.node('Ember','MeshInstance3D',name,'mesh = SubResource("Flame")')
s.save('scenes/world/lighting.tscn')
# Camera scene with editable framing.
s=Scene();s.node('PortraitCamera','Camera3D',props='position = Vector3(5.5, 23, 37)\nrotation_degrees = Vector3(-40.87, 11.94, 0)\nprojection = 1\nsize = 25.0\ncurrent = true\nfar = 150.0');s.save('scenes/world/portrait_camera.tscn')
# Main composition links all scenes; game logic references these fixed nodes.
s=Scene();script=s.resource('scripts/pasture_game.gd','Script')
s.node('Taigan',props=f'script = {script}')
s.node('Level',parent='.',instance=s.resource('scenes/levels/level_01.tscn'))
s.node('Lighting',parent='.',instance=s.resource('scenes/world/lighting.tscn'))
s.node('Camera',parent='.',instance=s.resource('scenes/world/portrait_camera.tscn'))
s.node('HUD',parent='.',instance=s.resource('scenes/ui/hud.tscn'))
s.node('Wolves',parent='.')
s.save('scenes/pasture.tscn')
print('Authored editable actor, lighting, camera, level and main scenes.')
