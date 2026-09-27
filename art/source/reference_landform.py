"""Continuous felt landscape and props, authored in Blender and exported as meshes."""
from mathutils.geometry import tessellate_polygon

def smooth_loop(points,steps=8):
    result=[];N=len(points)
    for i in range(N):
        p0=Vector(points[(i-1)%N]);p1=Vector(points[i]);p2=Vector(points[(i+1)%N]);p3=Vector(points[(i+2)%N])
        for j in range(steps):
            t=j/steps
            v=.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t)
            result.append(v)
    return result

# Blender Y is the negative of the Godot map Z.
CONTOUR=[(-5,-20,0),(5,-20,0),(9,-18,0),(11,-13,0),(10.5,-8,0),(8.6,-3,0),(9.5,1,0),(11.2,6,0),(11,13,0),(8.3,18,0),(3,20,0),(-4,19.8,0),(-9,17,0),(-10.5,11,0),(-10,6,0),(-8.6,1,0),(-9.0,-4,0),(-11,-9,0),(-10.5,-15,0)]
EDGE=smooth_loop(CONTOUR,9)

def inside_poly(x,y,poly=EDGE):
    odd=False;j=len(poly)-1
    for i in range(len(poly)):
        a=poly[i];b=poly[j]
        if (a.y>y)!=(b.y>y) and x<(b.x-a.x)*(y-a.y)/(b.y-a.y)+a.x:odd=not odd
        j=i
    return odd

def river_y(x):return 4-.70*sin(x*.42)

def quilt_color(x,y):
    # Flowing paths and large, irregular meadow patches instead of square tiles.
    path_center=.4+1.4*sin(y*.19)+.5*sin(y*.53)
    if abs(x-path_center)<1.35+.3*sin(y*.47):return 'felt_ochre'
    if y>7 and x>-4 and x<4:return 'felt_sage'
    field=sin(x*.37+y*.16)+.65*cos(y*.40-x*.10)+.4*sin(x*.67-y*.22)
    return 'felt_sage' if field>.55 else 'felt_meadow'

def clip_field(poly, fn, positive=True):
    out=[]
    for i,b in enumerate(poly):
        a=poly[i-1];fa=fn(a[0],a[1]);fb=fn(b[0],b[1])
        ina=(fa>=0)==positive;inb=(fb>=0)==positive
        if ina!=inb:
            t=fa/(fa-fb);out.append(tuple(a[k]+(b[k]-a[k])*t for k in range(3)))
        if inb:out.append(b)
    return out

def road_field(x,y):return 1.35+.3*sin(y*.47)-abs(x-(.4+1.4*sin(y*.19)+.5*sin(y*.53)))
def sage_field(x,y):return sin(x*.37+y*.16)+.65*cos(y*.40-x*.10)+.4*sin(x*.67-y*.22)-.55

def hill_height(x,y):
    r2=((x*.65+2.0)/3.5)**2+((-y*.55-4.6)/3.8)**2
    return .56*max(0,1-r2)**3/1.4

def lift_hill(g):
    g.v=[(v[0],v[1],v[2]+hill_height(v[0],v[1])) for v in g.v]

def landform():
    a=Asset('valley_landform','terrain');g=Geo();n=96;m=176
    # Top is subdivided evenly, clipped to the island and river channel.
    for iy in range(m):
        y=-21+42*iy/m;dy=42/m
        for ix in range(n):
            x=-12+24*ix/n;dx=24/n;cx=x+dx/2;cy=y+dy/2
            if not inside_poly(cx,cy) or abs(cy-river_y(cx))<1.02:continue
            pts=[(x,y,.025),(x+dx,y,.025),(x+dx,y+dy,.025),(x,y+dy,.025)]
            road=clip_field(pts,road_field)
            rest=clip_field(pts,road_field,False)
            for poly,mat in [(road,'felt_ochre'),(clip_field(rest,sage_field),'felt_sage'),(clip_field(rest,sage_field,False),'felt_meadow')]:
                if len(poly)>=3:g.add(poly,[tuple(range(len(poly)))],[(v[0]*.38,v[1]*.38) for v in poly],mat)
    lift_hill(g);a.part('Meadow',g)
    g=Geo();N=len(EDGE)
    layers=[(.005,-.16,'felt_border_linen'),(-.16,-1.03,'felt_border_red'),(-1.03,-1.25,'felt_border_teal'),(-1.25,-1.58,'felt_border_linen'),(-1.58,-1.85,'felt_border_ash')]
    lengths=[0.0]
    for i in range(N):lengths.append(lengths[-1]+(EDGE[(i+1)%N]-EDGE[i]).length)
    total=lengths[-1]
    from bisect import bisect_right
    def frame(distance):
        distance%=total;j=min(N-1,bisect_right(lengths,distance)-1)
        t=(distance-lengths[j])/(lengths[j+1]-lengths[j])
        p=EDGE[j].lerp(EDGE[(j+1)%N],t)
        d=(EDGE[(j+1)%N]-EDGE[j]).normalized();out=Vector((d.y,-d.x,0))
        return p,d,out
    def cliff(distance,z,extra=0):
        p,d,out=frame(distance)
        top,bottom,mat=next((v for v in layers if v[1]-.001<=z<=v[0]+.001),layers[-1])
        t=max(0,min(1,(top-z)/(top-bottom)))
        bulge=.14*sin(pi*t)+.035*sin(distance*1.7)+.018*sin(distance*4.2)
        wave=(.025*sin(distance*.85)+.013*sin(distance*2.8))*min(1,abs(z)*7)
        return p+out*(bulge+extra)+Vector((0,0,z+wave))
    for top,bottom,mat in layers:
        verts=[];uv=[];faces=[];rows=10
        for i in range(N):
            for row in range(rows+1):
                z=top+(bottom-top)*row/rows
                verts.append(tuple(cliff(lengths[i],z)))
                uv.append((lengths[i]*.6,z*.6))
        for i in range(N):
            j=(i+1)%N
            for row in range(rows):faces.append((i*(rows+1)+row,j*(rows+1)+row,j*(rows+1)+row+1,i*(rows+1)+row+1))
        g.add(verts,faces,uv,mat)
    ring=[cliff(total*i/(N*2),-.025,.025)+Vector((0,0,.045)) for i in range(N*2+1)]
    g.tube(ring,.085,'felt_applique',14)
    for j in range(int(total/.24)):
        dist=j*.24;p,d,out=frame(dist)
        g.tube([p-out*.10+Vector((0,0,.045)),p+Vector((0,0,.115)),cliff(dist,-.12,.045)],.013,'felt_tan',6)
    # Padded, flattened felt appliqué. Its entire curve is projected onto the
    # curved cliff, avoiding the old buried segments and pointed arch shapes.
    def applique(distance,path):
        verts=[];uv=[];faces=[];sides=10
        for i,(u,z) in enumerate(path):
            before=Vector(path[max(0,i-1)]);after=Vector(path[min(len(path)-1,i+1)])
            tangent=(after-before).normalized();side=Vector((-tangent.y,tangent.x))
            width=.095*(.65+.35*sin(pi*i/(len(path)-1))**.4)
            for k in range(sides+1):
                theta=tau*k/sides
                uu=u+side.x*width*cos(theta);zz=z+side.y*width*.58*cos(theta)
                point=cliff(distance+uu,zz,.035+.032*sin(theta))
                verts.append(tuple(point));uv.append((i/len(path)*2,k/sides*.22))
        for i in range(len(path)-1):
            for k in range(sides):
                n=i*(sides+1)+k;faces.append((n,n+1,n+sides+2,n+sides+1))
        g.add(verts,faces,uv,'felt_applique')
        # Small transverse hand stitches fasten cream felt to red cloth.
        for i in range(4,len(path)-3,5):
            u,z=path[i];t=(Vector(path[i+1])-Vector(path[i-1])).normalized();side=Vector((-t.y,t.x))
            points=[]
            for q in [-1,0,1]:points.append(cliff(distance+u+side.x*q*.11,z+side.y*q*.061,.072 if q==0 else .031))
            g.tube(points,.007,'felt_tan',5)
    motifs=max(1,int(total/2.5))
    for j in range(motifs):
        dist=(j+.5)*total/motifs
        for sign in [-1,1]:
            path=[]
            # Central stem branches into both curled horns of one applique.
            for k in range(17):
                t=k/16
                u=(1-t)**3*0+3*(1-t)**2*t*.03+3*(1-t)*t*t*.30+t**3*.551
                z=(1-t)**3*(-.34)+3*(1-t)**2*t*(-.78)+3*(1-t)*t*t*(-.89)+t**3*(-.88185)
                path.append((sign*u,z))
            # Recognizable round ram-horn curl with a broad outer spiral.
            for k in range(70):
                t=k/69;angle=-pi/2+t*1.87*pi;rad=.34*(1-t)+.065
                path.append((sign*(.38+rad*cos(angle))*1.45,-.57+rad*.77*sin(angle)))
            applique(dist,path)
        # Fine ochre sprigs between large curls, not star-shaped symbols.
        center=dist+total/motifs*.49
        g.tube([cliff(center,-.98,.035),cliff(center-.05,-.85,.037),cliff(center+.05,-.70,.035)],.009,'felt_gold',6)
        for side in [-1,1]:
            for k in range(3):
                z=-.93+k*.065
                g.tube([cliff(center,z,.037),cliff(center+side*.12,z+.04,.039),cliff(center+side*.18,z+.08,.035)],.008,'felt_gold',5)
    # Blanket stitches across layer joins and irregular hanging thread ends.
    rng=random.Random(378)
    for j in range(int(total/.23)):
        dist=j*.23
        for z,thread in [(-1.03,'felt_tan'),(-1.25,'felt_border_teal'),(-1.58,'felt_tan')]:
            g.tube([cliff(dist,z+.075,.025),cliff(dist+.018,z,.04),cliff(dist+.025,z-.075-rng.random()*.045,.023)],.011,thread,6)
    for i in range(15000):
        dist=rng.random()*total;z=rng.uniform(-1.83,-.03);l=rng.uniform(.015,.05)
        mat=next(m for top,bottom,m in layers if bottom<=z<=top)
        g.tube([cliff(dist,z,.004),cliff(dist+l*.5,z+.009,.012),cliff(dist+l,z+.003,.004)],.0014,mat,3)
    a.part('EmbroideredCliffs',g)
    # Scatter small physical wool fibers over the plateau.
    g=Geo();rng=random.Random(904)
    for _ in range(6000):
        x=rng.uniform(-11,11);y=rng.uniform(-20,20)
        if not inside_poly(x,y) or abs(y-river_y(x))<1.12:continue
        t=rng.random()*tau;l=rng.uniform(.020,.045)
        g.tube([(x,y,.028),(x+l*.5*cos(t),y+l*.5*sin(t),.034),(x+l*cos(t+.3),y+l*sin(t+.3),.03)],.0014,quilt_color(x,y),3)
    lift_hill(g);a.part('SurfaceWool',g)
    # Hand stitches trace selected curved patch boundaries across the meadow.
    g=Geo()
    for side in [-1,1]:
        pts=[]
        for i in range(160):
            y=-18+i*37/159;x=.4+1.4*sin(y*.19)+.5*sin(y*.53)+side*(1.35+.3*sin(y*.47))
            if abs(y-river_y(x))<1.3:
                if len(pts)>1:seam(g,pts,.22,.055)
                pts=[]
            else:pts.append((x,y,.04))
        if len(pts)>1:seam(g,pts,.22,.055)
    lift_hill(g);a.part('PatchStitching',g)
    return a.finish()

def valley_river():
    a=Asset('valley_river','terrain');g=Geo();N=160
    for i in range(N):
        x=-10.4+20.8*i/N;xx=-10.4+20.8*(i+1)/N;y=river_y(x);yy=river_y(xx)
        if not inside_poly((x+xx)/2,(y+yy)/2):continue
        g.add([(x,y-1.02,-.20),(xx,yy-1.02,-.20),(xx,yy+1.02,-.20),(x,y+1.02,-.20)],[(0,1,2,3)],[(x*.6,0),(xx*.6,0),(xx*.6,1),(x*.6,1)],'felt_water')
    rng=random.Random(405)
    for i in range(76):
        x=-10.4+i*20.8/75
        for side in [-1,1]:
            y=river_y(x)+side*1.025
            if not inside_poly(x,y):continue
            g.ell((x,y,-.06),(.17+rng.random()*.13,.16+rng.random()*.10,.12+rng.random()*.10),'stone',20,14,e=.75,jitter=.10)
    for i in range(95):
        x=rng.uniform(-10.2,10.2);y=river_y(x)+rng.uniform(-.76,.76)
        if not inside_poly(x,y):continue
        length=rng.uniform(.24,.55)
        g.tube([(x+length*k/8,y+.06*sin(pi*k/8),-.177) for k in range(9)],.012,'felt_water_light',6)
    a.part('WoolWaterAndBanks',g);return a.finish()

def hay_bale():
    a=Asset('hay_bale','prop');g=Geo();g.ell((0,0,.34),(.43,.33,.34),'felt_gold',36,24,e=.42,jitter=.035)
    g.fuzz((0,0,.34),(.43,.335,.345),'felt_gold',1000,.042)
    for x in [-.22,.22]:
        pts=[(x,.345*cos(tau*i/64),.34+.345*sin(tau*i/64)) for i in range(65)];g.tube(pts,.025,'rope',8)
    a.part('Bale',g);return a.finish()

def trough():
    a=Asset('wooden_trough','prop');g=Geo()
    g.box((0,0,.13),(.65,.30,.065),'wood')
    for y in [-.28,.28]:g.box((0,y,.31),(.67,.045,.20),'wood')
    for x in [-.63,.63]:g.box((x,0,.31),(.045,.28,.20),'wood')
    g.box((0,0,.27),(.58,.23,.025),'felt_water')
    for x in [-.43,.43]:g.box((x,0,.065),(.08,.35,.065),'wood')
    a.part('Trough',g);return a.finish()

def lantern():
    a=Asset('felt_lantern','prop');g=Geo();g.tube([(0,0,0),(0,0,1.1)],[.055,.042],'wood',12)
    g.tube([(0,0,1.08),(.10,0,1.23),(.29,0,1.19),(.30,0,1.02)],.024,'rope',8)
    g.ell((.30,0,.84),(.13,.13,.19),'felt_gold',24,16,e=.5)
    for z in [.65,1.02]:g.ell((.30,0,z),(.16,.16,.04),'wood',24,12)
    for x,y in [(.18,0),(.42,0),(.3,.12),(.3,-.12)]:g.tube([(x,y,.68),(x,y,1)],.012,'wood',6)
    a.part('Lantern',g);return a.finish()

def round_pen():
    a=Asset('pen_round_5m','architecture');g=Geo();radius=2.35
    for row in range(3):
        count=27 if row%2==0 else 28
        for i in range(count):
            angle=-pi/2+.50+(tau-1.0)*(i+.5)/count
            rad=radius+random.uniform(-.025,.025)
            g.ell((rad*cos(angle),rad*sin(angle),.18+row*.285),(.255,.235,.165),'stone',28,18,e=.48,jitter=.07,rot=(0,random.uniform(-.07,.07),angle+pi/2))
    for i in range(35):
        angle=random.uniform(-pi/2+.6,3*pi/2-.6);rad=radius+random.choice([-1,1])*.22
        g.ell((rad*cos(angle),rad*sin(angle),.035),(.12,.075,.045),'felt_meadow',16,10)
    a.part('StoneCircle',g);return a.finish()

landform();valley_river();hay_bale();trough();lantern();round_pen()
(ROOT/'data/landform_contour.json').write_text(json.dumps([[round(p.x,4),round(-p.y,4)] for p in EDGE]))
