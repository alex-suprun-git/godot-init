"""Separate portable export stage; three materials and an embedded palette."""
from pathlib import Path
import json
import struct
import bpy
from mathutils import Vector

HERE=Path(__file__).resolve().parent
PRESENTATION_SCALE=0.85 * 0.95 * 1.03  # User requested 3% growth of all three variants.
bpy.ops.wm.open_mainfile(filepath=str(HERE/'gazelle_2705.blend'))
scene=bpy.data.scenes['GAZ_2705'];bpy.context.window.scene=scene
root=scene.objects['GAZ_2705']
deps=bpy.context.evaluated_depsgraph_get()
palette=[];pieces=[]
for obj in root.children:
    if obj.type!='MESH':continue
    data=bpy.data.meshes.new_from_object(obj.evaluated_get(deps),preserve_all_data_layers=True,depsgraph=deps)
    colors=data.color_attributes['Color']
    for c in colors.data:
        rgb=tuple(round(v,5) for v in c.color[:3])
        if rgb not in palette:palette.append(rgb)
    pieces.append((obj,data))
assert len(palette)<=64
def srgb(c):return c*12.92 if c<=.0031308 else 1.055*c**(1/2.4)-.055
atlas=bpy.data.images.new('Gazelle portable palette',width=64,height=64,alpha=False)
pixels=[]
for y in range(64):
    for x in range(64):
        index=y//8*8+x//8
        c=palette[index] if index<len(palette) else palette[0]
        pixels.extend((*[srgb(v) for v in c],1))
atlas.pixels.foreach_set(pixels);atlas.pack()
materials=[]
for name in ['paint','glass','fittings']:
    mat=bpy.data.materials['Gazelle '+name].copy();mat.name='Gazelle '+name+' portable'
    bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    for link in list(bs.inputs['Base Color'].links):mat.node_tree.links.remove(link)
    tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=atlas;tex.interpolation='Closest'
    mat.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color']);materials.append(mat)
verts=[];faces=[];uvs=[];indices=[];smooth=[]
for obj,data in pieces:
    offset=len(verts);verts.extend(obj.matrix_world@v.co for v in data.vertices)
    mi=['paint','glass','fittings'].index(obj.data.materials[0].name.split()[-1])
    for p in data.polygons:
        faces.append(tuple(offset+v for v in p.vertices));indices.append(mi);smooth.append(p.use_smooth)
        for li in p.loop_indices:
            rgb=tuple(round(v,5) for v in data.color_attributes['Color'].data[li].color[:3])
            i=palette.index(rgb);uvs.append(((i%8+.5)/8,(i//8+.5)/8))
data=bpy.data.meshes.new('Gazelle merged game geometry');data.from_pydata(verts,[],faces);data.update()
for mat in materials:data.materials.append(mat)
for p,mi,s in zip(data.polygons,indices,smooth):p.material_index=mi;p.use_smooth=s
layer=data.uv_layers.new(name='PaletteUV')
for loop,uv in zip(layer.data,uvs):loop.uv=uv
export_scene=bpy.data.scenes.new('Gazelle_export_only');bpy.context.window.scene=export_scene
game=bpy.data.objects.new('GAZ_2705',data);export_scene.collection.objects.link(game)
game.scale=(PRESENTATION_SCALE,)*3
game.select_set(True);bpy.context.view_layer.objects.active=game
path=HERE/'gazelle_2705.glb'
bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,use_active_scene=True,export_materials='EXPORT',export_cameras=False,export_lights=False)
raw=path.read_bytes();n=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+n])
report={'file':path.name,'scenes':len(doc['scenes']),'meshes':len(doc['meshes']),
        'triangles':sum(doc['accessors'][p['indices']]['count']//3 for m in doc['meshes'] for p in m['primitives']),
        'materials':[m['name'] for m in doc['materials']],'images':len(doc.get('images',[])),
        'embedded_images':all('bufferView' in i for i in doc.get('images',[])),
        'forward':'Godot +Z','source_dimensions_xyz':[max(v[i] for v in verts)-min(v[i] for v in verts) for i in range(3)],
        'wheelbase_m':2.9,'ground_z':min(v.z for v in verts),'presentation_scale':PRESENTATION_SCALE}
# Measure the actual binary after a fresh import, including exported transforms.
verify=bpy.data.scenes.new('Gazelle_roundtrip_inspection');bpy.context.window.scene=verify
bpy.ops.import_scene.gltf(filepath=str(path))
points=[o.matrix_world@v.co for o in verify.objects if o.type=='MESH' for v in o.data.vertices]
# Blender imports glTF back into Z-up; report the equivalent Godot Y-up axes.
report['glb_dimensions_godot_xyz_m']=[max(p[i] for p in points)-min(p[i] for p in points) for i in [0,2,1]]
report['glb_ground_y_m']=min(p.z for p in points)
(HERE/'glb_inspection.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))

# Reuse identical geometry for the two requested paint variants. Recolour the
# paint/panel palette entries only; glass, rubber, lamps and steel stay intact.
def linear_hex(value):
    values=[int(value[i:i+2],16)/255 for i in (0,2,4)]
    return tuple(c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4 for c in values)
base=linear_hex('D5D8CE')
paint_entries=[tuple(round(c,5) for c in linear_hex(h)) for h in ['D5D8CE','C7CBC1']]
report['paint_variants']=[]
for suffix,hex in [('blue','617F98'),('sand','B7A989')]:
    target=linear_hex(hex);variant_palette=[]
    for rgb in palette:
        variant_palette.append(tuple(target[i]*rgb[i]/base[i] for i in range(3)) if rgb in paint_entries else rgb)
    variant=bpy.data.images.new('Gazelle '+suffix+' portable palette',width=64,height=64,alpha=False)
    variant_pixels=[]
    for y in range(64):
        for x in range(64):
            index=y//8*8+x//8
            color=variant_palette[index] if index<len(variant_palette) else variant_palette[0]
            variant_pixels.extend((*[srgb(v) for v in color],1))
    variant.pixels.foreach_set(variant_pixels);variant.pack()
    for mat in materials:
        for node in mat.node_tree.nodes:
            if node.type=='TEX_IMAGE':node.image=variant
    bpy.context.window.scene=export_scene
    variant_path=HERE/f'gazelle_2705_{suffix}.glb'
    bpy.ops.export_scene.gltf(filepath=str(variant_path),export_format='GLB',use_selection=True,use_active_scene=True,export_materials='EXPORT',export_cameras=False,export_lights=False)
    raw_variant=variant_path.read_bytes();length=struct.unpack_from('<I',raw_variant,12)[0]
    variant_doc=json.loads(raw_variant[20:20+length])
    report['paint_variants'].append(dict(file=variant_path.name,paint_srgb=hex,
        triangles=sum(variant_doc['accessors'][p['indices']]['count']//3 for m in variant_doc['meshes'] for p in m['primitives']),
        embedded_images=all('bufferView' in i for i in variant_doc.get('images',[]))))
(HERE/'glb_inspection.json').write_text(json.dumps(report,indent=2)+'\n')
