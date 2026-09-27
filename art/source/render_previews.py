exec(compile(open('/Users/sergei/projects/games/taigan/art/source/build_assets.py').read(), 'build_assets.py', 'exec'), globals())
import bpy, math, random, traceback
from pathlib import Path
from mathutils import Vector
ROOT=Path('/Users/sergei/projects/games/taigan')
LOG=ROOT/'art/render.log'
LOG.write_text('RENDER START\n')
def log(s):
    with LOG.open('a') as f:f.write(s+'\n')

def scene_new(name):
    s=bpy.data.scenes.new(name); bpy.context.window.scene=s
    s.render.engine='CYCLES'; s.cycles.device='CPU'; s.cycles.samples=48; s.cycles.use_denoising=True
    s.render.threads_mode='FIXED'; s.render.threads=8
    s.render.resolution_x=1200; s.render.resolution_y=1000; s.render.resolution_percentage=100
    s.world=bpy.data.worlds.new(name+' world'); s.world.use_nodes=True
    s.world.node_tree.nodes.get('Background').inputs[0].default_value=(.62,.64,.70,1)
    s.world.node_tree.nodes.get('Background').inputs[1].default_value=.45
    s.view_settings.view_transform='AgX'
    return s

def instance(s,id,p=(0,0,0),yaw=0,scale=1):
    root=bpy.data.objects.new(id+'_instance',None); s.collection.objects.link(root)
    original=bpy.data.collections[id]
    for ob in original.objects:
        if ob.type!='MESH':continue
        du=ob.copy(); du.data=ob.data; s.collection.objects.link(du); du.parent=root
        du.matrix_basis=ob.matrix_basis.copy()
    root.location=p; root.rotation_euler.z=yaw; root.scale=(scale,)*3
    return root

def plane(s,size=200,z=-.07):
    mat=bpy.data.materials.get('felt_linen')
    mesh=bpy.data.meshes.new('studio_floor'); mesh.from_pydata([(-size,-size,z),(size,-size,z),(size,size,z),(-size,size,z)],[],[(0,1,2,3)]); mesh.materials.append(mat)
    uv=mesh.uv_layers.new()
    for d,v in zip(uv.data,[(0,0),(400,0),(400,400),(0,400)]):d.uv=v
    ob=bpy.data.objects.new('Studio cloth',mesh); s.collection.objects.link(ob)

def light(s,p,power,size,color=(1,.83,.64)):
    d=bpy.data.lights.new('Softbox','AREA'); d.energy=power; d.shape='DISK'; d.size=size; d.color=color
    ob=bpy.data.objects.new('Softbox',d); s.collection.objects.link(ob); ob.location=p; ob.rotation_euler=(Vector((0,0,0))-ob.location).to_track_quat('-Z','Y').to_euler()
    return ob

def camera(s,p,target,scale):
    d=bpy.data.cameras.new('Camera'); d.type='ORTHO'; d.ortho_scale=scale
    ob=bpy.data.objects.new('Camera',d); s.collection.objects.link(ob); ob.location=p; ob.rotation_euler=(Vector(target)-ob.location).to_track_quat('-Z','Y').to_euler();s.camera=ob

def render(s,name):
    if (ROOT/'art/preview_focus.txt').exists() and name not in (ROOT/'art/preview_focus.txt').read_text().split():return
    s.render.filepath=str(ROOT/'previews'/name);log('render '+name);bpy.ops.render.render(write_still=True);log('done '+name)

try:
    s=scene_new('01 — Animals');plane(s)
    instance(s,'sheep_ivory',(-1.4,0,0),-.2,1.05)
    instance(s,'taigan_dog',(.1,.15,0),-.2)
    instance(s,'wolf_gray',(1.6,.3,0),-.2)
    light(s,(-3,-4,7),850,5);light(s,(4,2,5),550,4,(.8,.88,1))
    camera(s,(5,-10,6.5),(0,0,.65),6.4)
    render(s,'animals_closeup.png')
    s=scene_new('04 — Bridge and barrels');plane(s)
    ob=instance(s,'bridge_rope_4m');ob.scale=(1.35,.58,1)
    instance(s,'barrel_large',(2.1,.4,0),0,.7)
    instance(s,'barrel_small',(1.85,-.25,0),0,.7)
    light(s,(-3,-4,7),950,5);light(s,(4,2,5),350,4,(.8,.88,1))
    camera(s,(5,-8,6),(0.3,0,.3),5.7)
    render(s,'bridge_reference.png')
    s=scene_new('05 — Embroidered edge');plane(s,200,-2)
    instance(s,'valley_landform')
    light(s,(-5,-24,8),1400,6);light(s,(5,-18,5),500,5,(.8,.88,1))
    camera(s,(2,-27,2),(0,-19,-.75),5.8)
    render(s,'border_reference.png')
    s=scene_new('06 — Sheep folds');plane(s)
    for pos,ang in [((-1.1,0,0),-.45),((0,0,0),2.8),((1.1,0,0),1.5)]:instance(s,'sheep_ivory',pos,ang)
    light(s,(-3,-4,7),850,5);light(s,(4,2,5),400,4,(.8,.88,1))
    camera(s,(4,-7,6),(0,0,.45),4.2)
    render(s,'sheep_reference.png')
    s=scene_new('03 — Felt material study');s.render.resolution_x=1600;s.render.resolution_y=1200;plane(s,200,-.35)
    instance(s,'meadow_tile_4m',(0,0,0),0,1)
    instance(s,'boulder_large',(-1.05,.65,.12),.3,.72)
    instance(s,'shrub_teal',(.75,.55,.12),.3,1.5)
    instance(s,'sheep_ivory',(.15,-.80,.12),-.25,1.05)
    light(s,(-3,-4,6),900,5,(1,.91,.80));light(s,(4,3,5),500,5,(.82,.89,1))
    camera(s,(5,-8,7),(0,0,.45),6.2)
    render(s,'felt_material_study.png')
    s=scene_new('07 — Felt yurt and shyrdak');plane(s,z=0)
    instance(s,'yurt_embroidered')
    instance(s,'rug_shyrdak',(0,-1.95,.001))
    instance(s,'kazan_felt',(1.95,-1.25,0),0,.85)
    light(s,(-3,-4,7),900,5,(1,.91,.80));light(s,(4,2,5),450,4,(.8,.88,1))
    camera(s,(5,-8,6),(0,-.1,.9),5.4)
    render(s,'camp_reference.png')
    s=scene_new('02 — First pasture');s.render.resolution_x=900;s.render.resolution_y=1500;plane(s,200,-2.65)
    for item in json.loads((ROOT/'data/level_01_art.json').read_text()):
        ob=instance(s,item['id'],(item['x'],-item['z'],item['y']),item['yaw'])
        sc=item['scale'];ob.scale=(sc[0],sc[2],sc[1])
    key=light(s,(-9,-6,15),2800,8,(1,.84,.66));light(s,(7,9,12),1700,10,(.75,.86,1))
    camera(s,(24,-24,24),(0,0,0),38)
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/taigan_presentations.blend'))
    render(s,'level_01_evening.png')
    log('RENDER COMPLETE')
except Exception:log(traceback.format_exc())
