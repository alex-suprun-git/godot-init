"""Bake a portable paint texture, export the asset, and queue a studio render."""
from pathlib import Path
import json
import math
import traceback
import bpy

PROJECT = Path(__file__).resolve().parents[3]
SOURCE = PROJECT / 'art/models/lada'
EXPORT = PROJECT / 'init/assets/models/vehicles'
scene = bpy.data.scenes['Lada_Studio_Wagon']
bpy.context.window.scene = scene
root = bpy.data.objects['Lada_Wagon']
asset_collection = root.users_collection[0]
body = bpy.data.objects['Wagon body shell']
paint = body.data.materials[0]


def linear(hex_color):
    values = [int(hex_color[i:i+2], 16) / 255 for i in (0,2,4)]
    return tuple(c/12.92 if c<.04045 else ((c+.055)/1.055)**2.4 for c in values)


def select(objects):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]


paint_meshes = [obj for obj in root.children_recursive if obj.type=='MESH' and paint in obj.data.materials[:]]
for obj in paint_meshes:
    select([obj])
    for mod in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=mod.name)
select(paint_meshes)
bpy.ops.object.join()
paint_mesh = bpy.context.object
paint_mesh.name = 'Ivory bodywork - baked paint'
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=.012)
bpy.ops.object.mode_set(mode='OBJECT')

nodes=paint.node_tree.nodes
links=paint.node_tree.links
shader=nodes.get('Principled BSDF')
output=nodes.get('Material Output')
coords=nodes.new('ShaderNodeTexCoord')
noise=nodes.new('ShaderNodeTexNoise')
noise.inputs['Scale'].default_value=115
noise.inputs['Detail'].default_value=3
links.new(coords.outputs['Generated'],noise.inputs['Vector'])
base=nodes.new('ShaderNodeValToRGB')
base.color_ramp.elements[0].position=.15
base.color_ramp.elements[0].color=(*linear('C3C5B7'),1)
base.color_ramp.elements[1].position=.85
base.color_ramp.elements[1].color=(*linear('DADACD'),1)
links.new(noise.outputs['Fac'],base.inputs['Fac'])
separate=nodes.new('ShaderNodeSeparateXYZ')
links.new(coords.outputs['Generated'],separate.inputs[0])
low=nodes.new('ShaderNodeMapRange')
low.clamp=True
low.inputs['From Min'].default_value=0
low.inputs['From Max'].default_value=.14
low.inputs['To Min'].default_value=1
low.inputs['To Max'].default_value=0
links.new(separate.outputs['Z'],low.inputs['Value'])
rust_noise=nodes.new('ShaderNodeTexNoise')
rust_noise.inputs['Scale'].default_value=64
rust_noise.inputs['Detail'].default_value=4
links.new(coords.outputs['Generated'],rust_noise.inputs['Vector'])
patches=nodes.new('ShaderNodeValToRGB')
patches.color_ramp.elements[0].position=.48
patches.color_ramp.elements[1].position=.66
links.new(rust_noise.outputs['Fac'],patches.inputs[0])
mask=nodes.new('ShaderNodeMath')
mask.operation='MULTIPLY'
links.new(low.outputs['Result'],mask.inputs[0])
links.new(patches.outputs['Color'],mask.inputs[1])
mix=nodes.new('ShaderNodeMixRGB')
mix.blend_type='MIX'
mix.inputs[2].default_value=(*linear('76624D'),1)
links.new(mask.outputs[0],mix.inputs[0])
links.new(base.outputs['Color'],mix.inputs[1])

# The exported GLB uses this baked image, not Blender-only procedural nodes.
image=bpy.data.images.new('Lada wagon paint atlas',width=2048,height=2048,alpha=False)
image.colorspace_settings.name='sRGB'
target=nodes.new('ShaderNodeTexImage')
target.image=image
nodes.active=target
emission=nodes.new('ShaderNodeEmission')
links.new(mix.outputs[0],emission.inputs['Color'])
links.new(emission.outputs[0],output.inputs['Surface'])
select([paint_mesh])
scene.render.engine='CYCLES'
scene.cycles.samples=1
try:
    bpy.ops.object.bake(type='EMIT',margin=10)
except RuntimeError:
    scene.cycles.device='CPU'
    bpy.ops.object.bake(type='EMIT',margin=10)
links.new(shader.outputs['BSDF'],output.inputs['Surface'])
links.new(target.outputs['Color'],shader.inputs['Base Color'])
nodes.remove(emission)
image.filepath_raw=str(EXPORT/'lada_wagon_paint.png')
image.file_format='PNG'
image.save()
image.pack()
scene.cycles.samples=48

exec(compile((SOURCE/'export_lada_wagon.py').read_text(), str(SOURCE/'export_lada_wagon.py'), 'exec'))


def render_preview():
    status=SOURCE/'render_status_wagon.json'
    try:
        status.write_text(json.dumps({'status':'rendering'}))
        scene.render.filepath=str(SOURCE/'previews/lada_wagon_front.png')
        bpy.ops.render.render(write_still=True,scene=scene.name)
        status.write_text(json.dumps({'status':'complete','image':scene.render.filepath}))
    except Exception:
        status.write_text(json.dumps({'status':'error','traceback':traceback.format_exc()}))
    return None


bpy.app.timers.register(render_preview,first_interval=.5)
print('Studio preview render queued.')
