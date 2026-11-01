"""Detail a separate game copy from the existing shape scene; no rebuild or bake."""
from pathlib import Path
import math
import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
OUT = HERE/'finish_v1'
OUT.mkdir(exist_ok=True)
source = bpy.data.scenes.get('PublicTransport_Shape')
if source is None:
    raise RuntimeError('Open shape_v1/buses.blend or run build_buses.py first')
old = bpy.data.scenes.get('PublicTransport_Finish')
if old:
    for o in list(old.objects):
        bpy.data.objects.remove(o,do_unlink=True)
    bpy.data.scenes.remove(old)
scene = bpy.data.scenes.new('PublicTransport_Finish')
bpy.context.window.scene = scene


def box(root,name,pos,size,mat):
    bpy.ops.mesh.primitive_cube_add(size=1,location=pos)
    o = bpy.context.object
    o.name = name
    o.dimensions = size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.parent = root
    o.data.materials.append(mat)
    return o


def rod(root,name,a,b,radius,mat):
    a,b = Vector(a),Vector(b)
    bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=radius,depth=(b-a).length,location=(a+b)/2)
    o = bpy.context.object
    o.name = name
    o.rotation_euler = (b-a).to_track_quat('Z','Y').to_euler()
    o.parent = root
    o.data.materials.append(mat)


roots = []
for original in list(source.objects):
    if original.parent is not None or 'body_dimensions_m' not in original:
        continue
    root = original.copy()
    scene.collection.objects.link(root)
    root.location = (0,0,0)
    roots.append(root)
    for child in original.children:
        o = child.copy()
        o.data = child.data.copy()
        scene.collection.objects.link(o)
        o.parent = root
    length,width,height = root['body_dimensions_m']
    mats = {m.name.split('.')[0]:m for o in root.children for m in o.data.materials if m}
    rubber = mats['Bus - rubber']
    steel = mats['Bus - wheel steel']
    small = 'PAZ' in original.name
    # Wipers remain outside the opaque front glazing and follow its actual plane.
    for side in (-1,1):
        rod(root,'Wiper arm',(side*.59,-length/2-.025,1.66),
            (side*.36,-length/2-.030,2.04),.013,rubber)
        rod(root,'Wiper blade',(side*.52,-length/2-.034,1.83),
            (side*.23,-length/2-.034,2.27),.018,rubber)
        box(root,'Rain gutter',(side*1.253,0,height-.235),(.025,length-.43,.025),steel)
        box(root,'Waist protection strip',(side*1.262,0,1.29),(.018,length-.40,.023),rubber)
    # Driver door and body-access seams, kept shallow for the intended map scale.
    for y in ([-3.12,-2.08] if small else [-5.37,-4.10]):
        box(root,'Driver door seam',(-1.263,y,1.18),(.012,.014,.65),rubber)
    box(root,'Driver door handle',(-1.277,-2.21 if small else -4.22,1.45),(.018,.15,.025),steel)
    if small:
        # A separate rear emergency exit; never a second folding passenger door.
        for y in (2.28,3.10):
            box(root,'Emergency exit seam',(1.264,y,1.19),(.012,.015,.66),rubber)
        box(root,'Emergency exit lower seam',(1.264,2.69,.86),(.012,.82,.014),rubber)
        box(root,'Emergency exit handle',(1.278,2.39,1.44),(.018,.14,.025),steel)
        for j in range(7):
            box(root,'Front engine side vent',(1.268,-2.65+j*.075,1.30),(.015,.023,.22),rubber)
    else:
        for side in (-1,1):
            for j in range(7):
                box(root,'Rear engine side vent',(side*1.268,4.43+j*.12,1.36),(.014,.07,.16),rubber)
    box(root,'Rear number plate',(0,length/2+.025,.69),(.46,.012,.12),steel)
    root['stage'] = 'Detail v1; pending user visual review'
    # Select only the new asset. Join its game copy; keep shape source untouched.
    bpy.ops.object.select_all(action='DESELECT')
    children = [o for o in root.children if o.type=='MESH']
    for o in children:
        o.select_set(True)
    bpy.context.view_layer.objects.active = children[0]
    bpy.ops.object.join()
    mesh = bpy.context.object
    # Merge identical vertices along joined parts without simplifying silhouettes.
    mesh.name = ('PAZ_3205' if small else 'LiAZ_5256')+'_game'
    root.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/('PAZ_3205.glb' if small else 'LiAZ_5256.glb')),
                              export_format='GLB',use_selection=True,use_active_scene=True)
for i,root in enumerate(roots):
    root.location.x = -2.2 if i==0 else 2.2
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'buses.blend'))
print('Saved detail stage',OUT)
