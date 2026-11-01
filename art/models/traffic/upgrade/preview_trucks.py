"""Multi-angle review in common units, never exports studio objects."""
from pathlib import Path
import bpy, math, sys
from mathutils import Vector
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
block='--blockout' in sys.argv
bpy.ops.wm.open_mainfile(filepath=str(HERE/('trucks_blockout.blend' if block else 'trucks.blend')))
scene=bpy.data.scenes['Freight_Blockout' if block else 'Freight_Studio'];bpy.context.window.scene=scene
scene.render.engine='CYCLES';scene.cycles.samples=8;scene.cycles.use_denoising=True
scene.render.resolution_x=1500;scene.render.resolution_y=850;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='AgX'
bpy.ops.mesh.primitive_plane_add(size=80);floor=bpy.context.object;floor.location.z=-.015
m=bpy.data.materials.new('Neutral floor');m.diffuse_color=(.29,.32,.33,1);floor.data.materials.append(m)
bpy.ops.object.camera_add();cam=bpy.context.object;cam.data.type='ORTHO';scene.camera=cam
# Sources are identical in scale. Individual views let the shorter trucks fill the frame.
out=Path('/tmp/truck-upgrade');out.mkdir(exist_ok=True)
assets=[scene.objects[n] for n in ['ZIL_Food','ZIL_Coal','KamAZ_Container']]
for name,eye,target,scale in [('family',(25,-32,24),(1,0,1.5),23),('side',(35,0,3),(5,0,1.7),20),('front',(0,-35,7),(0,-1,1.4),15),('rear',(23,28,13),(0,0,1.5),23)]:
    cam.location=eye;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale
    scene.render.filepath=str(out/(('blockout-' if block else '')+name+'.png'));bpy.ops.render.render(write_still=True)
