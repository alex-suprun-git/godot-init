"""Build a live Blender comparison from actual GLBs at their Godot presentation scales."""
from pathlib import Path
import bpy
from mathutils import Vector

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
NAME='M62_ER2_Comparison'
if NAME in bpy.data.scenes:
    old=bpy.data.scenes[NAME]
    for o in list(old.objects):bpy.data.objects.remove(o,do_unlink=True)
    bpy.data.scenes.remove(old)
scene=bpy.data.scenes.new(NAME)
bpy.context.window.scene=scene
scene.unit_settings.system='METRIC'
scene.world=bpy.data.scenes['M62_Studio'].world
for obj in bpy.data.scenes['M62_Studio'].objects:
    if obj.type=='LIGHT':scene.collection.objects.link(obj.copy())
factor=4.3/4.37
for filename,x,y,scale in [('m62_locomotive.glb',-3.5,0,factor),
                          ('er2_head.glb',3.5,0,factor),
                          ('er2_motor.glb',10.5,0,factor),
                          ('truck_kamaz_semi.glb',-10.5,3,factor*.80),
                          ('volga_gaz24.glb',-10.5,-7,factor)]:
    before=set(scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(ROOT/'init/assets/models/vehicles'/filename))
    imported=set(scene.objects)-before
    for o in imported:
        if o.parent not in imported:
            o.scale*=scale
            o.location+=Vector((x,y,0))
        o.select_set(False)
for area in bpy.context.screen.areas:
    if area.type=='VIEW_3D':
        space=area.spaces.active
        space.shading.type='MATERIAL'
        space.region_3d.view_location=(0,0,2)
        space.region_3d.view_distance=37
        space.region_3d.view_rotation=Vector((1,-1,.82)).to_track_quat('Z','Y')
        space.region_3d.view_perspective='ORTHO'
out=ROOT/'.local/freight-train/comparison.blend'
out.parent.mkdir(parents=True,exist_ok=True)
bpy.data.libraries.write(str(out),{scene},fake_user=True)
print('Live comparison ready:',NAME,'; optional saved copy:',out)
