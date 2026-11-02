"""Render the authored wagon using neutral studio lighting; outputs are local only."""
from pathlib import Path
import bpy
import math
import sys
from mathutils import Vector

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
blockout='--blockout' in sys.argv
name='Container_Wagon_Studio'+('_Blockout' if blockout else '')
with bpy.data.libraries.load(str(HERE/('wagon_blockout.blend' if blockout else 'container_wagon.blend')),link=False) as (src,dst):
    dst.scenes=[name]
scene=dst.scenes[0];bpy.context.window.scene=scene
scene.render.engine='CYCLES';scene.cycles.samples=8;scene.cycles.use_denoising=True
scene.render.resolution_x=1200;scene.render.resolution_y=700;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.world.color=(.3,.3,.3)
cam_data=bpy.data.cameras.new('Wagon review camera');cam_data.type='ORTHO';cam_data.ortho_scale=18
cam=bpy.data.objects.new('Wagon review camera',cam_data);scene.collection.objects.link(cam);scene.camera=cam
cam.location=(16,-19,13)
cam.rotation_euler=(Vector((0,0,1.8))-cam.location).to_track_quat('-Z','Y').to_euler()
out=ROOT/'.local/freight-train';out.mkdir(parents=True,exist_ok=True)
scene.render.filepath=str(out/('wagon-blockout.png' if blockout else 'wagon-neutral.png'))
bpy.ops.render.render(write_still=True)
