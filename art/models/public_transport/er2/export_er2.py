"""Scoped GLB export and re-import measurements of the actual binary game copies."""
from pathlib import Path
import bpy
import json
import math
from mathutils import Vector

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
OUT=ROOT/'init/assets/models/vehicles'
OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(HERE/'er2.blend'))
scene=bpy.data.scenes['ER2_Studio'];bpy.context.window.scene=scene
report={}
for name,filename in [('ER2_Head','er2_head.glb'),('ER2_Motor','er2_motor.glb')]:
    bpy.ops.object.select_all(action='DESELECT')
    obj=scene.objects[name];old=obj.location.copy();obj.location=(0,0,0)
    obj.select_set(True);bpy.context.view_layer.objects.active=obj
    bpy.ops.export_scene.gltf(filepath=str(OUT/filename),export_format='GLB',
                             use_selection=True,use_active_scene=True,export_cameras=False,
                             export_lights=False,export_animations=False)
    obj.location=old
    review=bpy.data.scenes.new('Reimport '+name);bpy.context.window.scene=review
    bpy.ops.import_scene.gltf(filepath=str(OUT/filename))
    bpy.context.view_layer.update()
    meshes=[o for o in review.objects if o.type=='MESH']
    points=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
    low=[min(v[i] for v in points) for i in range(3)]
    high=[max(v[i] for v in points) for i in range(3)]
    materials={m.name for o in meshes for m in o.data.materials}
    triangles=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in meshes)
    report[filename]={'blender_xyz_bounds':{'min':low,'max':high},
                     'length':high[1]-low[1],'width':high[0]-low[0],'height':high[2]-low[2],
                     'triangles':triangles,'mesh_objects':len(meshes),'materials':sorted(materials),
                     'vertex_color_attributes':{o.name:list(o.data.color_attributes.keys()) for o in meshes},
                     'bytes':(OUT/filename).stat().st_size}
    bpy.context.window.scene=scene
    bpy.data.scenes.remove(review)

# Editable assembly uses linked meshes; two outward cabs, motor pantographs towards each head.
formation=bpy.data.scenes.new('ER2_Four_Car_Assembly')
source_head=scene.objects['ER2_Head'];source_motor=scene.objects['ER2_Motor']
spacing=report['er2_head.glb']['length']
for i,(source,flip) in enumerate([(source_head,False),(source_motor,False),(source_motor,True),(source_head,True)]):
    obj=source.copy();obj.data=source.data
    formation.collection.objects.link(obj)
    obj.name=f'ER2 consist {i+1} '+('head' if source==source_head else 'motor')
    obj.location=(0,(i-1.5)*spacing,0);obj.rotation_euler.z=math.pi if flip else 0
    obj.select_set(False)
formation.world=scene.world
report['formation']={'order':['head','motor','motor reversed','head reversed'],
                     'car_spacing':spacing,'length':spacing*4,
                     'common_map_factor':4.3/4.37,'map_length':spacing*4*4.3/4.37,
                     'triangles':2*(report['er2_head.glb']['triangles']+report['er2_motor.glb']['triangles'])}
(HERE/'export_report.json').write_text(json.dumps(report,indent=2)+'\n')
bpy.context.window.scene=scene
bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'er2.blend'))
print(json.dumps(report,indent=2))
