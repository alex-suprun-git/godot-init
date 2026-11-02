"""Export only an asset scene; inspect actual GLB accessors and world bounds."""
from pathlib import Path
import json
import struct
import bpy
from mathutils import Matrix, Vector, Quaternion

PROJECT=Path(__file__).resolve().parents[3]
PRESENTATION_SCALE=0.85  # User requested a uniform 15% reduction on 2026-11-02.

def inspect_glb(path):
    raw=path.read_bytes(); size,tag=struct.unpack_from('<II',raw,12)
    doc=json.loads(raw[20:20+size]); start=20+size
    n,tag=struct.unpack_from('<II',raw,start);binary=raw[start+8:start+8+n]
    def accessor(i):
        a=doc['accessors'][i];v=doc['bufferViews'][a['bufferView']]
        dims={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
        fmt={5126:'f',5125:'I',5123:'H',5121:'B'}[a['componentType']]
        width=struct.calcsize('<'+fmt*dims);stride=v.get('byteStride',width)
        offset=v.get('byteOffset',0)+a.get('byteOffset',0)
        return [struct.unpack_from('<'+fmt*dims,binary,offset+j*stride) for j in range(a['count'])]
    points=[];triangles=0; primitives=0
    def visit(i,parent):
        nonlocal triangles,primitives
        node=doc['nodes'][i]
        if 'matrix' in node:
            m=Matrix([node['matrix'][j:j+4] for j in range(0,16,4)]).transposed()
        else:
            q=node.get('rotation',[0,0,0,1]);s=node.get('scale',[1,1,1])
            m=Matrix.Translation(node.get('translation',[0,0,0]))@Quaternion((q[3],q[0],q[1],q[2])).to_matrix().to_4x4()@Matrix.Diagonal((*s,1))
        world=parent@m
        if 'mesh' in node:
            for p in doc['meshes'][node['mesh']]['primitives']:
                primitives+=1
                pos=accessor(p['attributes']['POSITION'])
                points.extend(world@Vector(v) for v in pos)
                triangles+=(doc['accessors'][p['indices']]['count'] if 'indices' in p else len(pos))//3
        for j in node.get('children',[]):visit(j,world)
    for i in doc['scenes'][doc.get('scene',0)]['nodes']:visit(i,Matrix.Identity(4))
    low=[min(p[i] for p in points) for i in range(3)]
    high=[max(p[i] for p in points) for i in range(3)]
    return dict(file=path.name,triangles=triangles,meshes=len(doc.get('meshes',[])),
        nodes=len(doc.get('nodes',[])),scenes=len(doc['scenes']),primitives=primitives,
        materials=[m.get('name','') for m in doc.get('materials',[])],
        images=len(doc.get('images',[])),animations=len(doc.get('animations',[])),
        cameras=len(doc.get('cameras',[])),bounds_min=low,bounds_max=high,
        dimensions_xyz_m=[high[i]-low[i] for i in range(3)],
        forward='+Z',origin='ground centre')

def export(kind='uaz'):
    name='UAZ_Police' if kind=='uaz' else 'RAF_Ambulance'
    folder=PROJECT/'art/models'/('uaz_service' if kind=='uaz' else 'raf_ambulance')
    scene=bpy.data.scenes[name];bpy.context.window.scene=scene
    root=next(o for o in scene.objects if o.name.startswith(name) and o.type=='EMPTY')
    temp=bpy.data.collections.new('Temporary scoped export');scene.collection.children.link(temp)
    er=bpy.data.objects.new(name+' game',None);temp.objects.link(er)
    er.scale=(PRESENTATION_SCALE,)*3
    # Godot 4.7.2 imported the shared fittings with vertex albedo disabled.
    # Encode the exact same palette in a tiny portable atlas instead. This also
    # keeps the GLB independent of importer-specific material flag overrides.
    palette=[]
    for obj in root.children_recursive:
        if obj.type!='MESH':continue
        for c in obj.data.color_attributes['Color'].data:
            value=tuple(round(x,5) for x in c.color[:3])
            if value not in palette:palette.append(value)
    # Boolean-generated interior corners use black; retain it explicitly.
    if (0,0,0) not in palette:palette.append((0,0,0))
    assert len(palette)<=64, len(palette)
    atlas=bpy.data.images.new(name+' portable palette',width=64,height=64,alpha=False)
    atlas.colorspace_settings.name='sRGB'
    def srgb(c):return 12.92*c if c<=.0031308 else 1.055*c**(1/2.4)-.055
    pixels=[]
    for y in range(64):
        for x in range(64):
            index=(y//8)*8+x//8
            color=palette[index] if index<len(palette) else palette[0]
            pixels.extend((*[srgb(c) for c in color],1))
    atlas.pixels.foreach_set(pixels);atlas.pack()
    portable={}
    for obj in root.children_recursive:
        if obj.type!='MESH':continue
        for mat in obj.data.materials:
            if mat is None:continue
            if mat.name in portable:continue
            copy=mat.copy();copy.name=mat.name+' portable'
            shader=next(n for n in copy.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
            for link in list(shader.inputs['Base Color'].links):copy.node_tree.links.remove(link)
            tex=copy.node_tree.nodes.new('ShaderNodeTexImage');tex.image=atlas;tex.interpolation='Closest'
            copy.node_tree.links.new(tex.outputs['Color'],shader.inputs['Base Color'])
            portable[mat.name]=copy
    deps=bpy.context.evaluated_depsgraph_get();groups={}
    for obj in root.children_recursive:
        if obj.type!='MESH':continue
        data=bpy.data.meshes.new_from_object(obj.evaluated_get(deps),preserve_all_data_layers=True,depsgraph=deps)
        for layer in list(data.uv_layers):data.uv_layers.remove(layer)
        uv=data.uv_layers.new(name='PaletteUV')
        colors=data.color_attributes['Color']
        for i,c in enumerate(colors.data):
            color=c.color[:3]
            index=min(range(len(palette)),key=lambda j:sum((palette[j][k]-color[k])**2 for k in range(3)))
            uv.data[i].uv=((index%8+.5)/8,(index//8+.5)/8)
        for i,mat in enumerate(list(data.materials)):
            data.materials[i]=portable[mat.name] if mat else next(iter(portable.values()))
        copy=bpy.data.objects.new(obj.name+' export',data);temp.objects.link(copy);copy.matrix_world=obj.matrix_world.copy()
        key=obj.parent.name if obj.parent!=root and obj.parent.type=='EMPTY' else 'Body'
        groups.setdefault(key,[]).append(copy)
    exported=[]
    for name,objects in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects:o.select_set(True)
        bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join()
        obj=bpy.context.object;obj.name=name+' game';obj.parent=er;exported.append(obj)
    bpy.ops.object.select_all(action='DESELECT')
    for o in [er]+exported:o.select_set(True)
    bpy.context.view_layer.objects.active=er
    path=PROJECT/'init/assets/models/vehicles'/('uaz_police.glb' if kind=='uaz' else 'raf_ambulance.glb')
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,use_active_scene=True,
        export_apply=True,export_yup=True,export_animations=False,export_cameras=False,export_lights=False)
    report=inspect_glb(path)
    report['palette_texture']='one embedded 64 x 64 nearest-filtered sRGB atlas'
    report['presentation_scale']=PRESENTATION_SCALE
    report['source_wheelbase_m']=root['wheelbase_m']
    report['wheelbase_m']=root['wheelbase_m']*PRESENTATION_SCALE
    (folder/'glb_inspection.json').write_text(json.dumps(report,indent=2)+'\n')
    for o in list(temp.objects):bpy.data.objects.remove(o,do_unlink=True)
    bpy.data.collections.remove(temp)
    bpy.ops.object.select_all(action='DESELECT');root.select_set(True);bpy.context.view_layer.objects.active=root
    print(json.dumps(report))
    return report

if __name__=='__main__':export('uaz')
