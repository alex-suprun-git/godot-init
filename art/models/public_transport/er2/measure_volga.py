"""Measure the actual reference GLB in Blender, independent of source constants."""
import bpy
import json
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[4]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(ROOT / 'init/assets/models/vehicles/volga_gaz24.glb'))
bpy.context.view_layer.update()
verts = [o.matrix_world @ v.co for o in bpy.context.scene.objects if o.type == 'MESH' for v in o.data.vertices]
lo = [min(v[i] for v in verts) for i in range(3)]
hi = [max(v[i] for v in verts) for i in range(3)]
box = [hi[i] - lo[i] for i in range(3)]
report = {'reference': 'init/assets/models/vehicles/volga_gaz24.glb',
          'blender_xyz_bounds': {'min': lo, 'max': hi},
          'length': box[1], 'width': box[0], 'height': box[2],
          'real_volga_reference_lwh': [4.735, 1.8, 1.49],
          'train_lwh_factors': [box[1] / 4.735, box[0] / 1.8, box[2] / 1.49],
          'common_map_factor': 4.3 / 4.37,
          'materials': [m.name for m in bpy.data.materials]}
(Path(__file__).parent / 'volga_measurements.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
