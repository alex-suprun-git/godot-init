"""Export exactly one truck per GLB; measure actual reimported game binaries."""
from pathlib import Path
import bpy,json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
OUT=ROOT/'init/assets/models/vehicles'
bpy.ops.wm.open_mainfile(filepath=str(HERE/'trucks.blend'))
scene=bpy.data.scenes['Freight_Studio'];bpy.context.window.scene=scene
report={}
for name,file in [('ZIL_Food','truck_zil_food.glb'),('ZIL_Coal','truck_zil_flatbed.glb'),('KamAZ_Container','truck_kamaz_semi.glb')]:
    bpy.ops.object.select_all(action='DESELECT');o=scene.objects[name];old=o.location.copy();o.location=(0,0,0);o.select_set(True);bpy.context.view_layer.objects.active=o
    bpy.ops.export_scene.gltf(filepath=str(OUT/file),export_format='GLB',use_selection=True,use_active_scene=True,export_cameras=False,export_lights=False,export_animations=False)
    o.location=old
    review=bpy.data.scenes.new('Inspect '+name);bpy.context.window.scene=review
    bpy.ops.import_scene.gltf(filepath=str(OUT/file));bpy.context.view_layer.update()
    meshes=[o for o in review.objects if o.type=='MESH'];ps=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
    lo=[min(v[i] for v in ps) for i in range(3)];hi=[max(v[i] for v in ps) for i in range(3)]
    report[file]={'min':lo,'max':hi,'length':hi[1]-lo[1],'width':hi[0]-lo[0],'height':hi[2]-lo[2],'triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in meshes),'mesh_objects':len(meshes),'materials':sorted({m.name for o in meshes for m in o.data.materials})}
    bpy.context.window.scene=scene;bpy.data.scenes.remove(review)
(HERE/'export_report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
