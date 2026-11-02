"""Scoped wagon export, with measurements from the reimported GLB."""
from pathlib import Path
import json
import struct
import bpy

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
OUT=ROOT/'init/assets/models/vehicles/container_flat_wagon.glb'
scene=bpy.data.scenes.get('Container_Wagon_Studio')
if scene is None:
    with bpy.data.libraries.load(str(HERE/'container_wagon.blend'),link=False) as (src,dst):
        dst.scenes=['Container_Wagon_Studio']
    scene=dst.scenes[0]
bpy.context.window.scene=scene
bpy.ops.object.select_all(action='DESELECT')
obj=next(o for o in scene.objects if o.name.startswith('Container_Flat_Wagon'))
obj.select_set(True);bpy.context.view_layer.objects.active=obj
bpy.ops.export_scene.gltf(filepath=str(OUT),export_format='GLB',use_selection=True,
                         use_active_scene=True,export_cameras=False,export_lights=False,export_animations=False)
binary=OUT.read_bytes();size=struct.unpack_from('<I',binary,12)[0]
gltf=json.loads(binary[20:20+size])
review=bpy.data.scenes.new('Wagon binary measurement');bpy.context.window.scene=review
bpy.ops.import_scene.gltf(filepath=str(OUT));bpy.context.view_layer.update()
meshes=[o for o in review.objects if o.type=='MESH']
points=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
low=[min(v[i] for v in points) for i in range(3)];high=[max(v[i] for v in points) for i in range(3)]
triangles=sum(len(p.vertices)-2 for o in meshes for p in o.data.polygons)
report={'asset':OUT.relative_to(ROOT).as_posix(),'blender_xyz_bounds':{'min':low,'max':high},
        'length':high[1]-low[1],'width':high[0]-low[0],'height':high[2]-low[2],
        'triangles':triangles,'budget_triangles':5500,'mesh_objects':len(meshes),
        'gltf_meshes':len(gltf.get('meshes',[])),'gltf_materials':len(gltf.get('materials',[])),
        'embedded_images':len(gltf.get('images',[])),
        'nominal_container_lwh_m':[12.192,2.438,2.591],
        'common_map_factor':4.3/4.37,
        'palette':['985a49','526c7b','6b7450'],
        'wagon_palette_indices':[0,1,2,0,2,1,0,1]}
map_factor=4.3/4.37
loco=json.loads((HERE/'export_report.json').read_text())
report['formation']={'wagons':8,'length_map_m':(loco['length']+8*report['length'])*map_factor,
                     'triangles':loco['triangles']+8*triangles}
(HERE/'wagon_export_report.json').write_text(json.dumps(report,indent=2)+'\n')
bpy.context.window.scene=scene
for o in list(review.objects):bpy.data.objects.remove(o,do_unlink=True)
bpy.data.scenes.remove(review)
print(json.dumps(report,indent=2))
