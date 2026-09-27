"""Taigan original felt miniature asset library. Run inside Blender 4.5+.
Geometry is authored procedurally. Ivory needle-felt base color is AI-generated;
other PBR maps are deterministic procedural assets. See docs/art-direction.md.
Units: meters, Z up, animal front -Y. Godot GLB converts to Y up / front +Z.
"""
import bpy, math, random, json, traceback
from pathlib import Path
from mathutils import Vector, Euler
from math import sin, cos, pi, tau
ROOT=Path('/Users/sergei/projects/games/taigan')
LOG=ROOT/'art/build.log'
random.seed(20260925)
def log(s):
    with LOG.open('a') as f: f.write(str(s)+'\n')
    print(s,flush=True)
LOG.write_text('BUILD START\n')
M={}; library={}; manifest=[]
exec(compile((ROOT/'art/source/normalize_gltf.py').read_text(), 'normalize_gltf.py', 'exec'),globals())
_shared_namespace={'__name__':'shared_texture_helper'}
exec(compile((ROOT/'art/source/share_gltf_textures.py').read_text(), 'share_gltf_textures.py', 'exec'),_shared_namespace)
share_textures=_shared_namespace['share_textures']

def material(name,color=None,rough=.85):
    mat=bpy.data.materials.new(name); mat.use_nodes=True
    bs=mat.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Roughness'].default_value=rough
    bs.inputs['Specular IOR Level'].default_value=.26
    if color:
        bs.inputs['Base Color'].default_value=(*color,1)
        mat.diffuse_color=(*color,1)
    else:
        colors={
        'wool_ivory':(1.0,.97,.88),'wool_snow':(1.0,1.0,.98),
        'sheep_face':(.008,.009,.008),'sheep_wool_ivory':(1.0,.99,.94),'sheep_wool_snow':(1.0,1.0,.98),
        'felt_charcoal':(.035,.032,.028),'felt_ash':(.48,.49,.46),
        'felt_wolf':(.17,.19,.18),'felt_muzzle':(.48,.50,.44),
        'felt_tan':(.50,.30,.14),'felt_ochre':(.31,.25,.044),
        'felt_meadow':(.9,.94,.83),'felt_sage':(.96,1.0,.95),
        'felt_pine':(.055,.24,.17),'felt_teal':(.08,.34,.27),
        'felt_rust':(.48,.095,.065),'felt_gold':(.69,.43,.07),
        'felt_red':(.44,.045,.055),'felt_linen':(.83,.71,.51),
        'felt_water':(.095,.29,.35),'felt_water_light':(.35,.59,.62),
        'wood':(.26,.135,.061),'felt_border_red':(.27,.041,.052),'felt_border_teal':(.045,.18,.15),'felt_border_linen':(.72,.61,.44),'felt_border_ash':(.30,.31,.28),'felt_applique':(.86,.75,.55),'felt_rose':(.60,.29,.24),'felt_soil':(.33,.21,.12),'stone':(.9,.94,.98)}
        TINTS.update(colors)
        photo=name in colors
        scan='sheep_merino_v1' if name.startswith('sheep_wool') else 'meadow_pressed_v4' if name in ['felt_meadow','felt_sage'] else ('stone_matted_v3' if name=='stone' else 'needle_felt_ivory_v2')
        normal_scan='needle_felt_normal_v2' if scan=='needle_felt_ivory_v2' else scan+'_normal'
        for suffix,target in [('color','Base Color'),('roughness','Roughness'),('normal','Normal')]:
            path=ROOT/f'assets/textures/{scan}.png' if photo and suffix=='color' else (ROOT/f'assets/textures/{normal_scan}.png' if photo and suffix=='normal' else ROOT/f'assets/textures/{name}_{suffix}.png')
            if not path.exists() and suffix=='roughness':path=ROOT/'assets/textures/felt_linen_roughness.png'
            im=bpy.data.images.load(str(path),check_existing=True)
            if suffix!='color':im.colorspace_settings.name='Non-Color'
            tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=im;tex.label=suffix
            if suffix=='normal':
                normal=mat.node_tree.nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=(.13 if name.startswith('sheep_wool') else .15 if name.startswith('wool_') else .18 if name.startswith('felt_border') or name=='felt_applique' or name=='wood' else (.12 if name in ['felt_meadow','felt_sage','felt_ochre'] else (.16 if name=='stone' else .22))) if photo else .5
                mat.node_tree.links.new(tex.outputs['Color'],normal.inputs['Color'])
                mat.node_tree.links.new(normal.outputs['Normal'],bs.inputs['Normal'])
            elif suffix=='color' and photo:
                mix=mat.node_tree.nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1
                mix.inputs[2].default_value=(*colors[name],1)
                mat.node_tree.links.new(tex.outputs['Color'],mix.inputs[1]);mat.node_tree.links.new(mix.outputs[0],bs.inputs['Base Color'])
            else:mat.node_tree.links.new(tex.outputs['Color'],bs.inputs[target])
        bs.inputs['Sheen Weight'].default_value=.08
        bs.inputs['Sheen Roughness'].default_value=.8
        bs.inputs['Specular IOR Level'].default_value=.12
    M[name]=mat
    return mat

class Geo:
    def __init__(self): self.v=[]; self.f=[]; self.uv=[]; self.mi=[]; self.mats=[]
    def add(self,vs,fs,uv,mat):
        offset=len(self.v); self.v.extend(vs); self.uv.extend(uv)
        if mat not in self.mats:self.mats.append(mat)
        idx=self.mats.index(mat)
        for f in fs:self.f.append(tuple(offset+i for i in f)); self.mi.append(idx)
    def ell(self,p,s,mat,n=24,r=14,e=1,rot=(0,0,0),jitter=0):
        vs=[]; uv=[]; fs=[]; matrix=Euler(rot).to_matrix()
        sp=lambda a: math.copysign(abs(a)**e,a)
        phase=random.random()*8
        for i in range(r+1):
            lat=-pi/2+pi*i/r
            for j in range(n+1):
                a=tau*j/n
                q=Vector((s[0]*sp(cos(lat))*sp(cos(a)),s[1]*sp(cos(lat))*sp(sin(a)),s[2]*sp(sin(lat))))
                q*=1+jitter*(sin(a*5+phase)*cos(lat*3)+sin(lat*7+a*3)*.4)
                q=matrix@q+Vector(p); vs.append(tuple(q)); uv.append((j/n,i/r))
        for i in range(r):
            for j in range(n):
                k=i*(n+1)+j; fs.append((k,k+1,k+n+2,k+n+1))
        self.add(vs,fs,uv,mat)
        self._felt_surface=(vs,fs)
    def tube(self,points,radius,mat,sides=8):
        ps=[Vector(p) for p in points]; vs=[]; uv=[]; fs=[]
        rs=radius if isinstance(radius,(list,tuple)) else [radius]*len(ps)
        dist=0
        for i,p in enumerate(ps):
            t=(ps[min(i+1,len(ps)-1)]-ps[max(i-1,0)]).normalized()
            ref=Vector((0,0,1)) if abs(t.z)<.9 else Vector((0,1,0))
            u=t.cross(ref).normalized(); v=t.cross(u).normalized()
            if i:dist+=(p-ps[i-1]).length
            for j in range(sides+1):
                a=tau*j/sides; vs.append(tuple(p+rs[i]*(u*cos(a)+v*sin(a)))); uv.append((j/sides,dist*2))
        for i in range(len(ps)-1):
            for j in range(sides):
                k=i*(sides+1)+j; fs.append((k,k+1,k+sides+2,k+sides+1))
        fs.extend([tuple(reversed(range(sides))),tuple((len(ps)-1)*(sides+1)+j for j in range(sides))])
        self.add(vs,fs,uv,mat)
    def fuzz(self,p,s,mat,count=800,length=.038,surface=False,width=1.0):
        center=Vector(p)
        for i in range(count):
            z=random.uniform(-1,1);t=random.uniform(0,tau);r=math.sqrt(1-z*z)
            q=Vector((s[0]*r*cos(t),s[1]*r*sin(t),s[2]*z))
            n=Vector((q.x/(s[0]*s[0]),q.y/(s[1]*s[1]),q.z/(s[2]*s[2]))).normalized()
            tangent=n.cross(Vector((random.random(),random.random(),random.random()))).normalized()
            l=length*random.uniform(.7,1.8);base=center+q
            if surface:
                sv,sf=self._felt_surface
                face=random.choice(sf);va,vb,vc=[Vector(sv[j]) for j in (face[0],face[1],face[2])]
                u,v=random.random(),random.random()
                if u+v>1:u,v=1-u,1-v
                base=va+(vb-va)*u+(vc-va)*v
                n=(vb-va).cross(vc-va).normalized()
                tangent=n.cross(Vector((random.random(),random.random(),random.random()))).normalized()
            side=n.cross(tangent)
            pts=[base,base+n*l*.35+tangent*l*.2,base+n*l*.48+tangent*l*.55+side*l*.18,base+n*l*.25+tangent*l*.85+side*l*.3]
            self.tube(pts,[.0022*width,.0018*width,.0012*width,.0003*width],mat,4)

    def ring(self,p,rad,zrad,tube,mat,n=64):
        self.tube([(p[0]+rad*cos(tau*i/n),p[1]+rad*sin(tau*i/n),p[2]+zrad*sin(tau*i/n)) for i in range(n+1)],tube,mat)
    def box(self,p,s,mat,rot=(0,0,0)):
        self.ell(p,s,mat,n=24,r=12,e=.19,rot=rot)
    def lathe(self,profile,mat,n=80,start=0,end=tau):
        vs=[]; uv=[]; fs=[]
        for i,(rad,z) in enumerate(profile):
            for j in range(n+1):
                a=start+(end-start)*j/n; vs.append((rad*cos(a),rad*sin(a),z)); uv.append((j/n*4,i/max(1,len(profile)-1)))
        for i in range(len(profile)-1):
            for j in range(n):
                k=i*(n+1)+j; fs.append((k,k+1,k+n+2,k+n+1))
        self.add(vs,fs,uv,mat)
    def object(self,name,col,parent=None):
        mesh=bpy.data.meshes.new(name); mesh.from_pydata(self.v,[],self.f); mesh.update()
        for m in self.mats:mesh.materials.append(M[m])
        uv=mesh.uv_layers.new(name='UVMap')
        for poly,idx in zip(mesh.polygons,self.mi):
            poly.material_index=idx; poly.use_smooth=True
            for li in poly.loop_indices:
                coord=self.uv[mesh.loops[li].vertex_index]
                fiber_scale=(3.4 if self.mats[idx].startswith('wool_') else 2.4 if self.mats[idx].startswith('felt_border') or self.mats[idx] in ['wood','felt_applique'] else (1.0 if self.mats[idx] in ['felt_meadow','felt_sage','felt_ochre'] else (2.0 if self.mats[idx]=='stone' else 2.4))) if self.mats[idx] in TINTS else 1
                uv.data[li].uv=(coord[0]*fiber_scale,coord[1]*fiber_scale)
        ob=bpy.data.objects.new(name,mesh); col.objects.link(ob)
        if parent:ob.parent=parent
        return ob

class Asset:
    def __init__(self,name,category):
        self.name=name; self.category=category; self.col=bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(self.col)
        self.root=bpy.data.objects.new(name,None); self.col.objects.link(self.root); self.objects=[]
    def part(self,name,g,pivot=None):
        ob=g.object(name,self.col,self.root)
        if pivot:
            for v in ob.data.vertices:v.co-=Vector(pivot)
            ob.location=pivot
        self.objects.append(ob); return ob
    def finish(self):
        bpy.ops.object.select_all(action='DESELECT')
        self.root.select_set(True)
        for ob in self.objects:ob.select_set(True)
        bpy.context.view_layer.objects.active=self.root
        tri=sum(sum(len(p.vertices)-2 for p in ob.data.polygons) for ob in self.objects)
        mods=[]
        for ob in self.objects:
            if len(ob.data.polygons)>1500 and self.category not in ['terrain','animal','foliage','architecture','prop']:
                mod=ob.modifiers.new('Mobile LOD0','DECIMATE');mod.ratio=.42;mods.append((ob,mod))
        bpy.ops.export_scene.gltf(filepath=str(ROOT/f'assets/models/{self.name}.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_extras=True)
        normalize_gltf(ROOT/f'assets/models/{self.name}.glb')
        share_textures(ROOT/f'assets/models/{self.name}.glb')
        for ob,mod in mods:ob.modifiers.remove(mod)
        entry={'id':self.name,'category':self.category,'source_triangles':tri,'game_simplification':0.42 if mods else 1.0,'parts':[o.name for o in self.objects],'file':f'assets/models/{self.name}.glb','units':'meters','lod':'Godot automatic LOD on import'}
        manifest.append(entry); library[self.name]=self
        # Library laid out only after export; asset local origin remains centered at ground.
        idx=len(manifest)-1; self.root.location=((idx%7)*6,(idx//7)*6,0)
        log(f'EXPORTED {self.name} / {tri:,} triangles')
        return self

def seam(g,points,spacing=.16,width=.065,mat='rope'):
    for a,b in zip(points[:-1],points[1:]):
        a=Vector(a); b=Vector(b); d=b-a; steps=max(1,int(d.length/spacing))
        side=Vector((-d.y,d.x,.15)).normalized()*width
        for i in range(steps):
            p=a+d*((i+.5)/steps); g.tube([p-side,p+Vector((0,0,.018)),p+side],.010,mat,6)

def horn_scroll(g,center,scale=1,plane='XY',mat='rope'):
    for sign in [-1,1]:
        pts=[]
        for i in range(42):
            t=i/41; a=t*1.7*pi; rad=(.22*(1-t)+.025)*scale
            x=sign*(.20*scale+rad*cos(a)); z=rad*sin(a)
            pts.append((center[0]+x,center[1]+z,center[2]) if plane=='XY' else (center[0]+x,center[1],center[2]+z))
        g.tube(pts,.026*scale,mat,8)

# ANIMALS: separate limb meshes and pivots support runtime gait without skinning.
def sheep(name='sheep_ivory',dark=False):
    a=Asset(name,'animal');g=Geo();wool='sheep_wool_snow' if dark else 'sheep_wool_ivory';face='sheep_face'
    # Reference: a compact padded block of wool with soft interrupted lobes.
    # The fleece remains a single surface, never separate transverse cylinders.
    center=(0,.012,.395);size=(.365,.43,.325)
    g.ell(center,size,wool,112,72,e=.82,jitter=.005)
    sculpted=[]
    for x,y,z in g.v:
        dx=x;dy=y-center[1];dz=z-center[2]
        side=abs(dx)/size[0];upper=max(0,dz/size[2])
        # Broad folds wander across each flank; they fade before meeting underneath.
        crease=0.0
        for cy,slant,depth in [(-.145,.18,.062),(.125,-.13,.054)]:
            offset=y-cy-slant*x-.028*sin(x*8+z*3+cy*4)
            mask=.48+.40*side+.12*sin(z*7+x*5)
            crease+=depth*math.exp(-(offset/.046)**2)*mask
        radial=max(.001,math.sqrt(dx*dx+dz*dz))
        # Small non-periodic dents and soft clumps on the top of the fleece.
        lumps=.007*sin(x*18+y*13)*sin(z*17-y*11)+.004*cos(x*29-z*17+y*5)
        d=crease-lumps
        sculpted.append((x-dx/radial*d,y+.004*sin(x*11+z*9),z-dz/radial*d))
    g.v=sculpted;g._felt_surface=(list(g.v),list(g.f))
    g.fuzz(center,size,wool,3400,.009,surface=True,width=.28)
    g.tube([(0,.411,.34),(0,.49,.348),(0,.525,.359)],[.034,.031,.022],face,12)
    a.part('Body',g)
    h=Geo();h.ell((0,-.414,.565),(.107,.13,.139),face,40,28,jitter=.012)
    h.ell((0,-.515,.492),(.081,.082,.075),face,32,22,jitter=.008)
    for side in [-1,1]:
        h.ell((side*.112,-.405,.682),(.076,.039,.048),face,28,18,rot=(0,side*-.32,side*.12),jitter=.02)
        h.ell((side*.074,-.510,.586),(.010,.007,.011),'eye',20,14)
        h.ell((side*.076,-.516,.590),(.003,.003,.0035),'highlight',12,8)
    # Wool meets the head without a separate white hat or floppy oversized ears.
    h.ell((0,-.345,.670),(.100,.092,.071),wool,28,18,jitter=.025)
    h.v=[(x,y,z-.055) for x,y,z in h.v]
    a.part('Head',h,(0,-.35,.485))
    for side in [-1,1]:
        for front in [-1,1]:
            pivot=(side*.225,front*.245,.23);l=Geo()
            l.tube([(pivot[0],pivot[1],.020),(pivot[0]+side*.006,pivot[1],.23)],[.034,.039],face,16)
            l.ell((pivot[0],pivot[1],.026),(.036,.039,.026),face,20,12)
            a.part(('Front' if front<0 else 'Rear')+('Left' if side<0 else 'Right'),l,pivot)
    return a.finish()

def canine(name,wolf):
    a=Asset(name,'animal');base='felt_wolf' if wolf else 'felt_charcoal';muzzle='felt_muzzle' if wolf else 'felt_charcoal'
    g=Geo();body=(.235,.58,.27) if wolf else (.165,.62,.22);height=.64 if wolf else .63
    g.ell((0,.04,height),body,base,48,28,jitter=.018)
    g.ell((0,-.35,.72),(.245,.28,.32) if wolf else (.185,.24,.30),base,36,24,jitter=.02)
    g.fuzz((0,.04,height),tuple(v*1.01 for v in body),base,2400,.028 if wolf else .04)
    g.fuzz((0,-.35,.72),(.25,.28,.32) if wolf else (.19,.24,.30),base,1800,.036)
    if wolf:g.ell((0,-.52,.68),(.15,.10,.22),'felt_muzzle',28,18,jitter=.025)
    a.part('Body',g)
    h=Geo();hc=(0,-.59,.94) if wolf else (0,-.61,.98)
    hs=(.19,.245,.205) if wolf else (.135,.215,.155)
    h.ell(hc,hs,base,40,28,jitter=.018);h.fuzz(hc,tuple(v*1.015 for v in hs),base,1100,.022)
    h.ell((0,-.80,.875 if wolf else .94),(.125,.225,.105) if wolf else (.087,.20,.077),muzzle,32,20,jitter=.018)
    h.ell((0,-.981,.902 if wolf else .967),(.067,.049,.048) if wolf else (.047,.041,.034),'nose',28,18)
    for side in [-1,1]:
        if wolf:
            h.tube([(side*.135,-.54,1.065),(side*.16,-.515,1.25),(side*.18,-.50,1.35)],[.095,.05,.004],base,16)
            h.tube([(side*.135,-.622,1.08),(side*.16,-.558,1.24),(side*.177,-.513,1.31)],[.043,.020,.001],'felt_ash',12)
        else:
            h.ell((side*.142,-.515,.95),(.058,.13,.205),base,28,20,rot=(.32,side*.18,0),jitter=.025)
            h.fuzz((side*.142,-.515,.95),(.061,.133,.208),base,400,.044)
        ex=side*(.142 if wolf else .102);ey=-.761 if wolf else -.753;ez=1.009 if wolf else 1.027
        h.ell((ex,ey,ez),(.031,.017,.027) if wolf else (.018,.012,.016),'amber',20,14)
        h.ell((ex,ey-.014,ez),(.012,.007,.017) if wolf else (.008,.006,.010),'eye',16,12)
        h.ell((ex-side*.006,ey-.02,ez+.009),(.004,.003,.004),'highlight',12,8)
    a.part('Head',h,(0,-.43,.91))
    for side in [-1,1]:
        for front in [-1,1]:
            x=side*(.165 if wolf else .122);y=front*.38;pivot=(x,y,.53);l=Geo()
            points=[(x,y,.53),(x,y+(.08 if front>0 else -.012),.30),(x,y+(.00 if front>0 else -.035),.105)]
            l.tube(points,[.073 if wolf else .050,.048 if wolf else .028,.038 if wolf else .024],base,16)
            l.ell((x,y-.039,.060),(.065,.105,.061) if wolf else (.041,.081,.042),base,24,16)
            a.part(('Front' if front<0 else 'Rear')+('Left' if side<0 else 'Right'),l,pivot)
    tail=Geo()
    points=[(0,.55,.74),(.05,.80,.67),(.16,1.00,.60),(.20,1.16,.68)] if wolf else [(0,.61,.68),(.05,.88,.69),(.16,1.13,.84),(.20,1.23,1.01)]
    tail.tube(points,[.14,.14,.095,.014] if wolf else [.080,.070,.045,.009],base,18)
    for i in range(18):
        t=i/18;point=Vector(points[0]).lerp(Vector(points[-2]),t)
        tail.ell(point,(.055,.095,.055),base,16,12,jitter=.04)
    a.part('Tail',tail,(0,.55,.70))
    return a.finish()

def rock(name,size,seed):
    a=Asset(name,'prop');g=Geo();rng=random.Random(seed)
    g.ell((0,0,size[2]*.78),size,'stone',44,30,e=.78,jitter=.08,rot=(.08,-.1,.2))
    g.fuzz((0,0,size[2]*.78),tuple(v*1.01 for v in size),'stone',6500,.025,surface=True)
    for i in range(7):
        x=rng.uniform(-.6,.6)*size[0];y=rng.uniform(-.6,.6)*size[1]
        g.ell((x,y,.03),(.12,.10,.06),'felt_meadow',16,10)
    a.part('FeltStone',g);return a.finish()

def wall(name,curve=False):
    a=Asset(name,'architecture'); g=Geo(); length=3.0
    for row in range(3):
        count=6 if row!=1 else 7
        for j in range(count):
            x=(j-(count-1)/2)*.48
            y=(.25*x*x) if curve else 0
            g.ell((x,y,.18+row*.29),(.25,.23,.16),'stone',20,12,e=.38,jitter=.04,rot=(0,random.uniform(-.06,.06),math.atan(.5*x) if curve else random.uniform(-.05,.05)))
    for i in range(7):
        x=random.uniform(-1.4,1.4); g.ell((x,-.24,.055),(.12,.09,.05),'felt_meadow',12,8)
    a.part('Stonework',g); return a.finish()

def gate():
    a=Asset('gate_openable','architecture'); g=Geo()
    for x in [-1.12,1.12]:
        g.box((x,0,.60),(.11,.13,.60),'wood'); g.ell((x,0,1.21),(.12,.14,.025),'wood',20,8)
        for z in [.25,.85]:g.ring((x,0,z),.133,0,.018,'rope',24)
    a.part('Posts',g)
    for sign in [-1,1]:
        leaf=Geo()
        for i in range(5):leaf.box((sign*(.12+i*.195),0,.53),(.086,.08,.50-random.uniform(0,.05)),'wood')
        for z in [.25,.8]:leaf.box((sign*.54,.095,z),(.52,.045,.04),'wood')
        leaf.tube([(sign*.09,.13,.18),(sign*1.0,.13,.90)],.035,'wood',8)
        for z in [.28,.83]:leaf.ell((sign*.97,-.085,z),(.030,.02,.03),'brass',12,8)
        a.part('GateLeft' if sign<0 else 'GateRight',leaf,(sign*1.02,0,0))
    return a.finish()

def bridge():
    a=Asset('bridge_rope_4m','architecture'); g=Geo()
    rng=random.Random(1805)
    for i in range(9):
        y=-2.0+i*.50; z=.22+.20*(1-(y/2)**2)
        g.ell((rng.uniform(-.025,.025),y,z),(.96+rng.uniform(-.03,.03),.232,.090),'wood',n=36,r=16,e=.33,jitter=.018,rot=(0,0,rng.uniform(-.013,.013)))
        g.fuzz((0,y,z),(.96,.232,.09),'wood',160,.012,surface=True)
        for side in [-1,1]:
            for j in range(12):
                x=-.80+j*.145
                g.tube([(x,y+side*.218,z+.035),(x+.01,y+side*.204,z+.085),(x+.02,y+side*.181,z+.093)],.005,'felt_tan',5)
    for x in [-.91,.91]:
        g.ell((x,0,.12),(.115,2.26,.13),'wood',36,14,e=.4,jitter=.015)
        # Low padded side beams, not tall rope railings.
        g.tube([(x,-2.08,.45),(x,-1.05,.56),(x,0,.61),(x,1.05,.56),(x,2.08,.45)],.085,'wood',14)
        for y in [-2.06,2.06]:
            g.tube([(x,y,-.03),(x+.012,y,.39),(x,y,.82)],[.13,.13,.11],'wood',20)
            g.ell((x,y,.825),(.12,.12,.027),'felt_tan',24,10)
            for rad in [.04,.075,.105]:g.ring((x,y,.849),rad,0,.004,'wood',28)
            for z in [.30,.35]:g.ring((x,y,z),.14,0,.013,'rope',24)
    a.part('Bridge',g); return a.finish()

def flat_horn(g,center,scale=1,mat='felt_applique',mapper=None):
    # Paired ram horns, joined at the stem, cut from a flat sheet of felt.
    for sign in [-1,1]:
        path=[]
        for i in range(17):
            t=i/16
            x=3*(1-t)**2*t*.03+3*(1-t)*t*t*.30+t**3*.551
            y=(1-t)**3*.30+3*(1-t)**2*t*(-.14)+3*(1-t)*t*t*(-.25)+t**3*(-.24185)
            path.append((sign*x,y))
        for i in range(65):
            t=i/64; rr=.34*(1-t)+.065; ang=-pi/2+1.87*pi*t
            path.append((sign*(.38+rr*cos(ang))*1.45,.07+rr*.77*sin(ang)))
        vs=[];fs=[];uv=[]
        for i,(x,y) in enumerate(path):
            prev=Vector(path[max(0,i-1)]);nxt=Vector(path[min(len(path)-1,i+1)])
            tangent=(nxt-prev).normalized();side=Vector((-tangent.y,tangent.x))
            for j in range(9):
                theta=tau*j/8;w=.075*(.72+.28*sin(pi*i/(len(path)-1)))
                u=(x+side.x*w*cos(theta))*scale;v=(y+side.y*w*cos(theta))*scale
                h=.009+.006*sin(theta)
                vs.append(mapper(u,v,h) if mapper else (center[0]+u,center[1]+v,center[2]+h))
                uv.append((u,v))
        for i in range(len(path)-1):
            for j in range(8):
                k=i*9+j;fs.append((k,k+1,k+10,k+9))
        g.add(vs,fs,uv,mat)

def yurt():
    a=Asset('yurt_embroidered','architecture');g=Geo();rad=1.65
    start=-pi/2+.25;end=3*pi/2-.25
    # Soft thick felt wall, with a real doorway and a rounded shoulder.
    wall_profile=[(rad-.05,.025),(rad+.025,.13),(rad+.04,.52),(rad+.015,1.09),(rad-.025,1.24)]
    def dense(profile,steps=6):
        return [(r+(r2-r)*t/steps,z+(z2-z)*t/steps) for (r,z),(r2,z2) in zip(profile,profile[1:]) for t in range(steps)]+[profile[-1]]
    g.lathe(dense(wall_profile),'wool_ivory',160,start,end)
    roof=[(1.625,1.22),(1.60,1.32),(1.48,1.49),(1.28,1.69),(1.03,1.88),(.77,2.045),(.52,2.16),(.36,2.20)]
    g.lathe(dense(roof),'wool_ivory',160)
    g._felt_surface=(list(g.v),list(g.f))
    g.fuzz((0,0,1.5),(1.65,1.65,.7),'wool_ivory',1800,.007,surface=True)
    # Open tunduk with a substantial felt-wrapped ring and crossed arched ribs.
    g.ring((0,0,2.215),.36,0,.043,'felt_tan',96)
    g.lathe([(.355,2.20),(.353,2.10),(.315,2.10),(.315,2.205)],'felt_tan',96)
    for axis in [0,1]:
        for offset in [-.105,0,.105]:
            reach=math.sqrt(.315**2-offset**2);pts=[]
            for i in range(25):
                t=-1+2*i/24;q=t*reach;z=2.215+.105*(1-t*t)
                pts.append((q,offset,z) if axis==0 else (offset,q,z+.006))
            g.tube(pts,.016,'felt_tan',8)
    # Eight restrained roof seams follow the felt dome, not bright spokes.
    for j in range(8):
        angle=tau*j/8
        g.tube([(rr*cos(angle),rr*sin(angle),z+.012) for rr,z in roof],.012,'felt_border_linen',8)
        for rr,z in roof[1:-1]:
            g.tube([(rr*cos(angle-.018),rr*sin(angle-.018),z+.016),(rr*cos(angle+.018),rr*sin(angle+.018),z+.016)],.004,'felt_tan',5)
    # A broad red felt band and small flat cream appliques.
    g.lathe(dense([(1.712,.32),(1.712,.67)],10),'felt_border_red',160,start,end)
    for z in [.12,.31,.69,1.22]:
        g.tube([(1.68*cos(start+(end-start)*i/128),1.68*sin(start+(end-start)*i/128),z) for i in range(129)],.016,'felt_border_red',8)
    for j in range(11):
        angle=start+.24+j*(end-start-.48)/10
        def mapped(u,v,h,angle=angle):
            an=angle+u/1.70;return ((1.718+h)*cos(an),(1.718+h)*sin(an),.495+v)
        flat_horn(g,(0,0,0),.38,mapper=mapped)
    # Low wool-wrapped door frame and a rolled cream felt door covering.
    for x in [-.405,.405]:g.box((x,-1.605,.59),(.055,.055,.59),'felt_tan')
    g.box((0,-1.605,1.19),(.455,.06,.05),'felt_tan')
    g.box((0,-1.58,.055),(.38,.16,.025),'felt_tan')
    g.tube([(-.35,-1.665,1.08),(-.16,-1.68,1.06),(.04,-1.675,1.055),(.21,-1.68,1.067),(.35,-1.665,1.083)],[.070,.076,.073,.081,.068],'wool_ivory',24)
    # Loaded cloth: broad sag between roof seams, folds at the foot and
    # compression beneath the binding. Apply to cloth, seams and applique together.
    shaped=[]
    for x,y,z in g.v:
        angle=math.atan2(y,x);rr=math.hypot(x,y)
        weight=min(1,(rr/.8)**2)
        basefold=math.exp(-((z-.14)/.22)**2)
        wallweight=max(0,min(1,(1.4-z)/.24))
        radial=1+weight*(.019*sin(3*angle+.7)+.011*sin(7*angle+z*1.3))
        radial+=wallweight*(.021*basefold*sin(17*angle+z*6)+.009*sin(11*angle+z*2))
        radial-=.014*math.exp(-((z-.69)/.07)**2)
        roofweight=max(0,min(1,(z-1.2)/.22))*weight
        panels=.5-.5*cos(8*angle)
        sag=weight*(.045*sin(3*angle+.4)+.022*sin(5*angle+.8))
        sag-=roofweight*(.065*panels+.038*math.exp(-((angle+.4)/.65)**2))
        fade=min(1,max(0,z/.23))
        shaped.append((x*radial+.028*sin(z*1.7),y*radial,z+sag*fade))
    g.v=shaped
    a.part('Yurt',g);return a.finish()

def kazan():
    a=Asset('kazan_felt','prop');g=Geo()
    # Open round cauldron, rendered as charcoal felt throughout.
    g.lathe([(.03,.10),(.23,.12),(.37,.23),(.43,.39),(.44,.49),(.405,.49),(.39,.37),(.32,.25),(.19,.18),(.03,.17)],'felt_wolf',72)
    g._felt_surface=(list(g.v),list(g.f))
    g.fuzz((0,0,.3),(.44,.44,.25),'felt_wolf',2100,.008,surface=True)
    g.ring((0,0,.49),.422,0,.025,'felt_ash',64)
    for side in [-1,1]:
        g.tube([(side*(.44+.11*sin(pi*i/24)),.12*cos(pi*i/24),.445) for i in range(25)],.027,'felt_wolf',10)
    for i in range(3):
        ang=i*tau/3;g.ell((.26*cos(ang),.26*sin(ang),.06),(.13,.12,.07),'stone',24,16,jitter=.025)
    shaped=[]
    for x,y,z in g.v:
        angle=math.atan2(y,x)
        # A hand-felted, slightly compressed bowl with a gently uneven rim.
        k=1+.028*sin(angle*3+.8)+.012*sin(angle*7+z*4)
        shaped.append((x*k*1.025,y*k*.975,z+.010*sin(angle*4+.4)*min(1,z/.3)))
    g.v=shaped
    a.part('FeltCauldron',g);return a.finish()

def barrel(name,small=False):
    a=Asset(name,'prop'); g=Geo(); r=.24 if small else .32; h=.62 if small else .86
    for j in range(16):
        an=tau*j/16; pts=[]
        for k in range(7):
            z=h*k/6; rr=r*(.86+.14*sin(pi*k/6)); pts.append((rr*cos(an),rr*sin(an),z))
        g.tube(pts,[r*.21]*7,'wood',12)
        for k in range(9):
            z=h*(.08+k*.10);rr=r*(.86+.14*sin(pi*z/h))+r*.18
            g.tube([(rr*cos(an-.03),rr*sin(an-.03),z),(rr*cos(an+.04),rr*sin(an+.04),z+.015)],.006,'felt_tan',5)
    for z in [h*.13,h*.30,h*.77,h*.91]:g.ring((0,0,z),r*(.86+.14*sin(pi*z/h))+.027,0,.022,'rope',40)
    g.ell((0,0,h), (r*.86,r*.86,.025),'wood',32,8,e=.4)
    g.fuzz((0,0,h),(r*.86,r*.86,.025),'wood',280,.012,surface=True)
    a.part('Barrel',g); return a.finish()

def rug():
    a=Asset('rug_shyrdak','prop');g=Geo();rng=random.Random(64012)
    for name,color in [('rug_wool_fiber',(.29,.061,.068)),('rug_wool_fiber_light',(.35,.086,.09))]:
        mat=material(name,color,1.0)
        mat.node_tree.nodes.get('Principled BSDF').inputs['Specular IOR Level'].default_value=.05
    # Thin compressed felt sheet. Rounded worn corners, no rim or ornament.
    def point(u,v,top=True):
        corner=(abs(u)*abs(v))**8
        x=.72*u*(1-.035*corner)+.006*sin(v*7)*abs(u)**4
        y=.49*v*(1-.045*corner)+.006*sin(u*8+.8)*abs(v)**5
        lift=.020*math.exp(-((u-.88)/.25)**2-((v+.9)/.32)**2)
        lift+=.004*(.5+.5*sin(u*8+v*4))*max(abs(u),abs(v))**8
        compression=math.exp(-((u/.7)**2+(v/.85)**2))
        thickness=.013-.005*compression+.0015*sin(u*13+v*9)
        z=.001+lift+(thickness if top else 0)
        if top:z+=.0018*sin(x*32+y*19)*sin(y*38-x*11)
        return (x,y,z)
    nx,ny=64,44;vs=[];fs=[]
    for top in [True,False]:
        for j in range(ny+1):
            for i in range(nx+1):vs.append(point(-1+2*i/nx,-1+2*j/ny,top))
    layer=(nx+1)*(ny+1)
    for j in range(ny):
        for i in range(nx):
            k=j*(nx+1)+i
            fs.append((k,k+1,k+nx+2,k+nx+1))
            fs.append((layer+k+nx+1,layer+k+nx+2,layer+k+1,layer+k))
    boundary=list(range(nx+1))+[j*(nx+1)+nx for j in range(1,ny+1)]+[ny*(nx+1)+i for i in range(nx-1,-1,-1)]+[j*(nx+1) for j in range(ny-1,0,-1)]
    for i,k in enumerate(boundary):
        q=boundary[(i+1)%len(boundary)];fs.append((k,layer+k,layer+q,q))
    g.add(vs,fs,[(x*1.25,y*1.25) for x,y,z in vs],'felt_border_red')
    # Short interlocked wool fibres, lying on the cloth, never a hanging fringe.
    for i in range(2400):
        u,v=rng.uniform(-.999,.999),rng.uniform(-.999,.999)
        x,y,z=point(u,v);ang=rng.uniform(0,tau);length=rng.uniform(.007,.019)
        pts=[]
        for t in [0,.33,.66,1]:
            pts.append((x+cos(ang)*length*t,y+sin(ang)*length*t,z+.0004+.0022*sin(pi*t)))
        g.tube(pts,[.00065,.0008,.00065,.00015],'rug_wool_fiber_light' if i%5==0 else 'rug_wool_fiber',3)
    a.part('PlainFeltMat',g);return a.finish()

def shrub(name,mat,seed):
    random.seed(seed); a=Asset(name,'foliage'); g=Geo()
    # Low felt crowns with short corded folds, not a pile of identical balls.
    for i in range(9):
        angle=i*2.4; r=.25 if i<7 else .09
        p=(r*cos(angle),r*sin(angle),.20+(.14 if i>=7 else random.uniform(-.02,.045)))
        radius=(random.uniform(.15,.20),random.uniform(.14,.19),random.uniform(.20,.26))
        g.ell(p,radius,mat,32,24,e=.9,jitter=.025)
        g.fuzz(p,radius,mat,550,.015,surface=True)
        for j in range(7):
            az=j*tau/7+.2*sin(i)
            pts=[]
            for k in range(17):
                t=.18+(pi-.36)*k/16
                pts.append((p[0]+radius[0]*1.01*sin(t)*cos(az),p[1]+radius[1]*1.01*sin(t)*sin(az),p[2]+radius[2]*cos(t)))
            g.tube(pts,.014,mat,6)
    a.part('Shrub',g); return a.finish()

def tuft(name,reeds=False):
    a=Asset(name,'foliage'); g=Geo()
    for i in range(19 if not reeds else 12):
        t=i*2.4; r=random.uniform(.01,.15); h=random.uniform(.18,.42)*(2 if reeds else 1)
        pts=[(r*cos(t),r*sin(t),0),((r+.05)*cos(t),(r+.05)*sin(t),h*.65),((r+.11)*cos(t),(r+.11)*sin(t),h)]
        g.tube(pts,[.035,.024,.001],'felt_teal' if not reeds else 'felt_meadow',7)
        if reeds:g.ell(pts[1],(.027,.027,.12),'felt_tan',12,8)
    a.part('Leaves',g); return a.finish()

def flowers():
    a=Asset('flowers_daisy','foliage'); g=Geo()
    for i in range(6):
        x=random.uniform(-.22,.22); y=random.uniform(-.22,.22); z=random.uniform(.18,.37)
        g.tube([(x,y,0),(x+.02,y,z)],.012,'felt_meadow',6)
        for j in range(6):
            t=tau*j/6; g.ell((x+.055*cos(t),y+.055*sin(t),z),(.048,.028,.019),'wool_ivory',12,8,rot=(0,.1,t))
        g.ell((x,y,z+.012),(.03,.03,.018),'felt_gold',14,8)
    a.part('Flowers',g); return a.finish()

def terrain(name,mat):
    a=Asset(name,'terrain'); g=Geo()
    # Flat, seamless tile; the top uses planar UVs rather than stretched polar UVs.
    g.box((0,0,-.14),(2.02,2.02,.13),mat)
    verts=[];uv=[];faces=[]
    n=16
    for iy in range(n+1):
        for ix in range(n+1):
            x=-2+4*ix/n;y=-2+4*iy/n
            verts.append((x,y,.009+.002*sin(ix*.8)*sin(iy*.7)))
            uv.append((ix/n*3,iy/n*3))
    for iy in range(n):
        for ix in range(n):
            k=iy*(n+1)+ix;faces.append((k,k+1,k+n+2,k+n+1))
    g.add(verts,faces,uv,mat)
    # A gently meandering stitched cloth patch breaks the mechanical square grid.
    pts=[(-1.98,-1.94,.025),(-.9,-1.90,.025),(.05,-1.96,.025),(1.0,-1.90,.025),(1.98,-1.94,.025)]
    seam(g,pts,.19,.035)
    pts=[(-1.94,-1.98,.025),(-1.90,-.9,.025),(-1.96,.05,.025),(-1.90,1,.025),(-1.94,1.98,.025)]
    seam(g,pts,.19,.035)
    # Sparse yarn filaments lie on the cloth surface and catch low evening light.
    for i in range(220):
        x=random.uniform(-1.95,1.95);y=random.uniform(-1.95,1.95);t=random.random()*tau
        g.tube([(x,y,.015),(x+.05*cos(t),y+.05*sin(t),.020),(x+.10*cos(t+.2),y+.10*sin(t+.2),.015)],.0025,'felt_sage' if mat=='felt_meadow' else mat,4)
    a.part('FeltTile',g); return a.finish()

def border():
    a=Asset('cliff_embroidered_4m','terrain'); g=Geo()
    for z,mat,h in [(-.19,'felt_linen',.15),(-.51,'felt_red',.21),(-.84,'felt_teal',.12),(-1.07,'felt_linen',.12)]:
        g.box((0,0,z),(2,.25,h),mat)
    for x in [-1.52,-.76,0,.76,1.52]:horn_scroll(g,(x,-.266,-.5),1.15,'XZ')
    for z in [-.03,-.98]:
        g.tube([(-2,-.28,z),(2,-.28,z)],.03,'rope',10)
        for j in range(34):
            x=-1.96+j*.118; g.tube([(x,-.30,z+.055),(x+.034,-.30,z-.05)],.012,'felt_tan',6)
    a.part('Cliff',g); return a.finish()

def water(name,bend=False):
    a=Asset(name,'terrain'); g=Geo(); vs=[]; uv=[]; fs=[]; N=32
    for j in range(N+1):
        y=-2+4*j/N; center=.55*sin(y*pi/4) if bend else 0
        for i in range(9):
            x=-1.0+i*.25+center; vs.append((x,y,-.05+.007*sin(i*3+j))); uv.append((i/8,j/N*2))
    for j in range(N):
        for i in range(8):k=j*9+i; fs.append((k,k+1,k+10,k+9))
    g.add(vs,fs,uv,'felt_water')
    for side in [-1,1]:
        for j in range(13):
            y=-1.9+j*.31; c=.55*sin(y*pi/4) if bend else 0
            g.ell((c+side*1.03,y,.005),(.16,.20,.10),'stone',16,10,e=.55,jitter=.03)
    for j in range(22):
        y=random.uniform(-1.9,1.6); c=.55*sin(y*pi/4) if bend else 0; x=c+random.uniform(-.8,.8)
        g.tube([(x,y,-.023),(x+.025,y+.11,-.018),(x+.06,y+.23,-.023)],.010,'felt_water_light',6)
    a.part('River',g); return a.finish()

def mountains():
    a=Asset('mountain_felt_peak','terrain'); g=Geo()
    # Future-level extension: layered cloth peak with seam ridges.
    g.tube([(0,0,0),(.08,0,.8),(-.15,.05,1.9),(.05,.10,3.1)],[1.6,1.25,.65,.005],'felt_ash',32)
    g.tube([(-.15,.05,2.05),(.05,.10,3.1)],[.58,.002],'wool_ivory',32)
    for j in range(8):
        t=j*tau/8; g.tube([(1.58*cos(t),1.58*sin(t),.06),(1.26*cos(t),1.26*sin(t),.82),(.63*cos(t)-.15,.63*sin(t)+.05,1.92),(.05,.10,3.10)],.014,'rope',6)
    a.part('Peak',g); return a.finish()

def ui_badge():
    a=Asset('leather_badge','prop'); g=Geo(); g.box((0,0,.035),(1.2,.38,.045),'leather')
    seam(g,[(-1.1,-.30,.08),(1.1,-.30,.08),(1.1,.30,.08),(-1.1,.30,.08),(-1.1,-.30,.08)],.12,.025)
    a.part('Badge',g); return a.finish()

def run():
    for ob in list(bpy.data.objects):bpy.data.objects.remove(ob,do_unlink=True)
    for mesh in list(bpy.data.meshes):
        if mesh.users==0:bpy.data.meshes.remove(mesh)
    for mat in list(bpy.data.materials):bpy.data.materials.remove(mat)
    for im in list(bpy.data.images):
        if im.source=='FILE':bpy.data.images.remove(im)
    for sc in list(bpy.data.scenes):
        if sc!=bpy.context.scene:bpy.data.scenes.remove(sc)
    for c in list(bpy.data.collections):
        if not c.objects:bpy.data.collections.remove(c)
    # Derive a tangent-space normal data map from the generated fiber scan.
    # This is shader input data; base color remains the original generated image.
    import numpy as np
    photo=bpy.data.images.load(str(ROOT/'assets/textures/needle_felt_ivory_v2.png'),check_existing=True)
    w,h=photo.size
    pixels=np.empty(w*h*4,dtype=np.float32);photo.pixels.foreach_get(pixels)
    rgb=pixels.reshape(h,w,4)[:,:,:3];height=rgb.mean(axis=2)
    dx=(np.roll(height,-1,axis=1)-np.roll(height,1,axis=1))*4.5
    dy=(np.roll(height,-1,axis=0)-np.roll(height,1,axis=0))*4.5
    normal=np.stack((-dx,-dy,np.ones_like(dx)),axis=2)
    normal/=np.linalg.norm(normal,axis=2,keepdims=True)
    rgba=np.ones((h,w,4),dtype=np.float32);rgba[:,:,:3]=normal*.5+.5
    im=bpy.data.images.new('Needle felt tangent normal',width=w,height=h,alpha=True)
    im.colorspace_settings.name='Non-Color';im.pixels.foreach_set(rgba.ravel())
    im.filepath_raw=str(ROOT/'assets/textures/needle_felt_normal_v2.png');im.file_format='PNG';im.save()
    bpy.data.images.remove(im)
    for scan_name in ['meadow_pressed_v4','stone_matted_v3','sheep_merino_v1']:
        photo=bpy.data.images.load(str(ROOT/'assets/textures'/f'{scan_name}.png'),check_existing=True)
        w,h=photo.size;pixels=np.empty(w*h*4,dtype=np.float32);photo.pixels.foreach_get(pixels)
        height=pixels.reshape(h,w,4)[:,:,:3].mean(axis=2)
        dx=(np.roll(height,-1,1)-np.roll(height,1,1))*6
        dy=(np.roll(height,-1,0)-np.roll(height,1,0))*6
        normal=np.stack((-dx,-dy,np.ones_like(dx)),axis=2);normal/=np.linalg.norm(normal,axis=2,keepdims=True)
        rgba=np.ones((h,w,4),dtype=np.float32);rgba[:,:,:3]=normal*.5+.5
        im=bpy.data.images.new(scan_name+' normal',width=w,height=h,alpha=True);im.colorspace_settings.name='Non-Color'
        im.pixels.foreach_set(rgba.ravel());im.filepath_raw=str(ROOT/'assets/textures'/f'{scan_name}_normal.png');im.file_format='PNG';im.save();bpy.data.images.remove(im)
    for p in sorted((ROOT/'assets/textures').glob('*_color.png')):material(p.name[:-10])
    for name in ['felt_border_red','felt_border_teal','felt_border_linen','felt_border_ash','felt_applique','sheep_wool_ivory','sheep_wool_snow','sheep_face']:material(name)
    material('eye',(.013,.012,.010),.23); material('nose',(.025,.021,.019),.37)
    material('highlight',(.95,.91,.80),.12); material('amber',(.63,.36,.045),.3); material('brass',(.33,.21,.08),.45)
    sheep(); sheep('sheep_whiteface',True); canine('taigan_dog',False); canine('wolf_gray',True)
    wall('wall_straight_3m'); wall('wall_curve_3m',True); gate(); bridge(); yurt(); kazan(); barrel('barrel_large'); barrel('barrel_small',True); rug()
    rock('boulder_large',(1.0,.8,.95),20); rock('boulder_medium',(.57,.48,.53),21); rock('pebbles',(.24,.2,.16),22)
    shrub('shrub_pine','felt_pine',1); shrub('shrub_teal','felt_teal',2); shrub('shrub_ochre','felt_gold',3); shrub('shrub_rust','felt_rust',4)
    tuft('grass_tuft'); tuft('river_reeds',True); flowers()
    terrain('meadow_tile_4m','felt_meadow'); terrain('sage_tile_4m','felt_sage'); terrain('path_tile_4m','felt_ochre'); border()
    water('river_straight_4m'); water('river_bend_4m',True); mountains(); ui_badge()
    exec(compile((ROOT/'art/source/reference_landform.py').read_text(), 'reference_landform.py', 'exec'),globals())
    (ROOT/'assets/manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
    # Save a self-contained source library with texture images packed.
    for im in bpy.data.images:
        if im.source=='FILE':im.pack()
    bpy.context.scene.unit_settings.system='METRIC'
    bpy.context.scene['project']='TAIGAN — Felt Pastures'; bpy.context.scene['asset_count']=len(manifest)
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/taigan_asset_library.blend'))
    log('BUILD COMPLETE')
try:run()
except Exception:
    log(traceback.format_exc())
    raise
