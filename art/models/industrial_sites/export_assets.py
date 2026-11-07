"""Explicit collection-only GLB export. Resumable independently of modeling."""
from pathlib import Path
import json
import struct
import argparse
import sys
import bpy

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
OUT=ROOT/'init/assets/models/industrial_sites'
OUT.mkdir(parents=True,exist_ok=True)
SHARED_MATERIALS=ROOT/'init/assets/materials/frontier'

def strip_shared_textures(path):
    """Frontier models share their textured materials (init/assets/materials/frontier).
    Remove the per-model embedded textures; shared_material_import.gd restores them by name."""
    import importlib.util
    spec=importlib.util.spec_from_file_location('strip_glb_textures',ROOT/'tools/strip_glb_textures.py')
    module=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    document,binary=module.read_glb(path)
    document,binary,_=module.strip(document,binary,SHARED_MATERIALS)
    module.write_glb(path,document,binary)

parser=argparse.ArgumentParser()
parser.add_argument('--source',type=Path)
parser.add_argument('--asset')
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
refined=HERE/'atp/atp.blend'
yard=HERE/'atp/yard.blend'
frontier=HERE/'frontier/frontier.blend'
sources=[args.source.resolve()] if args.source else [HERE/'industrial_sites.blend']+([refined] if refined.exists() else [])+([yard] if yard.exists() else [])+([frontier] if frontier.exists() else [])
reports=[]
for source in sources:
    bpy.ops.wm.open_mainfile(filepath=str(source))
    scene=bpy.context.scene
    for collection in scene.collection.children:
        if not collection.name.startswith('asset_'):
            continue
        name=collection.name.removeprefix('asset_')
        if args.asset and name!=args.asset:
            continue
        if not args.source and source!=refined and refined.exists() and name=='atp_hall':
            continue
        bpy.ops.object.select_all(action='DESELECT')
        for obj in collection.all_objects:
            obj.hide_set(False)
            obj.select_set(True)
        path=OUT/(name+'.glb')
        bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',
            use_selection=True,use_active_scene=True,export_yup=True,export_apply=True,
            export_materials='EXPORT')
        if name.startswith('frontier_'):
            strip_shared_textures(path)
        data=path.read_bytes()
        size,kind=struct.unpack_from('<II',data,12)
        document=json.loads(data[20:20+size])
        if len(document.get('scenes',[]))!=1 or len(document.get('meshes',[]))!=1:
            raise RuntimeError('Unexpected export contents: '+name)
        triangles=sum(len(o.data.loop_triangles) for o in collection.all_objects if o.type=='MESH')
        reports.append({'asset':name,'path':path.relative_to(ROOT).as_posix(),
            'source':source.relative_to(ROOT).as_posix(),
            'scenes':len(document['scenes']),'meshes':len(document['meshes']),
            'triangles':triangles,'materials':len(document.get('materials',[])),
            'embedded_images':len(document.get('images',[]))})
        print('EXPORTED',name,flush=True)
report_dir=args.source.resolve().parent if args.source else HERE
report_name='yard_export_report.json' if args.source and args.source.stem=='yard' else 'export_report.json'
(report_dir/report_name).write_text(json.dumps(reports,indent=2),encoding='utf-8')
if args.source and (HERE/'export_report.json').exists():
    combined=json.loads((HERE/'export_report.json').read_text(encoding='utf-8'))
    replacements={item['asset']:item for item in reports}
    combined=[replacements.pop(item['asset'],item) for item in combined]
    combined.extend(replacements.values())
    (HERE/'export_report.json').write_text(json.dumps(combined,indent=2),encoding='utf-8')
print('INDUSTRIAL_EXPORT_COMPLETE',flush=True)
