"""Original measured dormitory. Blender -Y front exports as Godot +Z.
Stages: -- textures | blockout | build. Run with Blender --background --factory-startup.
"""
from pathlib import Path
import bpy, math, random, sys, json
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
OUT = ROOT / 'init/assets/models/dormitory'
SOURCE = ROOT / 'art/source_images/dormitory'
PREVIEW = ROOT / '.local/dormitory'
PREVIEW.mkdir(parents=True,exist_ok=True)
stage = sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else 'build'
random.seed(611)
if stage == 'textures':
    # Original seamless silicate-brick albedo: 2 x 2 m repeat, no painted windows.
    n = 512
    image = bpy.data.images.new('Silicate brick original', width=n, height=n)
    pixels = []
    for y in range(n):
        row = int(y * 25 / n)
        fy = (y * 25 / n) % 1
        for x in range(n):
            bx = x * 8 / n + (row % 2) * .5
            fx = bx % 1
            noise = random.uniform(-.025, .025)
            tint = math.sin(int(bx)*31 + row*71)*.028 + noise
            col = (.57,.56,.51) if fy < .065 or fx < .035 else (.74+tint,.715+tint,.63+tint)
            pixels.extend((*col,1))
    image.pixels = pixels
    image.filepath_raw = str(SOURCE/'silicate-brick-v1.png')
    image.file_format = 'PNG'
    image.save()
    print('Source texture saved; optimizer preparation required before build.')
    raise SystemExit

scene = bpy.data.scenes.new('Dormitory_Original')
bpy.context.window.scene = scene
scene.unit_settings.system = 'METRIC'
parts = []
def mat(name, color, texture=None, metal=0, rough=.8):
    m = bpy.data.materials.new(name); m.use_nodes = True
    m.diffuse_color = (*color,1)
    p = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value = (*color,1)
    p.inputs['Roughness'].default_value = rough
    p.inputs['Metallic'].default_value = metal
    if texture:
        t=m.node_tree.nodes.new('ShaderNodeTexImage')
        t.image=bpy.data.images.load(str(texture),check_existing=True)
        m.node_tree.links.new(t.outputs['Color'],p.inputs['Base Color'])
    return m
brick=mat('Warm silicate brick',(.74,.71,.63),OUT/'silicate_brick.png' if stage=='build' else None)
red=mat('Red brown brick plinth',(.28,.12,.075))
roof=mat('Felt roof',(.08,.085,.075),ROOT/'art/models/civic_center/textures/clean_roof_felt.png' if stage=='build' else None)
concrete=mat('Weathered concrete',(.48,.49,.46))
frame=mat('Painted ivory window frames',(.76,.75,.67))
glass=mat('Blue grey glazing',(.12,.18,.20),metal=.15,rough=.29)
curtain=mat('Linen curtains',(.57,.54,.45))
dark=mat('Dark metal',(.07,.09,.085),metal=.2)
blue=mat('Blue grey canopy',(.22,.31,.34))
sign=mat('Cream sign enamel',(.84,.80,.65))

def box(name, at, size, material):
    x,y,z=at; a,b,c=(v/2 for v in size)
    verts=[(x-a,y-b,z-c),(x+a,y-b,z-c),(x+a,y+b,z-c),(x-a,y+b,z-c),
           (x-a,y-b,z+c),(x+a,y-b,z+c),(x+a,y+b,z+c),(x-a,y+b,z+c)]
    faces=[(0,3,2,1),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7)]
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    uv=mesh.uv_layers.new()
    for poly in mesh.polygons:
        normal=poly.normal
        for li in poly.loop_indices:
            p=mesh.vertices[mesh.loops[li].vertex_index].co
            uv.data[li].uv=(p.x/2,p.y/2) if abs(normal.z)>.5 else ((p.x/2,p.z/2) if abs(normal.y)>.5 else (p.y/2,p.z/2))
    ob=bpy.data.objects.new(name,mesh);scene.collection.objects.link(ob)
    mesh.materials.append(material);parts.append(ob)
    return ob

# A single canonical L plan. Main bar 30 x 11 m, western return 11 x 12 m.
for name,at,size in [('Main bar',(0,5.5,6.3),(30,11,12.6)),('West return',(-9.5,-6,6.3),(11,12,12.6))]:
    box(name,at,size,brick)
    box(name+' red plinth',(at[0],at[1],.4),(size[0]+.05,size[1]+.05,.8),red)
    box(name+' roof felt',(at[0],at[1],12.63),(size[0],size[1],.12),roof)
outline=[(-15,-12),(-4,-12),(-4,0),(15,0),(15,11),(-15,11)]
for a,b in zip(outline,outline[1:]+outline[:1]):
    x,y=(a[0]+b[0])/2,(a[1]+b[1])/2
    sx,sy=abs(a[0]-b[0]),abs(a[1]-b[1])
    box('Perimeter parapet',(x,y,12.85),(sx+.24,sy+.24,.45),brick)
    box('Perimeter coping',(x,y,13.09),(sx+.36,sy+.36,.07),concrete)

if stage=='build':
    def window(x,y,z,angle=0,w=1.5,h=1.65):
        start=len(parts)
        # Layered shallow recess, glazing, jambs, central mullion and sill.
        box('Window dark reveal',(0,.015,z),(w+.20,.12,h+.20),dark)
        box('Recessed glazing',(0,-.056,z),(w,.035,h),glass)
        for dx in [-w/2,w/2,0]:box('Frame upright',(dx,-.09,z),(.065,.10,h+.07),frame)
        for dz in [-h/2,h/2,.30]:box('Frame crosspiece',(0,-.09,z+dz),(w+.09,.10,.065),frame)
        box('Concrete sill',(0,-.17,z-h/2-.075),(w+.32,.38,.11),concrete)
        if random.random()<.78:
            for dx in [-w*.33,w*.33]:box('Curtain',(dx,-.08,z),(.28,.012,h-.16),curtain)
        for ob in parts[start:]:
            px,py,pz=ob.location # mesh coordinates are baked, rotate about facade origin
            for v in ob.data.vertices:
                a,b=v.co.x,v.co.y
                v.co.x=x+a*math.cos(angle)-b*math.sin(angle)
                v.co.y=y+a*math.sin(angle)+b*math.cos(angle)
    for floor in range(4):
        z=1.9+floor*3
        for x in [-1,6,10,13]:window(x,0,z)
        for x in range(-13,15,4):window(x,11,z,math.pi)
        for y in [2,6,9]:window(15,y,z,math.pi/2)
        for y in [-10,-6,-2,3,7]:window(-15,y,z,-math.pi/2)
        for y in [-9,-5,-1.8]:window(-4,y,z,math.pi/2)
        for x in [-12,-8]:window(x,-12,z,w=2.1 if floor==0 else 1.5)
    # Tall stair bay and entrance face the open southeastern courtyard.
    box('Stair brick accent',(2.7,-.09,6.3),(3.1,.20,11.0),red)
    for z in [4.1,7.1,10.1]:window(2.7,-.22,z,w=1.7,h=2.55)
    box('Entrance portal',(2.7,-.18,1.6),(2.6,.4,2.65),concrete)
    box('Double entrance doors',(2.7,-.41,1.55),(1.95,.08,2.45),blue)
    box('Door divider',(2.7,-.47,1.55),(.07,.06,2.45),frame)
    for x in [2.25,3.15]:
        box('Door glass',(x,-.47,1.92),(.66,.025,1.1),glass)
        box('Door handle',(x+.22,-.52,1.15),(.035,.05,.32),sign)
    box('Entrance canopy',(2.7,-1.0,3.15),(4.1,2.3,.20),blue)
    for i in range(3):box('Entrance step',(2.7,-.7-i*.38,.12+(2-i)*.10),(3.1,1.1+i*.7,.18),concrete)
    box('Notice board',(.35,-.10,1.65),(1.05,.12,1.05),dark)
    box('Notice paper',(.35,-.17,1.65),(.91,.025,.91),sign)
    box('Sign plaque',(6.1,-.13,3.45),(4.3,.12,.63),sign)
    curve=bpy.data.curves.new('Dormitory Cyrillic sign','FONT');curve.body='ОБЩЕЖИТИЕ № 2'
    curve.font=bpy.data.fonts.load(str(ROOT/'init/assets/fonts/golos_text.ttf'))
    curve.align_x='CENTER';curve.size=.33;curve.extrude=.002
    ob=bpy.data.objects.new('Entrance lettering',curve);scene.collection.objects.link(ob)
    ob.location=(6.1,-.202,3.30);ob.rotation_euler=(math.pi/2,0,0);curve.materials.append(dark)
    bpy.context.view_layer.objects.active=ob;ob.select_set(True);bpy.ops.object.convert(target='MESH');ob.select_set(False);parts.append(ob)
    for x,y in [(-11,3),(-5,7),(4,7),(11,3),(-10,-6)]:
        box('Roof ventilation shaft',(x,y,13.05),(.8,.8,.8),brick)
        box('Vent cap',(x,y,13.5),(1.05,1.05,.15),concrete)
    # Low-profile felt seams are visible from the map camera.
    for x in range(-13,15,3):box('Roof felt seam',(x,5.5,12.705),(.035,10.5,.015),dark)

# Save editable source before consolidating the game copy by material.
for image in bpy.data.images:
    if image.source=='FILE':image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'dormitory.blend' if stage=='build' else PREVIEW/'blockout.blend'))

if stage=='build':
    bpy.ops.object.select_all(action='DESELECT')
    for ob in parts:ob.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.object.join()
    asset=bpy.context.object;asset.name='Dormitory_30x23m_4storeys'
    asset.data.calc_loop_triangles()
    bpy.ops.export_scene.gltf(filepath=str(OUT/'dormitory.glb'),export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True)
    (PREVIEW/'export-report.json').write_text(json.dumps({'triangles':len(asset.data.loop_triangles),'materials':len(asset.data.materials),'dimensions':list(asset.dimensions),'front':'Blender -Y / Godot +Z'},indent=2))

# Cheap matched silhouette views; no user scene is touched in this background process.
scene.render.engine='BLENDER_WORKBENCH'
scene.display.shading.light='STUDIO';scene.display.shading.color_type='MATERIAL'
scene.display.shading.show_shadows=True;scene.display.shading.show_cavity=True
scene.world=bpy.data.worlds.new('Dormitory preview world')
scene.render.resolution_x=800;scene.render.resolution_y=650;scene.render.resolution_percentage=100
camdata=bpy.data.cameras.new('Review camera');cam=bpy.data.objects.new('Review camera',camdata);scene.collection.objects.link(cam)
scene.camera=cam;camdata.type='ORTHO';camdata.ortho_scale=46
for label,eye in [('front',(38,-47,35)),('rear',(-40,43,32))]:
    cam.location=eye;cam.rotation_euler=(Vector((0,0,6))-cam.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(PREVIEW/(stage+'-'+label+'.png'));bpy.ops.render.render(write_still=True)
print('Dormitory stage complete:',stage)
