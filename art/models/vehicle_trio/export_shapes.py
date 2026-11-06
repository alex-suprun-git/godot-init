"""Separate scoped export, modifier evaluation and measured GLB inspection."""
from pathlib import Path
import runpy
import json
import bpy
import sys
from mathutils import Vector

HERE=Path(__file__).resolve().parent
inspect_glb=runpy.run_path(str(HERE.parent/'uaz_service/export_vehicle.py'))['inspect_glb']
out=HERE/'exports';out.mkdir(exist_ok=True)
reports=[]
only=next((arg.split('=',1)[1] for arg in sys.argv if arg.startswith('--only=')),None)
existing=json.loads((HERE/'glb_inspection.json').read_text()) if (HERE/'glb_inspection.json').exists() else []
for key in ['luxury_suv','luxury_sedan','rural_4x4']:
    if only and key!=only:
        reports.extend(r for r in existing if r['file']==key+'.glb')
        continue
    scene=bpy.data.scenes[key];bpy.context.window.scene=scene
    bpy.ops.object.select_all(action='DESELECT')
    deps=bpy.context.evaluated_depsgraph_get();copies=[]
    for obj in list(scene.objects):
        if obj.type not in ['MESH','CURVE']:continue
        data=bpy.data.meshes.new_from_object(obj.evaluated_get(deps),depsgraph=deps)
        cp=bpy.data.objects.new(obj.name+' export',data);scene.collection.objects.link(cp);cp.matrix_world=obj.matrix_world.copy();copies.append(cp)
    for obj in copies:obj.select_set(True)
    bpy.context.view_layer.objects.active=copies[0];bpy.ops.object.join()
    obj=bpy.context.object;obj.name=key+' shape study'
    points=[obj.matrix_world@v.co for v in obj.data.vertices]
    low=Vector([min(p[i] for p in points) for i in range(3)])
    high=Vector([max(p[i] for p in points) for i in range(3)])
    obj.location-=Vector(((low.x+high.x)/2,(low.y+high.y)/2,low.z))
    path=out/(key+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,use_active_scene=True,
        export_apply=True,export_yup=True,export_animations=False,export_cameras=False,export_lights=False)
    report=inspect_glb(path);report['stage']=bpy.data.objects[key].get('stage','shape study')
    report['wheelbase_m']=bpy.data.objects[key]['wheelbase_m'];reports.append(report)
    bpy.data.objects.remove(obj,do_unlink=True)
(HERE/'glb_inspection.json').write_text(json.dumps(reports,indent=2)+'\n')
print(json.dumps(reports,indent=2))
