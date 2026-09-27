from pathlib import Path
import json,math,random,re
R=Path('/Users/sergei/projects/games/taigan')
src=(R/'art/source/author_scenes.py').read_text();exec(src[:src.index('# Each animal')])
s=Scene();s.node('FeltValley01',props='script = '+s.resource('scripts/level_builder.gd','Script')+'\npen_assist_radius = 3.0\npen_assist_half_width = 1.8\npen_assist_strength = 1.1')
for group in ['Terrain','River','Camp','Foliage','Boulders','CollisionMap','Herd','Spawns']:s.node(group,parent='.')
layout=[];counts={};collisions=[]
def hill_height(x,z):
    r2=((x+2.0)/3.5)**2+((z-4.6)/3.8)**2
    return .56*max(0,1-r2)**3
def prop(id,x,z,y=.02,yaw=0,scale=1,group='Terrain',name=None):
    y+=hill_height(x,z) if id not in ["valley_landform","valley_river"] else 0
    counts[id]=counts.get(id,0)+1;sc=(scale,)*3 if isinstance(scale,(int,float)) else scale
    s.node(name or id+'_'+str(counts[id]),parent=group,instance=s.resource(f'assets/models/{id}.glb'),props=f'position = {vec(x,y,z)}\nrotation = {vec(0,yaw,0)}\nscale = {vec(*sc)}')
    layout.append(dict(id=id,x=x,z=z,y=y,yaw=yaw,scale=list(sc)))
def collider(x,z,w,d):
    name='Obstacle'+str(len(collisions));collisions.append((x,z,w,d))
    s.sub.append(f'[sub_resource type="BoxShape3D" id="{name}"]\nsize = {vec(w,1.2,d)}')
    s.node(name,'StaticBody3D','CollisionMap',f'position = {vec(x,.6,z)}\nmetadata/extent = Vector2({w},{d})')
    s.node('Shape','CollisionShape3D','CollisionMap/'+name,f'shape = SubResource("{name}")')
prop('valley_landform',0,0,y=0,scale=(.65,1.4,.55))
prop('valley_river',0,0,y=0,scale=(.65,.8,.55),group='River')
prop('bridge_rope_4m',0,-2.2,y=0,scale=(1.35,1,.58),group='River')
# A single broad route leads from the small grazing meadow over the creek to camp.
# Pen has a wide approach and no confusing internal maze.
prop('pen_round_5m',-1.8,-7.2,group='Camp',name='RoundStonePen')
for i in range(34):
    t=-math.pi/2+.52+(math.tau-1.04)*(i+.5)/34
    x=-1.8+2.35*math.cos(t);z=-7.2-2.35*math.sin(t)
    collider(x,z,.40,.40)
prop('gate_openable',-1.8,-5.15,scale=.85,group='Camp',name='Gate')
prop('yurt_embroidered',3.6,-7.8,scale=.93,group='Camp',name='Yurt');collider(3.6,-7.8,2.9,2.9)
prop('rug_shyrdak',3.6,-5.95,y=.036,scale=.9,group='Camp')
prop('kazan_felt',5.3,-6.25,y=.14,scale=.85,group='Camp',name='FeltKazan')
prop('wooden_trough',-.6,-8.1,scale=.85,group='Camp');prop('hay_bale',-3.2,-8.3,scale=.8,group='Camp')
prop('hay_bale',5.35,-8.65,scale=.8,group='Camp')
# One short guide wall; ample room to go around either end.
prop('wall_straight_3m',3.75,3.2,yaw=-.15,scale=.72,group='Camp');collider(3.75,3.2,2.12,.55)
r=random.Random(2809)
# Deliberately grouped boulder / shrubs / flowers frame the playable clearings.
clusters=[(-5.55,7.15,1),(-6.2,2.8,.78),(-5.1,-.5,.65),(5.6,6.1,.85),(5.6,.0,.7),(-5.55,-7.6,.65),(1.7,9.5,.85),(6.3,-3.7,.60),(-3.5,9.5,.45)]
for j,(x,z,k) in enumerate(clusters):
    prop('boulder_large',x,z,scale=k,yaw=r.random()*6,group='Boulders');collider(x,z,k*1.45,k*1.3)
    for i,(dx,dz,asset,sc) in enumerate([(1.12,.38,'shrub_teal',1.55),(-1,.45,'shrub_ochre',1.2),(.1,-1.15,'shrub_pine',1.25),(-.9,-.9,'grass_tuft',1.15),(.8,1.15,'flowers_daisy',.9)]):
        prop(asset,x+dx*k,z+dz*k,scale=sc*k,yaw=r.random()*6,group='Foliage')
for x,z,id,sc in [(-4.8,-9,'shrub_teal',1.2),(-3.7,9.5,'shrub_pine',1.2),(3.9,8.2,'shrub_teal',1.1),(5.8,-9,'shrub_ochre',.9),(-6.15,-4.5,'shrub_pine',1.3),(-6.3,-3.8,'shrub_rust',.9),(1.1,-9.5,'shrub_teal',1.1)]:
    prop(id,x,z,scale=sc,group='Foliage')
for i in range(23):
    x=-5.7+i*.51
    if abs(x)<1.45:continue
    z=-2.2+.385*math.sin(x/.65*.42)+(1 if i%2 else -1)*.76
    prop('river_reeds' if i%3 else 'grass_tuft',x,z,scale=.5+r.random()*.25,yaw=r.random()*6,group='Foliage')
for x,z in [(-2,5.8),(2.4,7.2),(-3.4,1.4),(2.7,-3.5),(-4.4,-3.7),(4.8,9),(-5.2,5.5),(5.4,2.1)]:
    prop('flowers_daisy',x,z,scale=.55,group='Foliage');prop('grass_tuft',x+.25,z+.18,scale=.4,group='Foliage')
# A distant, recognizable wolf approach framed by two low rocks.
prop('boulder_large',-6.1,6.55,scale=.68,group='Boulders',name='WolfEntryRockSouth');collider(-6.1,6.55,.9,.9)
prop('boulder_large',-6.2,3.95,scale=.55,group='Boulders',name='WolfEntryRockNorth');collider(-6.2,3.95,.75,.75)
for x,z in [(-6.3,5.15),(-5.95,5.2),(-5.6,5.1),(-5.2,5.0)]:
    prop('grass_tuft',x,z,scale=.32,group='Foliage')
# The one night entry is concealed inside a low woolly thicket.
for x,z,asset,sc in [(-6.15,5.05,'shrub_pine',1.8),(-5.8,5.55,'shrub_teal',1.65),(-5.95,4.65,'shrub_pine',1.55),(-6.4,5.45,'shrub_ochre',.9)]:
    prop(asset,x,z,scale=sc,group='Foliage')
# Low planting beds make the yurt and pen one sheltered, inhabited camp.
for x,z,asset,sc in [(2.1,-8.9,'shrub_teal',1.05),(5.15,-7.6,'shrub_pine',1.1),(4.8,-5.8,'flowers_daisy',.7),(2.5,-5.3,'grass_tuft',.65),(-4.0,-8.8,'shrub_ochre',.65),(-3.9,-5.35,'flowers_daisy',.55)]:
    prop(asset,x,z,scale=sc,group='Foliage')
herd=[(-2.0,5.3),(-.8,5.9),(.3,5.15),(1.3,6.1),(-2.4,3.8),(-1.25,4.25),(.05,3.7),(1.1,4.65)]
for i,(x,z) in enumerate(herd):
    scale=.84+r.random()*.12;id='sheep_whiteface' if i==3 else 'sheep_ivory'
    s.node('Sheep'+str(i+1),parent='Herd',instance=s.resource('scenes/actors/'+id+'.tscn'),props=f'position = {vec(x,.03+hill_height(x,z),z)}\nscale = {vec(scale,scale,scale)}')
    layout.append(dict(id=id,x=x,z=z,y=.03+hill_height(x,z),yaw=r.random()*6,scale=[scale]*3))
s.node('Dog',parent='.',instance=s.resource('scenes/actors/taigan_dog.tscn'),props='position = Vector3(0,0.03,8)')
layout.append(dict(id='taigan_dog',x=0,z=8,y=.03,yaw=math.pi,scale=[1]*3))
for i,(x,z) in enumerate([(-5.7,5.1)]):s.node('WolfEntry'+str(i+1),'Marker3D','Spawns',f'position = {vec(x,0,z)}')
s.node('PenCenter','Marker3D','Spawns','position = Vector3(-1.8,0,-7.2)')
s.node('YurtSmoke',parent='Camp',instance=s.resource('scenes/effects/yurt_smoke.tscn'),props='position = Vector3(3.6,2.18,-7.8)')
s.node('Campfire',parent='Camp',instance=s.resource('scenes/effects/campfire.tscn'),props='position = Vector3(5.3,0.035,-6.25)')
s.save('scenes/levels/level_01.tscn')
(R/'data/level_01_art.json').write_text(json.dumps(layout,indent=2))
c=json.loads((R/'data/level_01.json').read_text());c.update(bounds=[16,23],title='Первый выпас',sheep_count=8,dog_spawn=[0,8],pen_center=[-1.8,-7.2],pen_half_size=[1.9,1.55],bridge_x=[0],bridge_half_width=1.15,river_z=-2.2,river_half_width=.56,landform_scale=[.65,.55],herd_spawns=[[-1,5]],wolf_spawns=[[-5.7,5.1]],wolf_interval_seconds=24,max_wolves=2)
(R/'data/level_01.json').write_text(json.dumps(c,ensure_ascii=False,indent=2))

print("Saved level_01 scene and shared art layout; camera and lighting are edited separately.")
