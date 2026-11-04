"""Reference-led sedan reconstruction; independent body sections, seated fittings.

Run in Blender background. Only luxury_sedan scene is rebuilt. -Y forward.
Source: luxury-sedan-v2.png; physical targets retained from reference_geometry.
"""
from pathlib import Path
import math, runpy
import bpy
import bmesh
from mathutils import Vector
HERE=Path(__file__).resolve().parent
src=runpy.run_path(str(HERE/'build_shapes.py'))
spec=runpy.run_path(str(HERE/'reference_geometry.py'))['TARGETS']['luxury_sedan']
scene,root,c=src['build']('luxury_sedan',spec)
for ob in list(scene.objects):
    if ob!=root:bpy.data.objects.remove(ob,do_unlink=True)
mesh,box,line,cyl=[c[k] for k in ['mesh','box','line','cylinder']] if 'cylinder' in c else [c[k] for k in ['mesh','box','line','cyl']]
mats=c['mats']
for name,color,rough,metal in [('paint','451B29',.40,.22),('glass','34444E',.38,.10),('lamp','A4AFA7',.40,.05)]:
    shader=next(n for n in mats[name].node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    shader.inputs['Base Color'].default_value=src['rgba'](color)
    shader.inputs['Roughness'].default_value=rough;shader.inputs['Metallic'].default_value=metal
# y, body half-width, deck centre reference. More stations at rolled ends.
stations=[(-2.54,.815,.885),(-2.49,.865,.910),(-2.37,.905,.940),(-2.10,.934,.972),
    (-1.65,.943,1.003),(-1.12,.943,1.017),(-.40,.943,1.017),(.45,.943,1.017),
    (1.60,.930,1.005),(1.95,.918,.980),(2.32,.895,.948),(2.48,.854,.920),(2.54,.805,.895)]
def section(y):
    for a,b in zip(stations,stations[1:]):
        if y<=b[0]:
            t=max(0,min(1,(y-a[0])/(b[0]-a[0])));return a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t
    return stations[-1][1:]
def cross(y):
    w,h=section(y)
    crown=.058 if y<1.3 else .026
    return [(0,.285),(w*.84,.285),(w*.94,.330),(w*.985,.450),(w,.660),
        (w*.995,.805),(w*.955,h-.065),(w*.86,h+.005),(w*.57,h+crown*.72),(0,h+crown)]
def side(sign,y,z,offset=.006):
    curve=cross(y);ww=curve[1][0]
    for a,b in zip(curve[1:],curve[2:]):
        if z<=b[1]:
            t=max(0,min(1,(z-a[1])/max(.0001,b[1]-a[1])));ww=a[0]+(b[0]-a[0])*t;break
    return (sign*(ww+offset),y,z)
# Full transverse surfaces: roof of bonnet/boot is the same mesh as its shoulders.
vs=[];fs=[];n=18
for y,_,_ in stations:
    cc=cross(y);profile=cc+[(-x,z) for x,z in cc[-2:0:-1]]
    vs.extend((x,y,z) for x,z in profile)
for j in range(len(stations)-1):
    for i in range(n):fs.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
fs.extend([tuple(range(n-1,-1,-1)),tuple(range((len(stations)-1)*n,len(stations)*n))])
body=mesh('Sedan compound shoulder and decks',vs,fs,smooth=True)
for axle in spec['axles']:
    bpy.ops.mesh.primitive_cylinder_add(vertices=36,radius=.382,depth=3,location=(0,axle,.3442),rotation=(0,math.pi/2,0))
    cutter=bpy.context.object;bpy.context.view_layer.objects.active=body
    mod=body.modifiers.new('Open arch','BOOLEAN');mod.operation='DIFFERENCE';mod.object=cutter
    bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cutter,do_unlink=True)
# Cabin uses a coordinated curved width profile, with larger glass openings.
z0=.955;zt=1.435;rf=-.690;rr=.910;bf=-1.225;br=1.850
def width(z):
    t=max(0,min(1,(z-z0)/(zt-z0)));return .883-.115*t+.018*math.sin(math.pi*t)
def cab_side(sign,y,z,off=.010):return (sign*(width(z)+off),y,z)
def cab_end(front,x,z,off=.010):
    t=(z-z0)/(zt-z0);lo=bf if front else br;hi=rf if front else rr
    curve=.026*(1-(x/max(.01,width(z)))**2)*math.sin(math.pi*t)
    roof_blend=.043*(1-(x/max(.01,width(z)))**2)*max(0,t)**8
    return (x,lo+(hi-lo)*t+(-1 if front else 1)*(off+curve),z+roof_blend)
def grid(name,mapper,cols=24,rows=24,mat='paint'):
    v=[mapper(i/cols,j/rows) for j in range(rows+1) for i in range(cols+1)];f=[]
    for j in range(rows):
        for i in range(cols):
            a=j*(cols+1)+i;f.append((a,a+1,a+cols+2,a+cols+1))
    return mesh(name,v,f,mat,True)
cabin_start=set(scene.objects)
for sign in [-1,1]:
    grid('Crowned cabin side',lambda u,t: cab_side(sign,bf+(rf-bf)*t+(br+(rr-br)*t-bf-(rf-bf)*t)*u,z0+(zt-z0)*t,0))
for front in [True,False]:
    grid('Screen surround',lambda u,t:cab_end(front,width(z0+(zt-z0)*t)*(-1+2*u),z0+(zt-z0)*t,0))
grid('Compound roof crown',lambda u,t:(.768*(-1+2*u),rf+(rr-rf)*t,zt+(.043+.008*math.sin(math.pi*t))*(1-(-1+2*u)**2)),24,24)

# Weld roof, screen surrounds and sides before rounding their shared creases.
# Separate shaded sheets left hard roof corners and discontinuous highlights.
cabin_parts=[ob for ob in scene.objects if ob not in cabin_start]
bpy.ops.object.select_all(action='DESELECT')
for ob in cabin_parts: ob.select_set(True)
bpy.context.view_layer.objects.active=cabin_parts[0]
bpy.ops.object.join()
cabin=bpy.context.object;cabin.name='Continuous rounded cabin shell'
bm=bmesh.new();bm.from_mesh(cabin.data)
bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.0001)
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
# Matching boundary grids make the four roof joins continuous.
edges=[e for e in bm.edges if e.is_manifold and e.calc_face_angle()>.30]
bmesh.ops.bevel(bm,geom=edges,offset=.028,segments=5,affect='EDGES',clamp_overlap=True)
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
bm.to_mesh(cabin.data);bm.free()
for poly in cabin.data.polygons:poly.use_smooth=True
def rounded(coords,r=.025):
    out=[]
    for i,p in enumerate(coords):
        p=Vector(p);a=Vector(coords[i-1]);b=Vector(coords[(i+1)%len(coords)])
        d=min(r,(a-p).length*.2,(b-p).length*.2);v=p+(a-p).normalized()*d;w=p+(b-p).normalized()*d
        for j in range(3):
            t=j/2;out.append(tuple((1-t)**2*v+2*t*(1-t)*p+t*t*w))
    return out
def patch(name,coords,mapper,mat='glass',trim=True):
    coords=rounded(coords);n=len(coords);mid=[sum(p[k] for p in coords)/n for k in [0,1]]
    v=[mapper(*mid)];f=[]
    rings=8
    for k in range(1,rings+1):
        t=k/rings
        v.extend(mapper(mid[0]+(p[0]-mid[0])*t,mid[1]+(p[1]-mid[1])*t) for p in coords)
    for i in range(n):
        j=(i+1)%n;f.append((0,i+1,j+1))
        for k in range(rings-1):
            a=1+k*n;f.append((a+i,a+n+i,a+n+j,a+j))
    ob=mesh(name,v,f,mat,True)
    if trim:
        line(name+' black seal',[mapper(*p) for p in coords],'rubber',.010,True)
        expanded=[(mid[0]+(p[0]-mid[0])*1.035,mid[1]+(p[1]-mid[1])*1.035) for p in coords]
        line(name+' chrome edge',[mapper(*p) for p in expanded],'steel',.005,True)
    return ob
for sign in [-1,1]:
    mapper=lambda y,z:cab_side(sign,y,z,.014)
    patch('Tall front door glass',[(-1.130,1.000),(.145,1.000),(.145,1.405),(-.665,1.405)],mapper)
    patch('Tall rear door glass',[(.230,1.000),(1.490,1.000),(.900,1.405),(.230,1.405)],mapper)
    line('Rear quarterlight divider',[mapper(1.19,1.01),mapper(.79,1.395)],'rubber',.009)
    for a,b in [(-1.15,.19),(.19,1.55)]:
        coords=rounded([(a,.965),(a,.40),(a+.06,.345),(b-.18,.345),(b-.08,.58),(b,.965)],.025)
        line('Seated door outline',[side(sign,y,z,.005) for y,z in coords],'seam',.003)
    for y in [-.04,1.29]:
        box('Door handle inset',side(sign,y,.940,.010),(.025,.17,.048),'rubber',.013)
        box('Chrome pull handle',side(sign,y,.945,.028),(.028,.14,.022),'steel',.007)
    line('Body waist chrome',[side(sign,y,.735,.008) for y in [-2.25,-1.75,-1.0,0,1,1.80,2.25]],'steel',.005)
    # Mirror seated against the actual A-pillar plane.
    box('Mirror base',cab_side(sign,-1.08,1.035,.014),(.045,.15,.11),'rubber',.012)
    box('Mirror housing',(sign*.976,-1.08,1.07),(.145,.19,.12),'paint',.025)
    for index,axle in enumerate(spec['axles']):
        track=spec['tracks'][index];r=.3442;xc=sign*track/2
        verts=[];faces=[];segments=28
        profile=[(-.1175,.70*r),(-.1175,.88*r),(-.080,.995*r),(.080,.995*r),(.1175,.88*r),(.1175,.70*r)]
        for dx,rad in profile:
            for j in range(segments):
                ang=2*math.pi*j/segments;verts.append((xc+dx,axle+rad*math.sin(ang),r+rad*math.cos(ang)))
        for k in range(5):
            for j in range(segments):
                a=k*segments+j;b=k*segments+(j+1)%segments;faces.append((a,b,b+segments,a+segments))
        mesh('Rounded tire',verts,faces,'rubber',True)
        outside=xc+sign*.110
        cyl('Cast rim',(outside,axle,r),.2032,.024,'steel',vertices=28)
        cyl('Cast centre',(outside+sign*.017,axle,r),.068,.018,'steel',vertices=20)
        for j in range(5):
            ang=2*math.pi*j/5
            cyl('Dark oval rim aperture',(outside+sign*.015,axle+.143*math.sin(ang),r+.143*math.cos(ang)),.035,.010,'rubber',vertices=12)
        rradius=.387;start=math.asin((.34-r)/rradius)
        line('Painted arch roll',[side(sign,axle+rradius*math.cos(a),r+rradius*math.sin(a),.005) for a in [start+(math.pi-2*start)*j/24 for j in range(25)]],'paint',.010)
# Both end masks include their side/top return walls into the main shell.
# Optics sample this exact mask, not a different analytical body approximation.
def end_y(front,x,z):
    corner=max(0,(abs(x)-.70)/.18)
    setback=.125*min(1,corner*corner)+.015*max(0,(z-.78)/.20)
    return (-1 if front else 1)*(2.580-setback)
for front in [True,False]:
    outline=[(-.875,.60),(.875,.60),(.875,.86),(.80,.947),(0,.969),(-.80,.947),(-.875,.86)]
    vs=[(x,end_y(front,x,z),z) for x,z in outline]
    vs.extend((x,(-1 if front else 1)*2.20,z) for x,z in outline)
    n=len(outline);faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]
    for i in range(n):faces.append((i,(i+1)%n,(i+1)%n+n,i+n))
    mesh('Connected front mask' if front else 'Connected rear mask',vs,faces,'paint')
def face(front,x,z,offset=.008):
    return (x,end_y(front,x,z)+(-offset if front else offset),z)
for front in [True,False]:
    direction=-1 if front else 1
    # Bumper is a curved integrated cover with inward returns, not a detached beam.
    path=[(-.925,2.29),(-.925,2.40),(-.90,2.51),(-.80,2.58),(0,2.6065),(.80,2.58),(.90,2.51),(.925,2.40),(.925,2.29)]
    verts=[];faces=[]
    for zz,inset in [(.365,.020),(.390,0),(.500,0),(.535,.025)]:
        verts.extend((x*(1-inset),direction*(y-inset),zz) for x,y in path)
    for k in range(3):
        for j in range(len(path)-1):
            a=k*len(path)+j;faces.append((a,a+1,a+1+len(path),a+len(path)))
    mesh('Integrated bumper cover',verts,faces,'paint',True)
    line('Narrow bumper impact strip',[(x,direction*(y+.002),.485) for x,y in path],'rubber',.019)
    box('Blank inset plate',(0,direction*2.609,.455),(.34,.012,.085),'steel',.004)
    for sign in [-1,1]:
        if front:
            poly=[(sign*.440,.720),(sign*.835,.720),(sign*.817,.920),(sign*.470,.920)]
            patch('Seated headlight housing',poly,lambda x,z:face(True,x,z,.009),'rubber',False)
            lens=[(sign*.458,.735),(sign*.817,.735),(sign*.802,.905),(sign*.480,.905)]
            patch('Inset rectangular headlight',lens,lambda x,z:face(True,x,z,.017),'lamp',False)
            for j in range(4):
                xx=sign*(.50+j*.080)
                line('Lens vertical flute',[face(True,xx,.751,.021),face(True,xx,.89,.021)],'steel',.002)
        else:
            inner=lambda z:.35+max(0,z-.770)*1.1
            for low,high,color in [(.685,.748,'lamp'),(.754,.856,'red'),(.862,.919,'amber')]:
                coords=[(sign*inner(low),low),(sign*.875,low),(sign*.875,high),(sign*inner(high),high)]
                patch('Wrapped rear lens '+color,coords,lambda x,z:face(False,x,z,.012),color,False)
if True:
    patch('Seated grille surround',[(-.405,.682),(.405,.682),(.365,.982),(-.365,.982)],lambda x,z:face(True,x,z,.010),'steel',False)
    patch('Dark grille opening',[(-.373,.708),(.373,.708),(.339,.954),(-.339,.954)],lambda x,z:face(True,x,z,.020),'rubber',False)
    for j in range(6):
        zz=.731+j*.039;ww=.359-(zz-.731)*.14
        line('Fine grille blade',[face(True,-ww,zz,.025),face(True,ww,zz,.025)],'steel',.004)
low=.995;high=1.405
coords=[(-width(low)+.045,low),(width(low)-.045,low),(width(high)-.045,high),(-width(high)+.045,high)]
patch('Broad curved windscreen',coords,lambda x,z:cab_end(True,x,z,.014))
# The backlight is not a copy of the windscreen: rounded shoulders, arched
# upper/lower edges and wider solid C-pillar margins. All points sample the
# existing rear-cabin surface, including the centre, so no floating flat pane.
rear_outline=[(-.775,1.085),(-.779,1.110),(-.700,1.360),(-.678,1.399),
    (-.620,1.410),(0,1.414),(.620,1.410),(.678,1.399),(.700,1.360),
    (.779,1.110),(.775,1.085),(.600,1.080),(0,1.078),(-.600,1.080)]
patch('Curved rear backlight',rear_outline,lambda x,z:cab_end(False,x,z,.012))
# Deck seam follows the body crown, below the separate backlight aperture.
line('Boot opening seam',[(x,1.83,.985+.026*(1-(x/.86)**2)) for x in [-.80,-.60,-.30,0,.30,.60,.80]],'seam',.003)
for sign in [-1,1]:
    line('Wiper arm',[cab_end(True,sign*.10,1.02,.032),cab_end(True,sign*.56,1.09,.032)],'rubber',.007)
root['stage']='Sedan v2 reconstruction from RAF-family sheet; awaiting visual review'
root['wheelbase_m']=3.14;root['glass_height_m']=.405
bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'sedan_v2.blend'))
print('SEDAN_V2',len(scene.objects),'objects; glass height .405m')
