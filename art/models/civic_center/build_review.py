"""Original separate civic review assets. Run in an isolated Blender scene via MCP.

Source exports remain outside init until visual approval. Metres, front Blender -Y.
"""
from pathlib import Path
import bpy, math, json, random
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
OUT = HERE / 'review_exports'
OUT.mkdir(exist_ok=True)
TEX = HERE / 'textures'
TEX.mkdir(exist_ok=True)
random.seed(97)
scene = bpy.data.scenes.new('Civic_Assets_Review')
bpy.context.window.scene = scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1
objects = []
assets = {}
report = {}

def material(name, rgb, metallic=0, rough=.8, mottled=False):
    m = bpy.data.materials.new('Civic_' + name)
    m.diffuse_color = (*rgb, 1)
    m.use_nodes = True
    bs = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bs.inputs['Base Color'].default_value = (*rgb, 1)
    bs.inputs['Metallic'].default_value = metallic
    bs.inputs['Roughness'].default_value = rough
    if mottled:
        size = 128
        img = bpy.data.images.new('Civic_' + name + '_color', width=size, height=size)
        pixels = []
        rng = random.Random(name)
        for y in range(size):
            for x in range(size):
                wave = .07*math.sin(x*.13)*math.cos(y*.17) + rng.uniform(-.045,.045)
                pixels.extend([max(.001, min(1,c*(1+wave))) for c in rgb] + [1])
        img.pixels = pixels
        img.filepath_raw = str(TEX / (name + '_color.png'))
        img.save()
        node = m.node_tree.nodes.new('ShaderNodeTexImage')
        node.image = img
        m.node_tree.links.new(node.outputs['Color'], bs.inputs['Base Color'])
    return m

stone=material('Limestone',(.64,.59,.47),mottled=True)
granite=material('Granite',(.23,.24,.23),mottled=True)
bronze=material('Patinated_Bronze',(.16,.19,.135),.68,.55,True)
wood=material('Varnished_Wood',(.30,.145,.054),mottled=True)
metal=material('Painted_Iron',(.065,.085,.075),.5,.65)
glass=material('Smoked_Glass',(.055,.085,.10),.25,.28)
roof=material('Roof_Felt',(.12,.13,.135),mottled=True)
soil=material('Soil',(.12,.083,.045),mottled=True)
leaf=material('Leaf_Green',(.18,.27,.065),mottled=True)
leaflight=material('Leaf_Light',(.28,.35,.10),mottled=True)
bark=material('Bark',(.23,.19,.13),mottled=True)
cream=material('Lamp_Glass',(.68,.63,.43),0,.42)
paper=material('Notice_Paper',(.73,.68,.50))
burgundy=material('Blank_Flag',(.29,.065,.075))

def finish(o,name,mat):
    o.name=name
    o.data.materials.append(mat)
    objects.append(o)
    return o

def box(name,p,s,mat,bevel=.015):
    bpy.ops.mesh.primitive_cube_add(size=1,location=p)
    o=bpy.context.object
    o.dimensions=s
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('Edge highlights','BEVEL');mod.width=bevel;mod.segments=2
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(o,name,mat)

def rod(name,a,b,r,mat,r2=None,vertices=10):
    a,b=Vector(a),Vector(b)
    bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=r,radius2=r if r2 is None else r2,depth=(b-a).length,location=(a+b)/2)
    o=bpy.context.object
    o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
    return finish(o,name,mat)

def ellipsoid(name,p,s,mat,subdiv=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv,radius=1,location=p)
    o=bpy.context.object;o.scale=s
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    for poly in o.data.polygons: poly.use_smooth=True
    return finish(o,name,mat)

def poly(name,verts,faces,mat):
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    o=bpy.data.objects.new(name,mesh);scene.collection.objects.link(o)
    finish(o,name,mat)
    return o

def export(name,start):
    parts=objects[start:]
    bpy.ops.object.select_all(action='DESELECT')
    for o in parts:o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.object.join()
    o=bpy.context.object;o.name=name
    # UVs for original procedural color maps are portable image textures.
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(island_margin=.015)
    bpy.ops.object.mode_set(mode='OBJECT')
    o.data.calc_loop_triangles()
    report[name]={'triangles':len(o.data.loop_triangles),'dimensions_m':list(o.dimensions),'front':'Blender -Y; Godot +Z'}
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,use_active_scene=True,export_apply=True,export_cameras=False,export_lights=False,export_animations=False)
    assets[name]=o
    return o

# Park furniture: reusable original meshes at real dimensions.
s=len(objects)
for x in [-.65,.65]:
    box('Bench foot',(x,0,.055),(.12,.64,.11),metal)
    rod('Bench leg',(x,0,.10),(x,.08,.48),.045,metal)
    rod('Back support',(x,.21,.42),(x,.36,.92),.03,metal)
    rod('Arm support',(x,-.18,.45),(x,-.18,.66),.025,metal)
    rod('Armrest',(x,-.24,.67),(x,.25,.67),.033,metal)
for y in [-.24,-.08,.08,.24]:box('Seat slat',(0,y,.47),(1.85,.135,.05),wood,.008)
for z in [.64,.77,.90]:
    o=box('Back slat',(0,.30+(z-.64)*.18,z),(1.85,.05,.105),wood,.008);o.rotation_euler.x=-.15
export('park_bench',s)

s=len(objects)
box('Bin base',(0,0,.07),(.50,.50,.14),granite)
box('Bin body',(0,0,.40),(.44,.44,.60),metal,.025)
for x in [-.23,.23]:box('Bin rim',(x,0,.72),(.035,.50,.05),metal)
for y in [-.23,.23]:box('Bin rim',(0,y,.72),(.50,.035,.05),metal)
box('Bin dark opening',(0,0,.66),(.40,.40,.025),soil,0)
export('park_bin',s)

s=len(objects)
for x in [-1.0,1.0]:rod('Fence post',(x,0,0),(x,0,1.04),.035,metal)
for z in [.15,.87]:box('Horizontal rail',(0,0,z),(2.06,.035,.035),metal,.005)
for i in range(11):rod('Vertical picket',(-.9+i*.18,0,.15),(-.9+i*.18,0,.97),.013,metal,vertices=6)
export('park_railing_2m',s)

s=len(objects)
for y in [-.60,.60]:box('Planter long curb',(0,y,.18),(2.4,.12,.36),stone)
for x in [-1.14,1.14]:box('Planter short curb',(x,0,.18),(.12,1.08,.36),stone)
box('Planter soil',(0,0,.22),(2.16,1.08,.08),soil)
export('park_planter_2m',s)

s=len(objects)
rod('Lamp plinth',(0,0,0),(0,0,.25),.19,granite,r2=.15)
rod('Tapered lamp pole',(0,0,.25),(0,0,3.55),.07,metal,r2=.04)
rod('Lantern base',(0,0,3.55),(0,0,3.65),.18,metal)
box('Lantern glass',(0,0,3.90),(.31,.31,.50),cream,.005)
for x in [-.17,.17]:
    for y in [-.17,.17]:rod('Lantern frame',(x,y,3.63),(x,y,4.17),.016,metal,vertices=6)
rod('Lantern roof',(0,0,4.16),(0,0,4.35),.29,metal,r2=.035,vertices=8)
export('park_lantern',s)

s=len(objects)
for i in range(12):
    x=random.uniform(-.75,.75);y=random.uniform(-.55,.55)
    ellipsoid('Shrub foliage',(x,y,.30+random.uniform(0,.35)),(.38,.38,.40),leaf if i%3 else leaflight)
export('park_shrub',s)

s=len(objects)
rod('Tree trunk',(0,0,0),(.1,0,4.2),.16,bark,r2=.065)
for i in range(10):
    a=i*2.399;z=2.7+i*.28;r=1.2 if i<7 else .7
    x=math.cos(a)*r;y=math.sin(a)*r
    rod('Tree branch',(.05,0,z-.8),(x,y,z+.4),.055,bark,r2=.02)
    ellipsoid('Canopy',(x,y,z+.65),(1.1,1.0,1.25),leaf if i%3 else leaflight)
export('park_deciduous_tree',s)

s=len(objects)
rod('Conifer trunk',(0,0,0),(0,0,5.5),.10,bark,r2=.035)
for i in range(7):
    z=.8+i*.61
    rod('Conifer crown',(0,0,z),(0,0,z+2.0),1.45-i*.15,leaf,r2=0,vertices=12)
export('park_conifer',s)

# A sculptural study, not a substituted political leader. About 3 m figure + 2.2 m base.
s=len(objects)
for z,w,d,h in [(.12,3.2,2.6,.24),(.35,2.7,2.15,.22),(.57,2.3,1.8,.22),(1.36,1.6,1.35,1.36),(2.10,1.85,1.55,.15)]:
    box('Monument granite',(0,0,z),(w,d,h),granite,.03)
base=2.18
for x,y in [(-.24,-.07),(.27,.10)]:
    box('Work boot',(x,y-.13,base+.10),(.28,.53,.20),bronze,.05)
    rod('Trouser leg',(x,y,base+.22),(x*.8,y+.04,base+1.20),.16,bronze,r2=.22,vertices=10)
ellipsoid('Pelvis',(0,.05,base+1.20),(.45,.25,.28),bronze)
# Angular jacket torso with broad shoulders and a pinched waist.
verts=[]
for z,w,d in [(1.15,.40,.23),(1.43,.34,.24),(2.13,.56,.27),(2.28,.48,.22)]:
    verts.extend([(-w,-d,base+z),(w,-d,base+z),(w,d,base+z),(-w,d,base+z)])
faces=[(0,3,2,1),(12,13,14,15)]
for k in range(3):
    for i in range(4):faces.append((k*4+i,k*4+(i+1)%4,(k+1)*4+(i+1)%4,(k+1)*4+i))
jacket=poly('Worker jacket',verts,faces,bronze)
bevel=jacket.modifiers.new('Sculpted jacket edges','BEVEL');bevel.width=.085;bevel.segments=3
bpy.context.view_layer.objects.active=jacket
bpy.ops.object.modifier_apply(modifier=bevel.name)
rod('Neck',(0,0,base+2.17),(0,0,base+2.40),.12,bronze)
ellipsoid('Head',(0,-.015,base+2.60),(.205,.205,.265),bronze,3)
ellipsoid('Jaw',(0,-.055,base+2.46),(.16,.17,.12),bronze)
ellipsoid('Nose',(0,-.211,base+2.59),(.044,.073,.075),bronze)
for x in [-.21,.21]:ellipsoid('Ear',(x,.0,base+2.59),(.043,.055,.075),bronze)
for x in [-.085,.085]:rod('Brow',(x-.045,-.198,base+2.68),(x+.045,-.198,base+2.67),.018,bronze,vertices=6)
rod('Lower lip',(-.07,-.19,base+2.49),(.07,-.19,base+2.49),.014,bronze,vertices=6)
# Flat working cap, not a helmet or a crown.
ellipsoid('Worker cap',(0,.015,base+2.82),(.235,.215,.075),bronze)
box('Cap visor',(0,-.20,base+2.79),(.35,.23,.035),bronze,.025)
# One hand on a compact survey/rail plan, other grips a long-handled track hammer.
rod('Left sleeve',(-.47,0,base+2.08),(-.60,-.10,base+1.68),.16,bronze,r2=.12)
rod('Left forearm',(-.60,-.10,base+1.68),(-.27,-.36,base+1.61),.12,bronze,r2=.085)
ellipsoid('Left hand',(-.24,-.37,base+1.62),(.105,.085,.115),bronze)
rod('Rolled plan',(-.43,-.37,base+1.50),(.28,-.37,base+1.67),.085,bronze,vertices=12)
rod('Right sleeve',(.48,.0,base+2.09),(.62,-.02,base+1.67),.16,bronze,r2=.12)
rod('Right forearm',(.62,-.02,base+1.67),(.61,-.16,base+1.33),.12,bronze,r2=.08)
ellipsoid('Right hand',(.61,-.17,base+1.30),(.10,.09,.13),bronze)
rod('Track hammer handle',(.62,-.15,base+.18),(.62,-.15,base+1.45),.035,bronze)
box('Track hammer head',(.62,-.15,base+.18),(.48,.17,.17),bronze,.03)
for a,b in [((-.12,-.26,base+2.18),(0,-.29,base+1.90)),((.12,-.26,base+2.18),(0,-.29,base+1.90))]:rod('Jacket lapel',a,b,.028,bronze,vertices=6)
for z in [1.45,1.65,1.83]:ellipsoid('Jacket button',(0,-.26,base+z),(.024,.018,.024),bronze,1)
for x in [-.25,.25]:
    box('Jacket pocket',(x,-.265,base+1.55),(.20,.035,.22),bronze,.025)
    rod('Trouser pressed fold',(x,-.18,base+.30),(x*.8,-.18,base+1.05),.018,bronze,vertices=6)
rod('Jacket lower hem',(-.34,-.245,base+1.24),(.34,-.245,base+1.24),.025,bronze)
box('Blank dedication plaque',(0,-.688,1.37),(.85,.025,.38),bronze,.008)
export('transport_founder_monument_study',s)

# Preserve the full editable library, with assets spread apart only AFTER export.
for i,(name,o) in enumerate(assets.items()):o.location.x+=(i%5)*5;o.location.y+=(i//5)*7
scene['review_only']=True
scene['note']='Original civic furniture and monument study. No map integration. Generated facade still awaits visual approval.'
bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'civic_assets_review.blend'))
(HERE/'asset_report.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
