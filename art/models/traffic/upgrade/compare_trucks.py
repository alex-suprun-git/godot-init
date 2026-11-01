"""Matched old/new geometry review. Old GLBs come from the pre-upgrade git revision.
--before-dir=/absolute/archive; output stays in /tmp/truck-upgrade, outside the repo.
"""
from pathlib import Path
import bpy,sys,math
from mathutils import Vector
HERE=Path(__file__).resolve().parent
archive=Path(next(a.split('=',1)[1] for a in sys.argv if a.startswith('--before-dir=')))
bpy.ops.wm.open_mainfile(filepath=str(HERE/'trucks.blend'))
scene=bpy.data.scenes['Freight_Studio'];bpy.context.window.scene=scene
assets=[scene.objects[n] for n in ['ZIL_Food','ZIL_Coal','KamAZ_Container']]
for o in assets:o.hide_render=True
bpy.ops.mesh.primitive_plane_add(size=60);floor=bpy.context.object;floor.location.z=-.015
mat=bpy.data.materials.new('Grid floor');mat.diffuse_color=(.33,.35,.36,1);floor.data.materials.append(mat)
for i in range(-12,13):
    for cross in [False,True]:
        bpy.ops.mesh.primitive_cube_add(size=1,location=(i,0,0) if cross else (0,i,0));o=bpy.context.object;o.dimensions=(.008,24,.004) if cross else (24,.008,.004)
        m=bpy.data.materials.get('Grid') or bpy.data.materials.new('Grid');m.diffuse_color=(.16,.18,.20,1);o.data.materials.append(m)
bpy.ops.object.camera_add();cam=bpy.context.object;cam.data.type='ORTHO';scene.camera=cam
scene.render.engine='CYCLES';scene.cycles.samples=8;scene.cycles.use_denoising=True
scene.render.resolution_x=1000;scene.render.resolution_y=700;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG'
for index,file in [(1,'old-zil.glb'),(2,'old-kamaz.glb')]:
    new=assets[index];new.location=(0,0,0)
    before=set(scene.objects);bpy.ops.import_scene.gltf(filepath=str(archive/file));old=[o for o in scene.objects if o not in before]
    for view,eye in [('side',(30,0,2.0)),('front',(0,-30,2.0)),('rear',(0,30,2.0)),('three-quarter',(24,-30,19))]:
        target=Vector((0,0,1.5));cam.location=eye;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=19 if index==2 else 9
        for version in ['before','after']:
            new.hide_render=version=='before'
            for o in old:o.hide_render=version=='after'
            scene.render.filepath=f'/tmp/truck-upgrade/{index}-{view}-{version}.png';bpy.ops.render.render(write_still=True)
    new.hide_render=True
    for o in old:bpy.data.objects.remove(o,do_unlink=True)
