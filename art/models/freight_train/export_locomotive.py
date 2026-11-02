"""Export only the locomotive; measure the reimported binary, not build constants."""
from pathlib import Path
import bpy
import json
import struct

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
OUT=ROOT/'init/assets/models/vehicles/m62_locomotive.glb'
scene=bpy.data.scenes.get('M62_Studio')
if scene is None:
    with bpy.data.libraries.load(str(HERE/'locomotive.blend'),link=False) as (src,dst):
        dst.scenes=['M62_Studio']
    scene=dst.scenes[0]
bpy.context.window.scene=scene
bpy.ops.object.select_all(action='DESELECT')
obj=next(o for o in scene.objects if o.name.startswith('M62_Locomotive'))
obj.select_set(True)
bpy.context.view_layer.objects.active=obj
bpy.ops.export_scene.gltf(filepath=str(OUT),export_format='GLB',use_selection=True,
                         use_active_scene=True,export_cameras=False,export_lights=False,
                         export_animations=False)
binary=OUT.read_bytes()
json_length=struct.unpack_from('<I',binary,12)[0]
gltf=json.loads(binary[20:20+json_length])
review=bpy.data.scenes.new('M62 temporary GLB measurement')
bpy.context.window.scene=review
bpy.ops.import_scene.gltf(filepath=str(OUT))
bpy.context.view_layer.update()
meshes=[o for o in review.objects if o.type=='MESH']
points=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
low=[min(v[i] for v in points) for i in range(3)]
high=[max(v[i] for v in points) for i in range(3)]
report={'asset':OUT.relative_to(ROOT).as_posix(),
        'blender_xyz_bounds':{'min':low,'max':high},
        'length':high[1]-low[1],'width':high[0]-low[0],'height':high[2]-low[2],
        'triangles':sum(len(p.vertices)-2 for o in meshes for p in o.data.polygons),
        'mesh_objects':len(meshes),
        'materials':sorted({m.name for o in meshes for m in o.data.materials}),
        'embedded_images':len(gltf.get('images',[])),
        'gltf_meshes':len(gltf.get('meshes',[])),
        'gltf_scenes':len(gltf.get('scenes',[])),
        'gltf_materials':len(gltf.get('materials',[])),
        'common_rail_map_factor':4.3/4.37,
        'budget_triangles':14000,
        'construction_lwh_m':[17.55,2.95,4.493],
        'comparison':'Common ER2 presentation factors; no independent fitting to a platform or car length'}
(HERE/'export_report.json').write_text(json.dumps(report,indent=2)+'\n')
bpy.context.window.scene=scene
for o in list(review.objects):bpy.data.objects.remove(o,do_unlink=True)
bpy.data.scenes.remove(review)
print(json.dumps(report,indent=2))
