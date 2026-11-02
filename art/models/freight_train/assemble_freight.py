"""Save an editable eight-wagon formation from the actual game exports."""
from pathlib import Path
import bpy
import json
import runpy

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
H=runpy.run_path(str(HERE/'build_locomotive.py'),run_name='m62_helpers')
name='Container_Freight_Assembly'
if name in bpy.data.scenes:
    old=bpy.data.scenes[name]
    for o in list(old.objects):bpy.data.objects.remove(o,do_unlink=True)
    bpy.data.scenes.remove(old)
scene=bpy.data.scenes.new(name);bpy.context.window.scene=scene
scene.unit_settings.system='METRIC'
report=json.loads((HERE/'wagon_export_report.json').read_text())
loco_report=json.loads((HERE/'export_report.json').read_text())
factor=report['common_map_factor'];wagon_length=report['length']*factor
loco_length=loco_report['length']*factor;total=report['formation']['length_map_m']
sources=[]
for filename in ['m62_locomotive.glb','container_flat_wagon.glb']:
    before=set(scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(ROOT/'init/assets/models/vehicles'/filename))
    sources.append(next(o for o in set(scene.objects)-before if o.type=='MESH'))
loco,wagon=sources
loco.name='Freight_Locomotive';loco.scale*=factor;loco.location.y=-(total-loco_length)/2
palettes=[]
for color in report['palette']:
    m=bpy.data.materials.new('Container paint '+color);m.use_nodes=True
    p=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value=(*H['helpers'].rgb(color),1)
    p.inputs['Roughness'].default_value=.66;p.inputs['Metallic'].default_value=.1
    palettes.append(m)
slot=next(i for i,m in enumerate(wagon.data.materials) if 'container paint' in m.name.lower())
for i,color in enumerate(report['wagon_palette_indices']):
    obj=wagon if i==0 else wagon.copy()
    if i:scene.collection.objects.link(obj)
    obj.name='Container_Wagon_%02d'%(i+1)
    obj.scale=(factor,factor,factor)
    obj.location.y=-total/2+loco_length+(i+.5)*wagon_length
    obj.material_slots[slot].link='OBJECT';obj.material_slots[slot].material=palettes[color]
    obj['paint_hex']=report['palette'][color];obj.select_set(False)
loco.select_set(False)
H['helpers'].scene=scene;H['helpers'].studio()
for area in bpy.context.screen.areas if bpy.context.screen else []:
    if area.type=='VIEW_3D':
        area.spaces.active.region_3d.view_distance=160
        area.spaces.active.region_3d.view_perspective='ORTHO'
scene['wagon_count']=8
scene['map_length_m']=total
scene['palette']=report['palette']
bpy.data.libraries.write(str(HERE/'freight_train.blend'),{scene},fake_user=True)
print('Freight assembly saved: 1 locomotive, 8 wagons, length',total)
