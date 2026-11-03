"""Resumable first 3D pass. Run with Blender --background --python this_file.

Godot metres: +X east, +Y up, +Z platform-facing. Blender uses (x,-z,y).
Creates an isolated scene, saves editable sources, exports asset selections only.
"""
from pathlib import Path
import bpy
import math
import json
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
OUT = ROOT / 'init/assets/models/station_hub'
OUT.mkdir(parents=True, exist_ok=True)
scene = bpy.data.scenes.new('StationHub_AssetBuild')
bpy.context.window.scene = scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1

def point(g):
    return (g[0], -g[2], g[1])

def material(name, color, texture=None, roughness=.85):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    shader = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    shader.inputs['Base Color'].default_value = (*color, 1)
    shader.inputs['Roughness'].default_value = roughness
    if texture:
        image = bpy.data.images.load(str(HERE/'textures'/texture), check_existing=True)
        node = m.node_tree.nodes.new('ShaderNodeTexImage')
        node.image = image
        m.node_tree.links.new(node.outputs['Color'], shader.inputs['Base Color'])
    return m

stone = material('Station pale limestone', (.77,.73,.63), 'station-facing-v1.png')
roof = material('Maintained bitumen', (.13,.14,.14), 'station-roof-v1.png')
canvas = material('Neutral woven canvas', (.85,.81,.69), 'stall-canvas-v1.png')
red = material('Canvas muted red', (.49,.13,.09))
blue = material('Canvas faded blue', (.15,.29,.38))
ochre = material('Canvas ochre', (.57,.42,.17))
olive = material('Olive painted metal', (.23,.29,.23), roughness=.65)
glass = material('Opaque blue grey glass', (.10,.17,.18), roughness=.28)
tile = material('Red brown ceramic plinth', (.28,.12,.085))
concrete = material('Warm concrete', (.59,.58,.53))
cream = material('Painted cream', (.82,.79,.67))
wood = material('Warm timber', (.35,.22,.11))
dark = material('Dark fittings', (.12,.14,.13))
mosaic = material('Station ceramic mosaic', (1,1,1), 'station-mosaic-v1.png')
ads = material('Period printed advertisements', (1,1,1), 'station-ads-v2.png')
goods = [material('Clothing '+str(i), c) for i,c in enumerate([
    (.14,.22,.28),(.42,.26,.20),(.29,.33,.25),(.62,.58,.47),(.25,.19,.28)])]
font = bpy.data.fonts.load('C:/Windows/Fonts/arialbd.ttf')

def box(name, at, size, mat, bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=point(at))
    ob = bpy.context.object
    ob.name = name
    ob.dimensions = (size[0],size[2],size[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    ob.data.materials.append(mat)
    if bevel:
        mod = ob.modifiers.new('Small physical edges','BEVEL')
        mod.width = bevel
        mod.segments = 1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return ob

def mesh(name, vertices, faces, mat, uvs=None):
    data = bpy.data.meshes.new(name)
    data.from_pydata([point(v) for v in vertices], [], faces)
    data.update()
    ob = bpy.data.objects.new(name,data)
    scene.collection.objects.link(ob)
    ob.data.materials.append(mat)
    if uvs:
        layer=data.uv_layers.new()
        for poly in data.polygons:
            for loop in poly.loop_indices:
                layer.data[loop].uv = uvs[data.loops[loop].vertex_index]
    return ob

def panel(name, x,y,z,w,h,mat,uv=(0,0,1,1),back=False):
    u0,v0,u1,v1=uv
    ob=mesh(name,[(x-w/2,y-h/2,z),(x+w/2,y-h/2,z),
                  (x+w/2,y+h/2,z),(x-w/2,y+h/2,z)],
                  [(0,1,2,3)] if not back else [(3,2,1,0)],mat,
                  [(u0,v0),(u1,v0),(u1,v1),(u0,v1)])
    return ob

def poster(index,x,y,z,w,h):
    col=index%3
    row=index//3
    uv=((27+col*504)/1536,1-(497+row*500)/1024,
        (502+col*504)/1536,1-(28+row*500)/1024)
    box('Poster backing',(x,y,z-.025),(w+.10,h+.10,.05),olive)
    panel('Printed advertisement',x,y,z+.01,w,h,ads,uv)

def text(label,at,size,mat):
    data=bpy.data.curves.new(label,'FONT')
    data.body=label
    data.font=font
    data.align_x='CENTER'
    data.size=size
    data.extrude=.012
    ob=bpy.data.objects.new(label,data)
    scene.collection.objects.link(ob)
    ob.location=point(at)
    ob.rotation_euler=(math.pi/2,0,0)
    ob.data.materials.append(mat)
    bpy.context.view_layer.objects.active=ob
    ob.select_set(True)
    bpy.ops.object.convert(target='MESH')
    ob.select_set(False)
    return ob

def station():
    box('Hall',(0,2.9,0),(20,5.8,14),stone,.04)
    for x in [-14,14]:
        box('Low service wing',(x,2.35,0),(8,4.7,14),stone,.04)
        box('Wing roofing',(x,4.76,0),(8.15,.12,14.15),roof)
    box('Hall roofing',(0,5.88,0),(20.15,.16,14.15),roof)
    for side in [-1,1]:
        z=side*7.035
        box('Continuous tiled plinth',(0,.38,z),(36,.76,.08),tile)
        panel('Glazed public hall',0,3.05,z+side*.045,18.6,4.3,glass,back=side<0)
        for x in range(-9,10):
            box('Window mullion',(x,3.05,z+side*.075),(.055,4.35,.075),olive)
        for y in [1.0,2.3,4.4,5.2]:
            box('Window transom',(0,y,z+side*.075),(18.7,.055,.075),olive)
        box('Entrance doors',(0,1.6,z+side*.10),(3.0,2.9,.08),olive)
        for x in [-.72,.72]:
            panel('Door glass',x,1.9,z+side*.16,1.32,2.15,glass,back=side<0)
        box('Entrance canopy',(0,3.72,side*8),(7,.25,2.6),concrete,.04)
        box('Canopy metal lip',(0,3.62,side*9.28),(7.05,.09,.07),olive)
        box('Hall parapet',(0,6.02,side*6.97),(20.35,.45,.22),stone)
        for x in [-17.8,-16,-12,-10.1,10.1,12,16,17.8]:
            box('Facing vertical joint',(x,2.55,z+side*.025),(.022,3.5,.02),concrete)
    panel('Ceramic transport mural',-14,2.65,7.11,5.2,3.3,mosaic)
    poster(3,12,2.6,7.13,1.9,1.15)
    poster(2,15.5,2.4,7.13,2.4,1.65)
    poster(0,-17,2.6,7.13,1.0,1.5)
    for x in [18.03,-18.03]:
        for z in [-3,1,4]:
            box('End window',(x,2.8,z),(.06,1.8,1.4),olive)
            box('End glazing',(x+(.035 if x>0 else -.035),2.8,z),(.02,1.6,1.2),glass)
    box('Station sign backing',(0,6.95,7.10),(12,1.12,.18),cream,.025)
    text('ВОКЗАЛ',(0,6.55,7.22),.95,tile)
    box('Clock box',(7.2,7.15,6.8),(1.35,1.45,.3),olive,.035)
    panel('Clock face',7.2,7.15,6.965,1.22,1.32,cream)
    for n in range(12):
        ang=n*math.tau/12
        ob=box('Clock tick',(7.2+math.sin(ang)*.48,7.15+math.cos(ang)*.51,6.98),(.035,.10,.022),dark)
        ob.rotation_euler.y=-ang
    box('Clock hour',(7.2,7.33,7.0),(.04,.36,.02),dark)
    hand=box('Clock minute',(7.40,7.15,7.01),(.40,.035,.02),dark)
    for x,z in [(-6,-3),(6,0),(-14,2),(14,-2)]:
        y=6.12 if abs(x)<10 else 4.94
        box('Visible roof vent',(x,y,z),(.65,.35,.65),olive,.025)

def stall(variant):
    cover=[canvas,blue,ochre][variant]
    for x in [-1.46,1.46]:
        for z in [-1.21,1.21]:
            box('Tube leg',(x,1.13,z),(.045,2.26,.045),olive)
    for z in [-1.22,1.22]:
        box('Top rail',(0,2.23,z),(3,.045,.045),olive)
    # Thin pitched roof strips have a slight bow, shared neutral fabric UVs.
    for side in [-1,1]:
        for strip in range(12):
            x0=-1.58+strip*3.16/12
            x1=-1.58+(strip+1)*3.16/12
            verts=[]
            for z,y in [(0,2.82),(side*.70,2.55),(side*1.40,2.23)]:
                sag=.025*math.sin((strip+.5)*math.pi/12)
                verts += [(x0,y-sag,z),(x1,y-sag,z)]
            mat=red if variant==0 and strip%4<2 else cover
            mesh('Woven canopy strip',verts,[(0,1,3,2),(2,3,5,4)],mat,
                 [(strip/12,.5),((strip+1)/12,.5),(strip/12,.75),((strip+1)/12,.75),(strip/12,1),((strip+1)/12,1)])
    box('Back curtain',(0,1.25,-1.20),(2.9,1.9,.025),cover)
    box('Right curtain',(1.45,1.24,-.25),(.025,1.85,1.9),cover)
    box('Counter board',(0,.9,.85),(2.85,.10,.65),wood)
    for x in [-1.23,1.23]:
        box('Counter leg',(x,.43,.85),(.06,.86,.06),olive)
    box('Clothes rail',(0,1.99,.10),(2.65,.035,.035),olive)
    for i in range(5):
        x=-1.05+i*.52
        mesh('Hanging jacket',[(x-.14,1.89,.12),(x-.29,1.75,.12),(x-.21,1.53,.12),
             (x-.15,1.63,.12),(x-.15,1.21,.12),(x+.15,1.21,.12),
             (x+.15,1.63,.12),(x+.21,1.53,.12),(x+.29,1.75,.12),(x+.14,1.89,.12)],
             [tuple(range(10))],goods[(i+variant)%len(goods)])
        for j in range(3):
            box('Folded clothes',(x,.99+j*.05,.85),(.42,.047,.38),goods[(i+j)%len(goods)])
    for x in [-.8,.65]:
        box('Cardboard stock',(x,.22,.3),(.62,.44,.48),wood)

def bench(x=0,z=0):
    for d in range(4):
        box('Bench seat slat',(x,.47,z-.23+d*.14),(1.8,.055,.11),wood)
    for y in [.78,.96]:
        box('Bench back slat',(x,y,z-.29),(1.8,.12,.055),wood)
    for dx in [-.66,.66]:
        box('Bench foot',(x+dx,.24,z),(.07,.48,.56),olive)

def shelter():
    box('Shelter roof',(0,2.9,0),(6.3,.16,3.2),roof,.035)
    for x in [-2.85,0,2.85]:
        box('Shelter post',(x,1.43,-1.3),(.075,2.86,.075),olive)
    for x in [-2.85,2.85]:
        box('Shelter front post',(x,1.43,1.28),(.075,2.86,.075),olive)
    for x in [-1.44,1.44]:
        box('Shelter back panel',(x,1.5,-1.29),(2.75,2.0,.045),glass)
    for z in [-1.5,1.5]:
        box('Shelter fascia',(0,2.85,z),(6.3,.26,.08),olive)
    bench(-1.2,-.75)
    box('Timetable board',(1.8,1.65,-1.22),(1.0,1.4,.09),cream)
    for i in range(8):
        box('Timetable line',(1.8,1.25+i*.11,-1.16),(.8,.015,.014),dark)

def kiosk():
    box('Kiosk body',(0,1.25,0),(3,2.5,2.5),cream,.03)
    box('Kiosk plinth',(0,.19,0),(3.06,.38,2.56),tile)
    box('Kiosk roofing',(0,2.57,0),(3.2,.14,2.7),roof)
    box('Serving window',(0,1.65,1.28),(2.4,1.3,.06),olive)
    box('Serving glass',(0,1.65,1.32),(2.25,1.15,.03),glass)
    box('Serving shelf',(0,1.02,1.43),(2.5,.10,.5),wood)
    poster(2,0,2.3,1.36,2.4,.5)
    for i in range(8):
        box('Awning stripe',(-1.35+i*.385,2.02,1.65),(.38,.08,.8),red if i%2 else canvas)

def lamp():
    box('Lamp post',(0,2.65,0),(.10,5.3,.10),olive,.015)
    box('Lamp arm',(.5,5.25,0),(1.1,.09,.09),olive)
    box('Lamp housing',(1.0,5.21,0),(.55,.13,.26),cream,.03)

builders={'station':station,'stall_red':lambda:stall(0),'stall_blue':lambda:stall(1),
          'stall_ochre':lambda:stall(2),'bus_shelter':shelter,'kiosk':kiosk,
          'bench':bench,'lamp':lamp}
reports=[]
for name,build in builders.items():
    bpy.ops.object.select_all(action='DESELECT')
    before=set(scene.objects)
    build()
    objects=[o for o in scene.objects if o not in before]
    collection=bpy.data.collections.new('asset_'+name)
    scene.collection.children.link(collection)
    for ob in objects:
        for old in list(ob.users_collection): old.objects.unlink(ob)
        collection.objects.link(ob)
    # Consolidate each asset to a single mesh with shared material slots.
    for ob in objects: ob.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.object.join()
    asset=bpy.context.object
    asset.name=name
    # Keep geometry in authored metre coordinates with an origin at ground centre.
    scene.cursor.location=(0,0,0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    for image in bpy.data.images:
        if image.source=='FILE' and not image.packed_file: image.pack()
    path=OUT/(name+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,
        use_active_scene=True,export_yup=True,export_apply=True,export_materials='EXPORT')
    asset.data.calc_loop_triangles()
    reports.append({'asset':name,'triangles':len(asset.data.loop_triangles),
        'materials':len(asset.data.materials),'objects_exported':1,'path':path.relative_to(ROOT).as_posix()})
    asset.hide_set(True)
    asset.select_set(False)
    print('EXPORTED',name,flush=True)
for ob in scene.objects: ob.hide_set(False)
bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'station_hub.blend'))
(HERE/'export_report.json').write_text(json.dumps(reports,indent=2),encoding='utf-8')
print('STATION_HUB_ASSETS_COMPLETE',flush=True)
