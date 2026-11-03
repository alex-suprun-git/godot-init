"""Refine the saved three civic vegetation studies; separate wood/foliage meshes.

Metres, origin at ground. About 16k/13k triangles/tree, 6k/shrub, two materials.
No downloads, alpha cards, generated raster art or changes to furniture sources.
"""
from pathlib import Path
import bpy, bmesh, math, random, json
from mathutils import Vector

HERE = Path(__file__).resolve().parent
OUT = HERE / 'vegetation_exports'
OUT.mkdir(exist_ok=True)
report = {}


def material(name, color, vertex=False):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bs = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bs.inputs['Base Color'].default_value = (*color, 1)
    bs.inputs['Roughness'].default_value = .9
    if vertex:
        node = m.node_tree.nodes.new('ShaderNodeVertexColor')
        node.layer_name = 'LeafColor'
        m.node_tree.links.new(node.outputs['Color'], bs.inputs['Base Color'])
    # Real leaf geometry must be visible from either side.
    m.use_backface_culling = not vertex
    return m


def imported_wood(asset_id, scale):
    bpy.ops.object.select_all(action='DESELECT')
    bpy.ops.import_scene.gltf(filepath=str(HERE/'review_exports'/(asset_id+'.glb')))
    imported = list(bpy.context.selected_objects)
    woods = []
    for obj in imported:
        if obj.type != 'MESH':
            continue
        bm = bmesh.new(); bm.from_mesh(obj.data)
        leaf_slots = {i for i,m in enumerate(obj.data.materials) if m and 'Leaf' in m.name}
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.material_index in leaf_slots], context='FACES')
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
        bm.to_mesh(obj.data); bm.free()
        if not len(obj.data.polygons):
            bpy.data.objects.remove(obj, do_unlink=True)
            continue
        # Bake the original GLB world transform before scaling at the ground origin.
        transform = obj.matrix_world.copy()
        for v in obj.data.vertices:
            v.co = (transform @ v.co) * scale
        obj.parent = None
        obj.matrix_world.identity()
        obj.name = 'Wood'
        obj.data.materials.clear(); obj.data.materials.append(wood_mat)
        for p in obj.data.polygons: p.material_index = 0
        woods.append(obj)
    return woods


def leaf_mesh(name, clusters, rng, conifer=False):
    vertices, faces, colors = [], [], []
    for center, radii, count in clusters:
        center = Vector(center)
        for _ in range(count):
            # Fill porous irregular volumes, not closed spherical shells.
            direction = Vector((rng.uniform(-1,1),rng.uniform(-1,1),rng.uniform(-1,1))).normalized()
            r = rng.uniform(.78,1.08)
            p = center + Vector((direction.x*radii[0],direction.y*radii[1],direction.z*radii[2])) * r
            angle = rng.random()*math.tau
            side = Vector((math.cos(angle),math.sin(angle),rng.uniform(-.35,.35))).normalized()
            up = Vector((-side.y,side.x,rng.uniform(.4,1.2))).normalized()
            length = rng.uniform(.15,.27) if not conifer else rng.uniform(.18,.33)
            # Three joined diamond leaves form each small three-dimensional spray.
            for leaf in range(3):
                direction = (side*math.cos(leaf*2.1) + up*math.sin(leaf*2.1)).normalized()
                across = direction.cross(Vector((.2,.1,1))).normalized()
                w = length*(.36 if not conifer else .22)
                start = len(vertices)
                vertices.extend([p, p+direction*length*.5+across*w, p+direction*length, p+direction*length*.5-across*w])
                faces.extend([(start,start+1,start+2),(start,start+2,start+3)])
                tone = rng.uniform(.78,1.20)
                base = (.105,.19,.035) if not conifer else (.055,.13,.045)
                colors.extend([(*[c*tone for c in base],1)]*4)
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces); mesh.update()
    attr = mesh.color_attributes.new(name='LeafColor', type='FLOAT_COLOR', domain='POINT')
    for dst,color in zip(attr.data,colors): dst.color=color
    obj = bpy.data.objects.new(name, mesh); bpy.context.scene.collection.objects.link(obj)
    mesh.materials.append(leaf_mat)
    return obj


def canopy_core(clusters, rng, conifer):
    objects=[]
    for center,radii,_ in clusters:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2 if not conifer else 1,radius=1,location=center)
        obj=bpy.context.object; obj.name='Foliage_Core'
        for vertex in obj.data.vertices:
            p=vertex.co.normalized()
            ripple=1+.10*math.sin(p.x*13+p.z*9)*math.cos(p.y*11-p.z*7)
            vertex.co=Vector((p.x*radii[0],p.y*radii[1],p.z*radii[2]))*.84*ripple
        for face in obj.data.polygons: face.use_smooth=True
        attr=obj.data.color_attributes.new(name='LeafColor',type='FLOAT_COLOR',domain='POINT')
        for color in attr.data:
            tone=rng.uniform(.90,1.10)
            base=(.062,.115,.018) if not conifer else (.032,.078,.026)
            color.color=(*[c*tone for c in base],1)
        obj.data.materials.append(leaf_mat);objects.append(obj)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.object.join();objects[0].name='Foliage_Core'
    return objects[0]


def twig(a,b,r):
    a,b=Vector(a),Vector(b)
    bpy.ops.mesh.primitive_cone_add(vertices=6,radius1=r,radius2=r*.25,depth=(b-a).length,location=(a+b)/2)
    obj=bpy.context.object;obj.name='Twig'
    obj.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
    obj.data.materials.append(wood_mat)
    return obj


def build(asset_id, scale, source_id=None):
    scene = bpy.data.scenes.new(asset_id+'_refined')
    bpy.context.window.scene = scene
    scene.unit_settings.system='METRIC'
    source_id=source_id or asset_id
    wood = imported_wood(source_id,scale)
    clusters=[]
    rng=random.Random(asset_id)
    if asset_id=='park_poplar':
        # Retain the saved deciduous trunk/limbs, narrowed for a columnar poplar.
        for obj in wood:
            for v in obj.data.vertices:
                v.co.x*=.5;v.co.y*=.5
        wood.append(twig((0,0,4.8),(.1,.05,15.0),.13))
        for i in range(14):
            a=i*2.399;z=5.2+i*.7
            radius=1.38*(1-.40*abs((i-6)/7))
            center=Vector((math.cos(a)*.24,math.sin(a)*.24,z))
            clusters.append((center,(radius,radius*.88,1.13),160))
            for j in range(2):
                angle=a+j*2.1
                end=center+Vector((math.cos(angle)*radius*.75,math.sin(angle)*radius*.75,.35))
                wood.append(twig((0,0,z-.65),end,.022))
    elif asset_id=='park_deciduous_tree':
        for i in range(10):
            a=i*2.399; z=2.7+i*.28; r=1.2 if i<7 else .7
            center=Vector((math.cos(a)*r,math.sin(a)*r,z+.65))*scale
            clusters.append((center,(1.1*scale,scale,1.25*scale),240))
            for j in range(3):
                end=center+Vector((rng.uniform(-1,1),rng.uniform(-1,1),rng.uniform(.2,.9)))*scale
                wood.append(twig(center-Vector((0,0,.7))*scale,end,.018*scale))
    elif asset_id=='park_conifer':
        for i in range(9):
            z=(.7+i*.58)*scale
            radius=(1.45-i*.14)*scale
            for j in range(7):
                a=j*math.tau/7+i*.41
                end=Vector((math.cos(a)*radius,math.sin(a)*radius,z))
                wood.append(twig((0,0,z+.23*scale),end,.025*scale))
                clusters.append((end*.72+Vector((0,0,z*.28)),(.50*scale,.48*scale,.40*scale),27))
        clusters.append(((0,0,6.15*scale),(.38*scale,.38*scale,.75*scale),100))
    else:
        for i in range(12):
            p=Vector((rng.uniform(-.65,.65),rng.uniform(-.45,.45),rng.uniform(.35,.70)))
            clusters.append((p,(.48,.42,.40),65))
            wood.append(twig((p.x*.4,p.y*.4,.02),p,.013))
    foliage=leaf_mesh('Foliage',clusters,rng,asset_id=='park_conifer')
    core=canopy_core(clusters,rng,asset_id=='park_conifer')
    if wood:
        bpy.ops.object.select_all(action='DESELECT')
        for obj in wood: obj.select_set(True)
        bpy.context.view_layer.objects.active=wood[0]
        bpy.ops.object.join(); wood=[bpy.context.object]; wood[0].name='Wood'
    root=bpy.data.objects.new(asset_id,None);scene.collection.objects.link(root)
    for obj in [*wood,foliage,core]: obj.parent=root
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [root,*wood,foliage,core]:obj.select_set(True)
    bpy.context.view_layer.objects.active=root
    bpy.ops.export_scene.gltf(filepath=str(OUT/(asset_id+'.glb')),export_format='GLB',use_selection=True,use_active_scene=True,export_apply=True,export_cameras=False,export_lights=False,export_animations=False)
    all_points=[obj.matrix_world@v.co for obj in [*wood,foliage,core] for v in obj.data.vertices]
    lo=[min(p[i] for p in all_points) for i in range(3)]
    hi=[max(p[i] for p in all_points) for i in range(3)]
    triangles=0
    for obj in [*wood,foliage,core]:
        obj.data.calc_loop_triangles();triangles+=len(obj.data.loop_triangles)
    report[asset_id]={'triangles':triangles,'bounds_min':lo,'dimensions_m':[hi[i]-lo[i] for i in range(3)],'meshes':len(wood)+2,'source':'review_exports/'+source_id+'.glb'}


wood_mat=material('Civic_Vegetation_Wood',(.22,.17,.105))
leaf_mat=material('Civic_Vegetation_Leaf',(.16,.235,.065),True)
for asset_id,scale in [('park_deciduous_tree',1.55),('park_conifer',1.45),('park_shrub',1)]:
    build(asset_id,scale)
build('park_poplar',1.55,'park_deciduous_tree')
bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'civic_vegetation.blend'))
(HERE/'vegetation_report.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
