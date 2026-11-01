"""Inspect exported GLBs and render matched views; run with MCP start."""
from pathlib import Path
import json
import math
import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parents[2]
OUT = HERE/('finish_v1' if (HERE/'finish_v1/LiAZ_5256.glb').exists() else 'shape_v1')
scene = bpy.data.scenes.get('PublicTransport_Preview')
if scene:
    for o in list(scene.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.data.scenes.remove(scene)
scene = bpy.data.scenes.new('PublicTransport_Preview')
bpy.context.window.scene = scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 16
scene.cycles.device = 'CPU'
scene.render.resolution_x = 1440
scene.render.resolution_y = 960
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.world = bpy.data.worlds.new('Bus review world')
scene.world.use_nodes = True
scene.world.node_tree.nodes['Background'].inputs[0].default_value = (.38,.42,.48,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value = .6


def load(path, x):
    before = set(scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    obs = set(scene.objects)-before
    meshes = [o for o in obs if o.type == 'MESH']
    points = [o.matrix_world @ Vector(v) for o in meshes for v in o.bound_box]
    lo = Vector(tuple(min(v[i] for v in points) for i in range(3)))
    hi = Vector(tuple(max(v[i] for v in points) for i in range(3)))
    tris = sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in meshes)
    for o in obs:
        if o.parent not in obs:
            o.location.x += x
    return list(obs), {'bounds_min':list(lo),'bounds_max':list(hi),
                       'dimensions_xyz_m':list(hi-lo),'triangles':tris,
                       'mesh_objects':len(meshes),
                       'materials':sorted({m.name for o in meshes for m in o.data.materials if m})}


groups, report = {}, {}
for name,x,path in [('LiAZ_5256',-2,OUT/'LiAZ_5256.glb'),
                    ('PAZ_3205',2,OUT/'PAZ_3205.glb'),
                    ('KamAZ',-6,PROJECT/'init/assets/models/vehicles/truck_kamaz_semi.glb'),
                    ('Volga',6,PROJECT/'init/assets/models/vehicles/volga_gaz24.glb')]:
    groups[name],report[name] = load(path,x)
(OUT/'glb_inspection.json').write_text(json.dumps(report,indent=2))

bpy.ops.mesh.primitive_plane_add(size=200)
ground = bpy.context.object
m = bpy.data.materials.new('Review ground')
m.diffuse_color = (.24,.27,.29,1)
ground.data.materials.append(m)
ground.location.z = -.012
# Metric grid across the comparison area.
gridmat = bpy.data.materials.new('One metre grid')
gridmat.diffuse_color = (.36,.39,.40,1)
for direction in (0,1):
    for i in range(-12,13):
        bpy.ops.mesh.primitive_cube_add(size=1,location=(i if direction==0 else 0,
                                                      i if direction==1 else 0,-.004))
        o = bpy.context.object
        o.dimensions = (.012,24,.003) if direction==0 else (24,.012,.003)
        o.data.materials.append(gridmat)

for loc,energy,size in [((5,-8,12),2100,8),((-6,1,8),1500,7)]:
    bpy.ops.object.light_add(type='AREA',location=loc)
    o = bpy.context.object
    o.data.energy,o.data.shape,o.data.size = energy,'DISK',size
    o.rotation_euler = (Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add()
cam = bpy.context.object
scene.camera = cam
cam.data.type = 'ORTHO'


def view(name, location, target, scale, visible):
    for key,obs in groups.items():
        for o in obs:
            o.hide_render = key not in visible
    cam.location = location
    cam.rotation_euler = (Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.ortho_scale = scale
    scene.render.filepath = str(OUT/(name+'.png'))
    bpy.ops.render.render(write_still=True)
    print('Rendered',name,flush=True)


view('buses_front_three_quarter',(16,-21,12),(0,-.1,1.3),17,['LiAZ_5256','PAZ_3205'])
view('liaz_right',(20,0,1.5),(-2,0,1.5),13,['LiAZ_5256'])
view('paz_right',(20,0,1.5),(2,0,1.5),8,['PAZ_3205'])
view('buses_rear_three_quarter',(-16,21,11),(0,0,1.3),17,['LiAZ_5256','PAZ_3205'])
view('fleet_comparison',(23,-28,21),(0,0,1.5),25,list(groups))
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'comparison.blend'))
