"""Measured original church family. Blender X east, Y north, Z up (metres).
Stages: blockout (two-angle review), build (editable source), export (GLBs).
No interactive Blender scene is used. Dimensions come from church_site.json.
"""
from pathlib import Path
import bpy, bmesh, math, json, sys, struct
from mathutils import Vector
from mathutils.geometry import tessellate_polygon

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
OUT=ROOT/'init/assets/models/church_ensemble'
TEXTURES=HERE/'textures'  # prepared surface maps (Blender inputs), kept out of the Godot project
SHARED_MATERIALS=ROOT/'init/assets/materials/church_ensemble'  # shared runtime maps + <material_slug>.tres
SCRATCH=ROOT/'.local/church-ensemble'
PLAN=json.loads((ROOT/'init/scripts/data/church_site.json').read_text())
STAGE=sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else 'build'
DETAIL=STAGE!='blockout'
OUT.mkdir(parents=True,exist_ok=True);SCRATCH.mkdir(parents=True,exist_ok=True)
if STAGE=='export':
    bpy.ops.wm.open_mainfile(filepath=str(HERE/'church_ensemble.blend'))
else:
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene
scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
parts=[];collection=None

def strip_shared_textures(path):
    """Church models share their textured materials (init/assets/materials/church_ensemble).
    Remove the per-model embedded textures; church_material_import.gd restores them by name."""
    import importlib.util
    spec=importlib.util.spec_from_file_location('strip_glb_textures',ROOT/'tools/strip_glb_textures.py')
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    document,binary=module.read_glb(path)
    document,binary,_=module.strip(document,binary,SHARED_MATERIALS)
    module.write_glb(path,document,binary)

def material(name,color,texture=None,rough=.8,metal=0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    n=m.node_tree.nodes;l=m.node_tree.links
    p=next(x for x in n if x.type=='BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
    if DETAIL and texture:
        for suffix,socket in [('', 'Base Color'),('_roughness','Roughness'),('_normal','Normal')]:
            path=TEXTURES/(texture+suffix+'.png')
            if not path.exists():raise RuntimeError('Prepare texture first: '+str(path))
            image=bpy.data.images.load(str(path),check_existing=True)
            t=n.new('ShaderNodeTexImage');t.image=image
            if suffix:image.colorspace_settings.name='Non-Color'
            if suffix=='_normal':
                nm=n.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.45
                l.new(t.outputs['Color'],nm.inputs['Color']);l.new(nm.outputs['Normal'],p.inputs[socket])
            else:l.new(t.outputs['Color'],p.inputs[socket])
    return m

def asset(name):
    global collection,parts
    collection=bpy.data.collections.new('asset_'+name);scene.collection.children.link(collection);parts=[]

def mesh(name,verts,faces,mat,smooth=False):
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    bm=bmesh.new();bm.from_mesh(me)
    if all(e.is_manifold for e in bm.edges):
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);me.update()
    bm.free()
    ob=bpy.data.objects.new(name,me);collection.objects.link(ob);me.materials.append(mat);parts.append(ob)
    uv=me.uv_layers.new(name='SurfaceMetres')
    for p in me.polygons:
        p.use_smooth=smooth
        axis=max(range(3),key=lambda i:abs(p.normal[i]))
        for li in p.loop_indices:
            v=me.vertices[me.loops[li].vertex_index].co
            uv.data[li].uv= ((v.y/2,v.z/2) if axis==0 else (v.x/2,v.z/2) if axis==1 else (v.x/2,v.y/2))
    return ob

def box(name,at,size,mat):
    x,y,z=at;a,b,c=[s/2 for s in size]
    return mesh(name,[(x-a,y-b,z-c),(x+a,y-b,z-c),(x+a,y+b,z-c),(x-a,y+b,z-c),
        (x-a,y-b,z+c),(x+a,y-b,z+c),(x+a,y+b,z+c),(x-a,y+b,z+c)],
        [(0,3,2,1),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7)],mat)

def beam(name,a,b,r,mat,segments=6):
    a,b=Vector(a),Vector(b);d=(b-a).normalized()
    u=d.cross(Vector((0,0,1)))
    if u.length<.1:u=d.cross(Vector((0,1,0)))
    u.normalize();v=d.cross(u)
    verts=[tuple(c+(u*math.cos(i*math.tau/segments)+v*math.sin(i*math.tau/segments))*r) for c in [a,b] for i in range(segments)]
    faces=[tuple(range(segments-1,-1,-1)),tuple(range(segments,2*segments))]
    faces += [(i,(i+1)%segments,(i+1)%segments+segments,i+segments) for i in range(segments)]
    return mesh(name,verts,faces,mat)

def lathe(name,c,profile,mat,n=48):
    verts=[(c[0]+r*math.cos(i*math.tau/n),c[1]+r*math.sin(i*math.tau/n),z) for z,r in profile for i in range(n)]
    faces=[tuple(range(n-1,-1,-1)),tuple(range((len(profile)-1)*n,len(profile)*n))]
    for row in range(len(profile)-1):
        for i in range(n):j=(i+1)%n;faces.append((row*n+i,row*n+j,(row+1)*n+j,(row+1)*n+i))
    return mesh(name,verts,faces,mat,True)

def prism_xz(name,poly,ya,yb,mat,along_x=False):
    # polygon is (horizontal,height), extruded through wall thickness.
    points=[Vector((a,b,0)) for a,b in poly]
    tris=tessellate_polygon([points]);lookup={tuple(p):i for i,p in enumerate(points)};n=len(poly)
    verts=[(u,y,z) if not along_x else (y,u,z) for y in [ya,yb] for u,z in poly]
    faces=[]
    for tri in tris:
        ids=tuple(p if isinstance(p,int) else lookup[tuple(p)] for p in tri)
        faces.extend([tuple(reversed(ids)),tuple(i+n for i in ids)])
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,verts,faces,mat)

def arch_poly(center,bottom,width,top,steps=12):
    r=width/2;spring=top-r
    return [(center-r,bottom),(center+r,bottom)]+[(center+math.cos(a)*r,spring+math.sin(a)*r) for a in [i*math.pi/steps for i in range(steps+1)]]

def arch_ring(name,c,bottom,w,top,thickness,ya,yb,mat,along_x=False):
    inner=arch_poly(c,bottom,w,top);outer=arch_poly(c,bottom-thickness,w+2*thickness,top+thickness)
    n=len(inner)
    def xyz(p,y):return (y,p[0],p[1]) if along_x else (p[0],y,p[1])
    verts=[xyz(p,y) for y in [ya,yb] for outline in [inner,outer] for p in outline]
    faces=[]
    for i in range(n):
        j=(i+1)%n
        faces.extend([(i,j,n+j,n+i),(2*n+i,3*n+i,3*n+j,2*n+j),(i,2*n+i,2*n+j,j),(n+i,n+j,3*n+j,3*n+i)])
    return mesh(name,verts,faces,mat)

def window(c,y,side=1,bottom=2.15,w=1.12,top=4.9,along_x=False):
    outer=y+side*.045;glass_y=y-side*.22
    arch_ring('Carved pale window surround',c,bottom,w,top,.14,outer,outer+side*.10,trim,along_x)
    arch_ring('Deep masonry reveal',c,bottom,w,top,.015,glass_y,outer,stone,along_x)
    prism_xz('Recessed arched glazing',arch_poly(c,bottom+.06,w-.1,top-.07),glass_y,glass_y-side*.025,glass,along_x)
    arch_ring('Timber arched frame',c,bottom+.07,w-.16,top-.08,.055,glass_y+side*.025,glass_y+side*.08,frame,along_x)
    if along_x:
        box('Window mullion',(glass_y+side*.09,c,(bottom+top)/2),(.06,.045,top-bottom-.14),frame)
        box('Window transom',(glass_y+side*.09,c,top-w/2),(.06,w-.12,.055),frame)
    else:
        box('Window mullion',(c,glass_y+side*.09,(bottom+top)/2),(.045,.06,top-bottom-.14),frame)
        box('Window transom',(c,glass_y+side*.09,top-w/2),(w-.12,.06,.055),frame)

def pitched(name,x0,x1,half,eaves,ridge,mat,center_y=0):
    return prism_xz(name,[(center_y-half,eaves),(center_y+half,eaves),(center_y,ridge)],x0,x1,mat,True)

def gable_roof(name,x0,x1,half,eaves,ridge):
    # Thin actual metal roof leaves the gable wall below it visible.
    for sign in [-1,1]:
        v=[(x0,0,ridge),(x1,0,ridge),(x1,sign*half,eaves),(x0,sign*half,eaves)]
        mesh(name,v,[(0,1,2,3),(3,2,1,0)],roof)
        if DETAIL:
            for i in range(int((x1-x0)/.55)+1):
                x=x0+(x1-x0)*i/max(1,int((x1-x0)/.55))
                beam('Raised standing seam',(x,0,ridge+.025),(x,sign*half,eaves+.025),.019,roof_edge,4)
            beam('Rolled gutter',(x0,sign*half,eaves),(x1,sign*half,eaves),.065,roof_edge,8)
    beam('Ridge cap',(x0,0,ridge+.04),(x1,0,ridge+.04),.075,roof_edge,8)

def cross(x,y,z,height,mat,orthodox=True):
    beam('Cross upright',(x,y,z),(x,y,z+height),.035 if height>1 else .025,mat,6)
    for level,width in [(.69,.64),(.87,.31)]:
        beam('Cross arm',(x,y-width*height/2,z+level*height),(x,y+width*height/2,z+level*height),.028,mat,6)
    if orthodox:beam('Slanted foot crossbar',(x,y-.22*height,z+.24*height),(x,y+.22*height,z+.36*height),.027,mat,6)

if STAGE!='export':
    plaster=material('Warm lime plaster',(.78,.75,.65),'plaster')
    roof=material('Muted green roof steel',(.19,.25,.16),'green_metal',.72,.18)
    roof_edge=material('Standing seam green edges',(.15,.21,.13),rough=.66,metal=.3)
    stone=material('Limestone plinth',(.44,.43,.38),'limestone')
    wood=material('Brown maintained timber',(.24,.12,.055),'wood')
    trim=material('Ivory lime mouldings',(.84,.81,.71),rough=.86)
    frame=material('Aged ivory window paint',(.59,.55,.41),rough=.8)
    glass=material('Dark muted church glazing',(.085,.13,.14),rough=.26,metal=.1)
    iron=material('Dark green painted iron',(.065,.083,.065),rough=.71,metal=.45)
    gold=material('Subdued gilded cross',(.55,.34,.075),rough=.35,metal=.8)
    bronze=material('Bell bronze',(.21,.14,.065),rough=.52,metal=.8)
    soil=material('Grave soil',(.16,.12,.075),rough=1)
    granite=material('Weathered grey memorial stone',(.32,.34,.32),rough=.9)
    asset('church')
    # 18 x 12 m masonry extent: west vestibule -9..-4.5, nave -4.5..4.5,
    # east apse 4.5..9; porch steps are outside this footprint.
    box('Nave stone base',(0,0,.32),(9.0,12,.64),stone)
    if DETAIL:
        for sign in [-1,1]:
            y=sign*6
            box('Lower nave wall',(0,y-sign*.21,1.37),(9,.42,1.46),plaster)
            last=-4.5
            for c in [-2.8,0,2.8]:
                left,right=c-.56,c+.56
                if left>last:box('Nave wall pier',((last+left)/2,y-sign*.21,3.62),(left-last,.42,5.96),plaster)
                spring=4.9-.56
                arc=[(c+math.cos(a)*.56,spring+math.sin(a)*.56) for a in [math.pi-i*math.pi/12 for i in range(13)]]
                prism_xz('Wall above arch',arc+[(right,6.6),(left,6.6)],y-sign*.42,y,plaster)
                window(c,y,sign);last=right
            box('Nave end pier',((last+4.5)/2,y-sign*.21,3.62),(4.5-last,.42,5.96),plaster)
            box('Cornice lower',(0,y-sign*.15,6.42),(9.3,.65,.16),trim)
            box('Cornice upper',(0,y-sign*.12,6.65),(9.55,.85,.18),trim)
            for x in [-4.35,4.35]:box('Corner pilaster',(x,y+sign*.04,3.52),(.30,.13,5.75),trim)
    else:box('Nave mass',(0,0,3.6),(9,12,6),plaster)
    for x in [-4.3,4.3]:box('Nave end wall',(x,0,3.6),(.4,12,6),plaster)
    # Hipped roof with a 3m ridge; horizontal nave roof matches the reference.
    verts=[(-4.8,-6.3,6.85),(4.8,-6.3,6.85),(4.8,6.3,6.85),(-4.8,6.3,6.85),(-1.5,0,9.1),(1.5,0,9.1)]
    mesh('Nave hipped metal roof',verts,[(0,1,5,4),(1,2,5),(2,3,4,5),(3,0,4)],roof)
    if DETAIL:
        for sign in [-1,1]:
            for x in [i*.55 for i in range(-8,9)]:
                start=max(-1.5,min(1.5,x));beam('Nave standing seam',(x,sign*6.3,6.87),(start,0,9.12),.018,roof_edge,4)
            beam('Nave gutter',(-4.8,sign*6.3,6.8),(4.8,sign*6.3,6.8),.07,roof_edge,8)
            for x in [-4.65,4.65]:
                beam('Drain pipe',(x,sign*6.34,6.8),(x,sign*6.34,.5),.055,roof_edge,8)
    # Small half-round eastern sanctuary: 4.5..9, width 7.2m.
    apse=[(4.5,-3.6),(5.4,-3.6)]+[(5.4+3.6*math.cos(a),3.6*math.sin(a)) for a in [-math.pi/2+i*math.pi/12 for i in range(13)]]+[(4.5,3.6)]
    n=len(apse)
    for name,lo,hi,mat in [('Apse stone base',0,.64,stone),('Apse masonry',.64,4.8,plaster)]:
        mesh(name,[(x,y,z) for z in [lo,hi] for x,y in apse],[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)],mat)
    roofverts=[(x*1.0+( .12 if x>5 else 0),y*1.05,4.95) for x,y in apse]+[(5.3,0,6.5)]
    mesh('Apse faceted roof',roofverts,[(i,(i+1)%n,n) for i in range(n)],roof)
    if DETAIL:
        window(0,9.015,1,bottom=1.8,w=.9,top=3.95,along_x=True)
        for i in range(2,n-2):beam('Apse roof fold',roofverts[i],roofverts[-1],.018,roof_edge,4)
    # West vestibule and attached belfry, clearly subordinate to the central dome.
    box('Vestibule plinth',(-6.75,0,.32),(4.5,6.4,.64),stone)
    box('Vestibule masonry',(-6.75,0,2.6),(4.5,6.4,4.0),plaster)
    pitched('Vestibule gable masonry',-9,-4.4,3.2,4.6,6.6,plaster)
    gable_roof('Vestibule metal roof',-9.25,-4.3,3.5,4.65,6.85)
    if DETAIL:
        # Door is recessed behind a built arched masonry portal.
        prism_xz('Dark entrance recess',arch_poly(0,.60,2.05,3.42),-9.025,-9.05,iron,True)
        prism_xz('Timber double door',arch_poly(0,.65,1.8,3.27),-9.065,-9.09,wood,True)
        arch_ring('Entrance stone archivolt',0,.60,2.05,3.42,.28,-9.14,-9.01,trim,True)
        box('Door centre stile',(-9.12,0,1.8),(.06,.055,2.25),frame)
        for y in [-.16,.16]:box('Door brass handle',(-9.16,y,1.63),(.065,.03,.22),gold)
        for i in range(3):box('Wide stone entrance step',(-9.35-i*.48,0,.10+(2-i)*.16),(1.0+i*.1,3.4,.20+(2-i)*.32),stone)
        for sign in [-1,1]:window(-6.6,sign*3.21,sign,bottom=1.45,w=.80,top=3.55)
    # Belfry has real open arches, not a painted black rectangle.
    bx=-5.35
    box('Belfry base',(bx,0,5.85),(2.55,2.7,.35),trim)
    if DETAIL:
        for x in [bx-1.02,bx+1.02]:
            for y in [-1.08,1.08]:box('Belfry pier',(x,y,6.92),(.4,.4,2.0),plaster)
        for sign in [-1,1]:
            arch_ring('Open belfry arch',0,6.05,1.75,8.02,.22,bx+sign*1.04,bx+sign*1.28,trim,True)
        lathe('Bronze bell',(bx,0),[(6.22,.47),(6.32,.49),(6.5,.38),(6.8,.25),(6.93,.18)],bronze,24)
        beam('Bell suspension',(bx,0,6.85),(bx,0,7.6),.055,iron)
        beam('Bell clapper',(bx,0,6.18),(bx,0,6.7),.055,iron)
    else:box('Belfry mass',(bx,0,6.95),(2.55,2.7,2),plaster)
    pitched('Belfry gable',bx-1.3,bx+1.3,1.4,8.02,9.12,plaster)
    gable_roof('Belfry roof',bx-1.48,bx+1.48,1.65,8.08,9.38)
    # Central octagonal drum and smooth onion profile: max height exactly18.5m.
    lathe('Drum base',(0,0),[(8.65,1.68),(8.9,1.85),(9.12,1.85),(9.25,1.65)],trim,32)
    lathe('Octagonal drum',(0,0),[(9.2,1.62),(12.15,1.62)],plaster,8)
    lathe('Drum cornice',(0,0),[(11.96,1.65),(12.12,1.82),(12.35,1.82),(12.48,1.72)],trim,32)
    if DETAIL:
        # Narrow dark arched lights and frames sit on the flat drum facets.
        for angle in [math.pi/8+i*math.pi/4 for i in range(8)]:
            before=len(parts);window(0,1.51,1,bottom=9.8,w=.50,top=11.55)
            for ob in parts[before:]:
                for v in ob.data.vertices:
                    x,y=v.co.x,v.co.y;v.co.x=x*math.cos(angle)-y*math.sin(angle);v.co.y=x*math.sin(angle)+y*math.cos(angle)
    profile=[(12.4,1.72),(12.75,1.94),(13.2,2.2),(13.7,2.30),(14.2,2.23),(14.7,1.98),(15.2,1.58),(15.7,1.08),(16.15,.59),(16.5,.22),(16.65,.055)]
    lathe('Single onion dome',(0,0),profile,roof,64 if DETAIL else 32)
    if DETAIL:
        for i in range(16):
            a=i*math.tau/16
            for (za,ra),(zb,rb) in zip(profile,profile[1:]):
                beam('Dome folded meridian',(ra*math.cos(a),ra*math.sin(a),za),(rb*math.cos(a),rb*math.sin(a),zb),.014,roof_edge,4)
    lathe('Cross gilded ball',(0,0),[(16.59,.05),(16.68,.14),(16.8,.17),(16.92,.08)],gold,16)
    cross(0,0,16.85,1.65,gold)

    if DETAIL:
        for name,key in [('parish_house','parish_house'),('shed','shed')]:
            asset(name);w,d=PLAN[key]['footprint'];e=PLAN[key]['eaves'];ridge=PLAN[key]['ridge']
            base=plaster if name=='parish_house' else wood
            box('Stone footing',(0,0,.20),(w,d,.4),stone)
            box('Wall body',(0,0,e/2+.2),(w,d,e-.0),base)
            pitched('Gable wall',-w/2,w/2,d/2,e,ridge,base)
            gable_roof('Pitched green roof',-w/2-.25,w/2+.25,d/2+.3,e+.1,ridge+.1)
            box('Front timber door',(0,-d/2-.04,1.3),(1.0,.10,2.15),wood)
            box('Door jamb',(0,-d/2-.10,2.45),(1.2,.14,.12),trim)
            if name=='parish_house':
                for x in [-2.9,2.9]:
                    window(x,-d/2-.01,-1,bottom=1.15,w=1.15,top=2.45)
                for sign in [-1,1]:window(0,sign*(w/2+.01),sign,bottom=1.15,w=1.15,top=2.45,along_x=True)
                box('Chimney',(2,1,4.7),(.6,.65,1.1),stone)
                box('Chimney coping',(2,1,5.27),(.8,.85,.14),trim)
                box('House entry step',(0,-d/2-.5,.12),(1.9,1.0,.24),stone)
            else:
                for x in [-w/2+.15,w/2-.15]:box('Shed corner board',(x,-d/2-.07,1.2),(.18,.08,2.3),roof_edge)
                box('Shed tiny window',(1.5,-d/2-.07,1.6),(.6,.05,.6),glass)
        asset('fence_panel')
        for x in [-1.5,1.5]:
            box('Masonry fence pier',(x,0,.78),(.32,.34,1.56),stone)
            box('Pale pier cap',(x,0,1.58),(.43,.45,.12),trim)
        for z in [.27,1.23]:box('Iron horizontal rail',(0,0,z),(2.7,.055,.055),iron)
        for i in range(17):
            x=-1.25+i*2.5/16
            box('Iron fence picket',(x,0,.80),(.032,.038,1.25),iron)
        asset('gate')
        # Exact clear widths between 0.4m piers: 3.6m vehicle +1m wicket.
        for x in [-2.7,1.3,2.7]:
            box('Gate pier',(x,0,.9),(.40,.40,1.8),stone);box('Gate cap',(x,0,1.84),(.52,.52,.14),trim)
        for a,b in [(-2.5,-.72),(-.68,1.1)]:
            for z in [.22,1.4]:box('Gate leaf rail',((a+b)/2,0,z),(b-a,.065,.065),iron)
            for i in range(10):
                x=a+(b-a)*i/9;box('Gate vertical iron',(x,0,.82),(.038,.04,1.25+.22*(1-abs(x+.5)/2)),iron)
        # Wicket is folded inward, leaving its actual pedestrian opening usable.
        for z in [.25,1.4]:box('Open wicket rail',(2.57,-.48,z),(.055,.90,.05),iron)
        for i in range(7):box('Open wicket picket',(2.57,-.08-i*.13,.82),(.035,.035,1.2),iron)
        asset('grave_cross')
        box('Old grave mound',(0,-.3,.08),(.85,1.8,.16),soil)
        # Cross arms lie along east-west; grave head is at its northern end.
        box('Wooden grave upright',(0,.70,.79),(.10,.10,1.58),wood)
        box('Wooden upper crossbar',(0,.69,1.37),(.31,.09,.08),wood)
        box('Wooden main crossbar',(0,.69,1.1),(.69,.10,.10),wood)
        ob=box('Slanted grave footrest',(0,.69,.48),(.48,.09,.075),wood)
        # baked local coordinates rotate just the short footrest about its centre.
        for v in ob.data.vertices:
            x,z=v.co.x,v.co.z-.48;v.co.x=x*math.cos(.22)-z*math.sin(.22);v.co.z=.48+x*math.sin(.22)+z*math.cos(.22)
        asset('grave_stone')
        box('Burial stone edging',(0,-.25,.10),(1.0,2.0,.20),stone)
        box('Grave soil',(0,-.25,.22),(.83,1.82,.08),soil)
        prism_xz('Rounded stone stela',[(-.31,.10),(.31,.10),(.31,1.1),(.2,1.28),(-.2,1.28),(-.31,1.1)],.61,.82,granite)
        box('Memorial inset',(0,.595,.78),(.36,.02,.38),iron)
        asset('grave_recent')
        box('Fresh dark earth mound',(0,-.2,.13),(.95,1.95,.26),soil)
        box('Fresh wooden cross',(0,.82,.80),(.085,.085,1.6),wood)
        box('Fresh crossbar',(0,.82,1.17),(.65,.085,.085),wood)
        box('Small grave plaque',(0,.76,.94),(.31,.025,.19),trim)
        asset('grave_rails')
        for x in [-.68,.68]:
            for y in [-1.35,1.05]:box('Grave enclosure post',(x,y,.34),(.04,.04,.68),iron)
            for z in [.20,.55]:box('Grave side rail',(x,-.15,z),(.035,2.4,.035),iron)
        for y in [-1.35,1.05]:
            for z in [.2,.55]:box('Grave end rail',(0,y,z),(1.36,.035,.035),iron)
        for x in [-.68,.68]:
            for y in [-1.05,-.55,-.05,.45,.85]:box('Grave enclosure upright',(x,y,.37),(.025,.025,.40),iron)
        asset('bench')
        for x in [-.80,.80]:
            for y in [-.22,.22]:box('Bench metal leg',(x,y,.24),(.065,.065,.48),iron)
            box('Back upright',(x,.25,.66),(.055,.055,.55),iron)
        for y in [-.21,-.07,.07,.21]:box('Bench seat plank',(0,y,.48),(2.0,.12,.065),wood)
        for z in [.70,.85]:box('Bench backrest plank',(0,.25,z),(2.0,.07,.12),wood)

    if STAGE=='build':
        for im in bpy.data.images:
            if im.source=='FILE':im.pack()
        bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'church_ensemble.blend'))
        print('EDITABLE_SOURCE_SAVED',flush=True)

if STAGE=='export':
    report=[]
    for col in list(scene.collection.children):
        if not col.name.startswith('asset_'):continue
        name=col.name[6:];objects=[o for o in col.all_objects if o.type=='MESH']
        bpy.ops.object.select_all(action='DESELECT')
        for ob in objects:ob.hide_set(False);ob.select_set(True)
        bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();ob=bpy.context.object;ob.name=name
        ob.data.calc_loop_triangles();tri=len(ob.data.loop_triangles)
        maximum=PLAN['budget']['church_triangles_max' if name=='church' else 'support_asset_triangles_max']
        if tri>maximum:raise RuntimeError(f'{name} exceeds triangle budget: {tri}>{maximum}')
        bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,export_materials='EXPORT')
        strip_shared_textures(OUT/(name+'.glb'))
        data=(OUT/(name+'.glb')).read_bytes();size,kind=struct.unpack_from('<II',data,12);doc=json.loads(data[20:20+size])
        if len(doc.get('meshes',[]))!=1 or len(doc.get('scenes',[]))!=1:raise RuntimeError('Unexpected GLB contents: '+name)
        bounds=[Vector(v) for v in ob.bound_box]
        dims=[max(v[i] for v in bounds)-min(v[i] for v in bounds) for i in range(3)]
        report.append({'asset':name,'blender_xyz_m':dims,'triangles':tri,'materials':len(doc.get('materials',[])),'embedded_images':len(doc.get('images',[]))})
        print('EXPORTED',name,tri,flush=True)
    (HERE/'export_report.json').write_text(json.dumps(report,indent=2)+'\n')

if STAGE=='blockout':
    import numpy as np
    scene.render.engine='BLENDER_WORKBENCH';scene.display.shading.color_type='MATERIAL'
    scene.display.shading.light='STUDIO';scene.display.shading.show_shadows=True;scene.display.shading.show_cavity=True
    scene.render.resolution_x=640;scene.render.resolution_y=620;scene.render.resolution_percentage=100
    camera=bpy.data.cameras.new('Two angle review');cam=bpy.data.objects.new('Two angle review',camera);scene.collection.objects.link(cam)
    scene.camera=cam;camera.type='ORTHO';camera.ortho_scale=26
    pixels=[]
    for label,eye in [('west_south',(-28,-35,26)),('east_north',(29,36,26))]:
        cam.location=eye;cam.rotation_euler=(Vector((0,0,8))-cam.location).to_track_quat('-Z','Y').to_euler()
        path=SCRATCH/('shape-'+label+'.png');scene.render.filepath=str(path);bpy.ops.render.render(write_still=True)
        im=bpy.data.images.load(str(path),check_existing=False);a=np.empty(640*620*4,dtype=np.float32);im.pixels.foreach_get(a);pixels.append(a.reshape(620,640,4))
    im=bpy.data.images.new('Shape comparison',width=1280,height=620,alpha=True)
    im.pixels.foreach_set(np.concatenate(pixels,axis=1).ravel());im.file_format='PNG';im.filepath_raw=str(SCRATCH/'shape-comparison.png');im.save()
print('CHURCH_STAGE_COMPLETE',STAGE,flush=True)
