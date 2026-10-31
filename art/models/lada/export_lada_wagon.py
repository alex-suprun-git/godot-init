"""Export a lighter game copy while keeping the Blender source editable."""
from pathlib import Path
import json
import bpy

PROJECT=Path(__file__).resolve().parents[3]
SOURCE=PROJECT/'art/models/lada'
EXPORT=PROJECT/'init/assets/models/vehicles'
scene=bpy.data.scenes['Lada_Studio_Wagon']
bpy.context.window.scene=scene
root=bpy.data.objects['Lada_Wagon']


def select(objects):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]


temp=bpy.data.collections.new('TEMP GLB export')
scene.collection.children.link(temp)
export_root=bpy.data.objects.new('Lada_Wagon',None)
temp.objects.link(export_root)
depsgraph=bpy.context.evaluated_depsgraph_get()
groups={}
for obj in list(root.children_recursive):
    if obj.type not in {'MESH','FONT','CURVE'}:
        continue
    data=bpy.data.meshes.new_from_object(obj.evaluated_get(depsgraph),
                                        preserve_all_data_layers=True,depsgraph=depsgraph)
    copy=bpy.data.objects.new(obj.name+' export',data)
    temp.objects.link(copy)
    copy.matrix_world=obj.matrix_world.copy()
    group=obj.parent.name if obj.parent and obj.parent.name.startswith('Wheel_') else 'Body'
    groups.setdefault(group,[]).append(copy)
export_meshes=[]
counts={}
for name,objects in groups.items():
    select(objects)
    bpy.ops.object.join()
    obj=bpy.context.object
    obj.name=name
    obj.parent=export_root
    decimate=obj.modifiers.new('Game geometry reduction','DECIMATE')
    decimate.ratio=.32
    decimate.use_collapse_triangulate=True
    bpy.ops.object.modifier_apply(modifier=decimate.name)
    obj.data.calc_loop_triangles()
    counts[name]=len(obj.data.loop_triangles)
    export_meshes.append(obj)
select([export_root]+export_meshes)
bpy.ops.export_scene.gltf(filepath=str(EXPORT/'lada_wagon.glb'),export_format='GLB',
                          use_selection=True,use_active_scene=True,export_apply=True,export_yup=True,
                          export_animations=False,export_cameras=False,export_lights=False)
report={'model':'Lada Wagon','triangles':sum(counts.values()),'triangles_by_mesh':counts,
        'meshes':len(export_meshes),'paint_atlas':'2048 x 2048',
        'source':'lada_wagon.blend','export':'init/assets/models/vehicles/lada_wagon.glb',
        'front_axis_blender':'-Y','front_axis_godot':'+Z',
        'notes':'Procedural geometry and baked paint based on car_lada_v3.png. No external model assets. Original detail retained in Blender.'}
(SOURCE/'asset_report_wagon.json').write_text(json.dumps(report,indent=2)+'\n')
for obj in list(temp.objects):
    bpy.data.objects.remove(obj,do_unlink=True)
bpy.data.collections.remove(temp)
select([root])
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'lada_wagon.blend'))
print(json.dumps(report))
