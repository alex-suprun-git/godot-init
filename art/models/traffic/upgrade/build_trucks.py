"""Reference-led truck family. Build only; export and review are separate stages.
Blender -Y forward, metres, wheels at Z=0. No external geometry or textures.
"""
from pathlib import Path
import bpy, bmesh, math, json, sys, random
from mathutils import Vector
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
BLOCKOUT='--blockout' in sys.argv
# Same independently measured stylization as ER2; not fitted to an old prop box.
MEASURE=json.loads((ROOT/'art/models/public_transport/er2/volga_measurements.json').read_text())
SL,SW,SH=MEASURE['train_lwh_factors']

def rgb(h):
    c=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    return tuple(x/12.92 if x<.04045 else ((x+.055)/1.055)**2.4 for x in c)

def material(name,color,rough=.6,metal=0,vertex=False):
    m=bpy.data.materials.new(name);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*rgb(color),1)
    p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
    m.diffuse_color=(*rgb(color),1)
    if vertex:
        n=m.node_tree.nodes.new('ShaderNodeVertexColor');n.layer_name='Color'
        m.node_tree.links.new(n.outputs['Color'],p.inputs['Base Color'])
    return m

class Geo:
    def __init__(self): self.v=[];self.f=[];self.c=[];self.m=[];self.s=[]
    def poly(self,ps,col,mat=2,smooth=False):
        i=len(self.v);self.v.extend(ps);self.f.append(tuple(range(i,i+len(ps))))
        self.c.append((*rgb(col),1));self.m.append(mat);self.s.append(smooth)
    def box(self,c,d,col,mat=2,bevel=0):
        if bevel:
            # Chamfered silhouette; actual geometry, not merely smooth normals.
            x,y,z=c;a,b,h=[v/2 for v in d];r=min(bevel,a*.8,b*.8,h*.8)
            outline=[(-a+r,-b), (a-r,-b),(a,-b+r),(a,b-r),(a-r,b),(-a+r,b),(-a,b-r),(-a,-b+r)]
            rings=[]
            for zz,inset in [(z-h,r),(z-h+r,0),(z+h-r,0),(z+h,r)]:
                rings.append([(x+xx*(a-inset)/a,y+yy*(b-inset)/b,zz) for xx,yy in outline])
            self.loft(rings,col,mat,False);return
        x,y,z=c;a,b,h=[v/2 for v in d]
        p=[(x+i*a,y+j*b,z+k*h) for i,j,k in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
        for f in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]:self.poly([p[i] for i in f],col,mat)
    def loft(self,rings,col,mat=0,smooth=True):
        for a,b in zip(rings[:-1],rings[1:]):
            for i in range(len(a)):
                j=(i+1)%len(a);self.poly([a[i],a[j],b[j],b[i]],col,mat,smooth)
        self.poly(rings[0][::-1],col,mat);self.poly(rings[-1],col,mat)
    def cyl(self,a,b,r,col,mat=2,n=16):
        a,b=Vector(a),Vector(b);axis=(b-a).normalized();u=axis.cross(Vector((0,0,1)))
        if u.length<.01:u=axis.cross(Vector((1,0,0)))
        u.normalize();v=axis.cross(u)
        rings=[[tuple(p+r*(u*math.cos(i*math.tau/n)+v*math.sin(i*math.tau/n))) for i in range(n)] for p in (a,b)]
        self.loft(rings,col,mat)
    def panel(self,mapper,w,h,r,col,mat=2):
        ps=[]
        for x,z,t in [(w/2-r,h/2-r,0),(-w/2+r,h/2-r,90),(-w/2+r,-h/2+r,180),(w/2-r,-h/2+r,270)]:
            for j in range(5):
                a=math.radians(t+j*22.5);ps.append(mapper(x+r*math.cos(a),z+r*math.sin(a)))
        # Sample narrow strips rather than a large nonplanar fan for curved glass.
        center=mapper(0,0)
        for i in range(len(ps)):self.poly([center,ps[i],ps[(i+1)%len(ps)]],col,mat)
    def obj(self,name,collection,mats):
        mesh=bpy.data.meshes.new(name);mesh.from_pydata(self.v,[],self.f);mesh.update()
        for m in mats:mesh.materials.append(m)
        colors=mesh.color_attributes.new(name='Color',type='FLOAT_COLOR',domain='CORNER')
        for p,c,m,s in zip(mesh.polygons,self.c,self.m,self.s):
            p.material_index=m;p.use_smooth=s
            for i in p.loop_indices:colors.data[i].color=c
        bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free()
        for v in mesh.vertices:v.co.x*=SW;v.co.y*=SL;v.co.z*=SH
        o=bpy.data.objects.new(name,mesh);collection.objects.link(o);return o

DARK='252b2b';STEEL='626b68';GLASS='344e5a';IVORY='d6d2bc'

def tire(g,x,y,r=.5,w=.28):
    # Rounded tread shoulders, recessed wheel face and hub. Rear duals are separate tires.
    rings=[]
    for xx,rr in [(x-w/2,r*.85),(x-w*.34,r),(x+w*.34,r),(x+w/2,r*.85)]:
        rings.append([(xx,y+rr*math.sin(t*math.tau/20),r+rr*math.cos(t*math.tau/20)) for t in range(20)])
    g.loft(rings,'282b29',2)
    s=1 if x>0 else -1;face=x+s*(w/2+.005)
    g.cyl((face,y,r),(face+s*.022,y,r),r*.58,'72766e',2,16)
    g.cyl((face+s*.025,y,r),(face+s*.065,y,r),r*.27,DARK,2,12)
    if not BLOCKOUT:
        for i in range(8):
            t=i*math.tau/8;yy=y+r*.39*math.sin(t);zz=r+r*.39*math.cos(t)
            g.cyl((face+s*.025,yy,zz),(face+s*.04,yy,zz),.023,STEEL,2,6)

def axle(g,y,r=.5,track=1.8,duals=False):
    g.cyl((-track/2,y,r),(track/2,y,r),.075,DARK)
    for s in [-1,1]:
        tire(g,s*track/2,y,r)
        if duals:tire(g,s*(track/2-.30),y,r)
        g.box((s*.52,y,.47),(.12,1.0,.09),DARK)

def arch(g,s,y,r=.5,width=.40,col='ffffff',mat=0):
    # Real wheel opening, 160-degree crowned fender and short vertical ends.
    rings=[]
    for i in range(17):
        t=math.pi*i/16
        yy=y+math.cos(t)*(r+.16);zz=r+math.sin(t)*(r+.16)
        rings.append([(s*(.87-width/2),yy,zz),(s*(.87+width/2),yy,zz),
                      (s*(.87+width/2+.025),y+math.cos(t)*(r+.24),r+math.sin(t)*(r+.24)),
                      (s*(.87-width/2),y+math.cos(t)*(r+.24),r+math.sin(t)*(r+.24))])
    g.loft(rings,col,mat)

def chassis(g,start,end):
    for s in [-1,1]:g.box((s*.43,(start+end)/2,.65),(.15,end-start,.22),DARK)
    for y in [start+.3,(start+end)/2,end-.2]:g.box((0,y,.65),(1.0,.13,.14),DARK)

def fittings(g,s,y,z):
    g.box((s*1.055,y,z),(.035,.21,.035),STEEL)
    g.cyl((s*1.02,y-.43,z+.1),(s*1.30,y-.6,z+.62),.018,DARK,2,8)
    g.box((s*1.30,y-.6,z+.71),(.065,.18,.32),DARK,2,.035)
    g.box((s*1.336,y-.6,z+.71),(.012,.135,.25),'879694',2,.02)

def zil_cab(g):
    # Rounded section-built cab, coordinated crown, cowl and windshield rake.
    profile=[(-.91,.65),(.91,.65),(1.0,.77),(1.015,1.55),(.985,2.10),(.93,2.30),(.74,2.38),(.36,2.415),(0,2.425),(-.36,2.415),(-.74,2.38),(-.93,2.30),(-.985,2.10),(-1.015,1.55),(-1,.77)]
    rings=[]
    for y,scale in [(-1.68,.91),(-1.54,1),(-.29,1),(-.15,.91)]:
        rings.append([(x*scale,y+max(0,z-1.65)*.28 if y< -1 else y,z) for x,z in profile])
    g.loft(rings,'ffffff',0)
    # Bonnet has a crown and rolled shoulders in transverse sections.
    rings=[]
    for y,z,width in [(-3.17,1.51,.68),(-3.04,1.59,.75),(-2.65,1.64,.77),(-1.69,1.70,.77)]:
        profile=[(-width,1.03),(width,1.03),(width,z-.15),(width*.9,z-.04),(width*.5,z+.015),(0,z+.04),(-width*.5,z+.015),(-width*.9,z-.04),(-width,z-.15)]
        rings.append([(x,y,zz) for x,zz in profile])
    g.loft(rings,'ffffff',0)
    # Windshield halves follow the same cowl rake and transverse cab curvature.
    for s in [-1,1]:
        for inset,col,mat in [(0,DARK,2),(.045,GLASS,1)]:
            g.panel(lambda u,v:(s*.445+u,-1.70+(1.965+v-1.65)*.28-.025-(.006 if mat==1 else 0)+.055*((s*.445+u)/.93)**2,1.965+v),.84-inset,.61-inset,.075,col,mat)
        for inset,col,mat in [(0,DARK,2),(.055,GLASS,1)]:
            g.panel(lambda u,v:(s*(1.018+(.006 if mat==1 else 0)-.035*max(0,v)), -.88+u,1.965+v),1.04-inset,.60-inset,.08,col,mat)
        arch(g,s,-2.2625)
        g.box((s*.96,-.84,.59),(.36,1.30,.12),DARK,2,.035)
        fittings(g,s,-.45,1.40)
        # Door seam and bonnet vents, subordinate to the silhouette.
        if not BLOCKOUT:
            g.box((s*1.019,-.23,1.18),(.012,.018,.85),DARK)
            g.box((s*1.02,-.86,.76),(.013,1.18,.018),DARK)
            for i in range(4):g.box((s*.774,-1.88,1.43+i*.045),(.012,.32,.022),DARK)
            g.cyl((s*.1,-1.715,1.70),(s*.73,-1.60,1.78),.012,STEEL,2,6)
    g.box((0,-3.20,1.075),(1.95,.16,.86),IVORY,2,.11)
    for z in [.86,1.04,1.22]:
        for x in [-.34,.34]:g.panel(lambda u,v:(x+u,-3.288,z+v),.59,.095,.035,DARK)
    for s in [-1,1]:
        g.cyl((s*.79,-3.29,.99),(s*.79,-3.32,.99),.152,STEEL)
        g.cyl((s*.79,-3.325,.99),(s*.79,-3.34,.99),.118,'e1dfca')
        g.cyl((s*.80,-3.29,1.33),(s*.80,-3.32,1.33),.055,'c48735',2,12)
    g.box((0,-3.345,.53),(2.20,.15,.19),DARK,2,.035)

def zil(food):
    g=Geo();chassis(g,-3.20,3.25);zil_cab(g)
    axle(g,-2.2625);axle(g,1.5375,duals=True)
    for s in [-1,1]:
        g.box((s*.78,.28,.57),(.38,.85,.44),DARK,2,.07)
        g.box((s*.95,2.20,.39),(.5,.07,.55),DARK)
        # Rear mudguards do not occlude the tire's silhouette.
        g.box((s*.95,1.54,1.07),(.53,1.27,.09),DARK,2,.025)
    if food:
        g.box((0,1.57,2.025),(2.40,3.44,2.05),'dedbc9',3,.065)
        for s in [-1,1]:
            for z in [1.08,2.98]:g.box((s*1.204,1.57,z),(.025,3.32,.04),'b8baad',3)
            for y in [.0,1.57,3.24]:g.box((s*1.207,y,2.025),(.015,.022,1.85),'c6c7b9',3)
        rear=3.301
        for x in [-.59,.59]:
            g.panel(lambda u,v:(x+u,rear,2.03+v),1.13,1.85,.035,'c9cabb',3)
            g.cyl((x,rear+.025,1.22),(x,rear+.025,2.83),.018,STEEL,2,8)
            for z in [1.35,2.68]:g.box((x+(.49 if x>0 else -.49),rear+.035,z),(.13,.05,.065),STEEL)
        g.box((0,3.38,.70),(1.3,.22,.10),STEEL)
    else:
        g.box((0,1.48,1.12),(2.42,3.70,.16),'465d43',3)
        for s in [-1,1]:
            for i in range(4):g.box((s*1.19,1.48,1.28+i*.16),(.07,3.70,.145),'536247' if i%2 else '465840',3)
            for y in [-.34,.55,1.65,3.30]:g.box((s*1.24,y,1.53),(.05,.075,.80),'85846c',3)
        for y in [-.34,3.30]:
            for i in range(4):g.box((0,y,1.28+i*.16),(2.40,.08,.145),'4c5d42',3)
        # Tarp covers the front 76%; rear coal remains visible. Shared bows and folds.
        profile=[(-1.19,1.88),(-1.17,2.63),(-.83,2.86),(0,2.98),(.83,2.86),(1.17,2.63),(1.19,1.88)]
        rings=[]
        for i in range(19):
            y=-.36+i*2.85/18;sag=.055*math.sin(i*math.pi/3)**2
            rings.append([(x,y,z-sag if z>2 else z) for x,z in profile])
        for a,b in zip(rings[:-1],rings[1:]):
            for i in range(6):g.poly([a[i],a[i+1],b[i+1],b[i]],'777957' if i%2 else '727451',3,True)
        g.poly(rings[0][::-1],'707450',3)
        for y in [-.32,.59,1.50,2.45]:
            for s in [-1,1]:g.cyl((s*1.20,y,1.86),(s*1.22,y+.14,1.61),.013,'b1aa80',3,6)
        g.loft([[(-1.12,y,1.86),(-1.05,y,2.38),(-.48,y,2.69),(0,y,2.77),(.48,y,2.69),(1.05,y,2.38),(1.12,y,1.86)] for y in [2.43,3.24]],'303532',3,False)
        rng=random.Random(42)
        for i in range(72):
            x=rng.uniform(-1.02,1.02);y=rng.uniform(2.49,3.20);z=2.38+.37*(1-abs(x))+rng.uniform(-.05,.07)
            # A reproducible low-poly lumpy load, no particles/interior.
            r=rng.uniform(.075,.16)
            g.loft([[(x+math.cos(t*math.tau/5)*r,y+math.sin(t*math.tau/5)*r,z) for t in range(5)],[(x+math.cos(t*math.tau/5)*r*.45,y+math.sin(t*math.tau/5)*r*.45,z+r) for t in range(5)]],rng.choice(['303532','3c413e','242a28']),3,False)
    for s in [-1,1]:g.box((s*.96,3.36,.89),(.25,.07,.12),'8f392c')
    return g

def kamaz():
    g=Geo();chassis(g,-7.95,-1.82)
    # 5410 tractor anchors: front overhang 1.275, axle spacings 2.840 + 1.320.
    # Whole coupled rig centered at Y=0; front bumper -8.09.
    front=-6.815
    for y in [front,front+2.84,front+4.16]:axle(g,y,.49,2.026 if y==front else 1.856,y!=front)
    g.box((0,-7.12,1.81),(2.36,1.98,1.70),'ffffff',0,.12)
    # Crown is section lofted instead of a flat slab.
    roof=[]
    for y,k in [(-8.10,.95),(-7.98,1),(-6.25,1),(-6.12,.95)]:
        roof.append([(x*k,y,z) for x,z in [(-1.18,2.55),(-1.16,2.69),(-.85,2.75),(0,2.78),(.85,2.75),(1.16,2.69),(1.18,2.55)]])
    g.loft(roof,'ffffff',0)
    for s in [-1,1]:
        g.panel(lambda u,v:(s*.56+u,-8.135,2.19+v),1.06,.77,.055,DARK)
        g.panel(lambda u,v:(s*.56+u,-8.145,2.19+v),.98,.69,.04,GLASS,1)
        for inset,col,mat in [(0,DARK,2),(.055,GLASS,1)]:g.panel(lambda u,v:(s*(1.191+(.006 if mat==1 else 0)),-7.15+u,2.17+v),1.15-inset,.73-inset,.055,col,mat)
        # Lower cab sides stop above the wheel arch; no rectangular shell through tires.
        arch(g,s,front,.49,.45,DARK,2)
        g.box((s*1.08,-6.30,.91),(.30,.45,.1),STEEL)
        fittings(g,s,-6.75,1.60)
        g.box((s*.94,-5.18,.62),(.46,1.02,.48),DARK,2,.08)
        for y in [front+2.84,front+4.16]:g.box((s*.98,y,1.03),(.51,1.2,.09),DARK,2,.035)
        if not BLOCKOUT:
            g.box((s*1.192,-6.43,1.83),(.014,.02,1.32),DARK)
            g.cyl((s*.12,-8.13,1.84),(s*.87,-8.11,1.97),.014,STEEL,2,6)
    g.box((0,-8.15,.73),(2.43,.15,.28),DARK,2,.025)
    g.box((0,-8.126,1.27),(1.45,.035,.36),DARK)
    for z in [1.15,1.25,1.35]:g.box((0,-8.15,z),(1.38,.035,.018),STEEL)
    for s in [-1,1]:g.cyl((s*.94,-8.14,1.25),(s*.94,-8.17,1.25),.105,'dedbc8')
    for x in [-.22,0,.22]:g.box((x,-7.95,2.765),(.105,.12,.055),'bd8235',2,.015)
    g.cyl((1.0,-6.03,.8),(1.0,-6.03,2.85),.055,DARK,2,10)
    g.cyl((0,-3.18,1.15),(0,-3.18,1.25),.42,DARK)
    # Distinct skeletal trailer; lower container at 1.38, 0.13 above fifth wheel.
    for s in [-1,1]:
        g.box((s*.64,1.91,1.19),(.15,12.24,.28),DARK)
        g.box((s*.96,1.0,.66),(.07,4.9,.10),STEEL)
        g.box((s*.96,1.0,.98),(.07,4.9,.07),STEEL)
        g.box((s*.86,-2.55,.69),(.11,.14,.89),DARK)
        g.box((s*.86,-2.55,.25),(.35,.30,.07),DARK)
    for y in [-4.18,-2.5,1,4,7.99]:g.box((0,y,1.25),(2.43,.12,.16),DARK)
    for y in [5.99,7.31]:axle(g,y,.49,1.90,True)
    for s in [-1,1]:
        g.box((s*.98,6.65,1.08),(.52,2.55,.10),DARK,2,.035)
        g.box((s*.96,7.95,.4),(.52,.08,.57),DARK)
    # Standard-height 40 ft dry container. Independent 12.192 x 2.438 x 2.591 m unit.
    center=1.91;length=12.192;bottom=1.39;top=bottom+2.591
    g.box((0,center,(bottom+top)/2),(2.408,length-.06,2.55),'376280',3)
    for i in range(60):
        y=center-length/2+.18+i*(length-.36)/59
        g.box((0,y,top-.005),(2.28,.08,.025),'426e8b',3)
    for s in [-1,1]:
        for i in range(60):
            y=center-length/2+.18+i*(length-.36)/59
            g.box((s*1.218,y,(bottom+top)/2),(.045,.085,2.40),'426e8b',3,0)
        for z in [bottom+.06,top-.06]:g.box((s*1.18,center,z),(.10,length,.12),'527993',3)
    for y in [center-length/2,center+length/2]:
        for s in [-1,1]:
            g.box((s*1.17,y,(bottom+top)/2),(.10,.10,2.591),'527993',3)
            for z in [bottom+.065,top-.065]:g.box((s*1.16,y,z),(.14,.14,.13),STEEL)
    rear=center+length/2+.02
    for x in [-.58,.58]:
        g.panel(lambda u,v:(x+u,rear,2.685+v),1.10,2.34,.015,'396583',3)
        for xx in [x-.29,x+.29]:g.cyl((xx,rear+.025,1.57),(xx,rear+.025,3.80),.018,STEEL,2,8)
        for z in [1.8,2.66,3.54]:g.box((x+(.52 if x>0 else -.52),rear+.035,z),(.13,.04,.07),STEEL)
    g.box((0,8.11,.52),(2.30,.12,.12),STEEL)
    for s in [-1,1]:g.box((s*.91,8.08,1.12),(.28,.065,.14),'8f392c')
    return g

scene=bpy.data.scenes.new('Freight_Blockout' if BLOCKOUT else 'Freight_Studio');bpy.context.window.scene=scene
mats=[material('Truck cab paint','7493a3'),material('Truck opaque glass',GLASS,.25),material('Truck mechanical and trim','ffffff',.7,.12,True),material('Truck cargo','ffffff',.85,0,True)]
for name,builder,x,paint in [('ZIL_Food',lambda:zil(True),-4,'7493a3'),('ZIL_Coal',lambda:zil(False),0,'56684e'),('KamAZ_Container',kamaz,5,'b7ad8b')]:
    local=list(mats);local[0]=material(('KamAZ' if name=='KamAZ_Container' else name)+' cab paint',paint)
    o=builder().obj(name,scene.collection,local);o.location.x=x
    o['forward']='Blender -Y / Godot +Z';o['source_units']='metres with Volga L/W/H factors'
world=bpy.data.worlds.new('Freight world');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.3,.34,.39,1);world.node_tree.nodes['Background'].inputs[1].default_value=.7;scene.world=world
for name,rot,energy in [('Key',(30,-20,-35),3),('Fill',(40,20,145),1)]:
    l=bpy.data.objects.new(name,bpy.data.lights.new(name,'SUN'));scene.collection.objects.link(l);l.rotation_euler=[math.radians(x) for x in rot];l.data.energy=energy
bpy.ops.wm.save_as_mainfile(filepath=str(HERE/('trucks_blockout.blend' if BLOCKOUT else 'trucks.blend')))
print('Freight build complete',flush=True)
