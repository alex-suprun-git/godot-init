"""Matched, metre-calibrated Blender views of the ER2 game variant and real game Volga."""
import bpy
import math
import sys
from pathlib import Path
from mathutils import Vector

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
BLOCKOUT='--blockout' in sys.argv
bpy.ops.wm.open_mainfile(filepath=str(HERE/('er2_blockout.blend' if BLOCKOUT else 'er2.blend')))
scene=bpy.data.scenes.get('ER2_Blockout' if BLOCKOUT else 'ER2_Studio')
bpy.context.window.scene=scene
head=scene.objects['ER2_Head']
motor=scene.objects['ER2_Motor']
motor.hide_render=True
before=set(scene.objects)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'init/assets/models/vehicles/volga_gaz24.glb'))
car=[o for o in scene.objects if o not in before]
for o in car:
    if not o.parent or o.parent not in car:
        o.location += Vector((5, -7.65, 0))
scene.render.engine='CYCLES'
scene.cycles.samples=12
scene.cycles.use_denoising=True
scene.render.resolution_x=1400
scene.render.resolution_y=800
scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.view_settings.view_transform='AgX'
plane=bpy.data.meshes.new('review ground')
plane.from_pydata([(-40,-40,-.015),(40,-40,-.015),(40,40,-.015),(-40,40,-.015)],[],[(0,1,2,3)])
floor=bpy.data.objects.new('review ground',plane);scene.collection.objects.link(floor)
m=bpy.data.materials.new('review neutral floor');m.diffuse_color=(.32,.34,.35,1);m.use_nodes=True
p=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED');p.inputs['Base Color'].default_value=(.32,.34,.35,1);p.inputs['Roughness'].default_value=1
plane.materials.append(m)
# Thin real one-metre grid, comparable across all variants.
grid=bpy.data.materials.new('review grid');grid.diffuse_color=(.16,.18,.20,1)
for i in range(-13,14):
    for along_x in [True,False]:
        bpy.ops.mesh.primitive_cube_add(size=1,location=(0,i,0) if along_x else (i,0,0))
        o=bpy.context.object;o.name='one metre grid';o.dimensions=(26,.009,.005) if along_x else (.009,26,.005)
        o.data.materials.append(grid)
cam_data=bpy.data.cameras.new('review camera');cam_data.type='ORTHO'
cam=bpy.data.objects.new('review camera',cam_data);scene.collection.objects.link(cam);scene.camera=cam
out=HERE/'previews';out.mkdir(exist_ok=True)
prefix='blockout-' if BLOCKOUT else ''
for name,eye,target,scale in [
    ('side',(34,0,3.0),(0,0,2.15),25),
    ('front',(3,-26,4.2),(2.1,-7.8,2.2),10.6),
    ('three-quarter',(24,-27,20),(1.5,-.8,1.8),27),
    ('rear',(22,24,14),(1.2,1.8,1.7),27),
]:
    cam.location=eye;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler()
    cam_data.ortho_scale=scale
    scene.render.filepath=str(out/(prefix+name+'.png'))
    bpy.ops.render.render(write_still=True)
    print('ER2 preview:',name,flush=True)
