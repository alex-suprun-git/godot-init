"""Complete measured homestead prefabs, before map placement.
Blender metres: X frontage, Y rear, Z up; front -Y exports as Godot +Z.
Stages: prototypes (two-angle assembly review), build (17 fitted sources), export.
"""
from pathlib import Path
import bpy, bmesh, math, json, sys, re, random, struct
from mathutils import Vector

HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[2]
OUT=ROOT/'init/assets/models/village';SCRATCH=ROOT/'.local/village-rebuild'
CFG=json.loads((HERE/'families.json').read_text())
STAGE=sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else 'build'
DETAIL=STAGE!='prototypes'
OUT.mkdir(parents=True,exist_ok=True);SCRATCH.mkdir(parents=True,exist_ok=True)
if STAGE=='export':bpy.ops.wm.open_mainfile(filepath=str(HERE/'village_sites.blend'))
else:
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
buffers={};collection=None;group='Structure';markers=[]

def material(name,color,tex=None,rough=.85,metal=0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    p=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
    if DETAIL and tex:
        for suffix,socket in [('', 'Base Color'),('_normal','Normal'),('_roughness','Roughness')]:
            im=bpy.data.images.load(str(OUT/(tex+suffix+'.png')),check_existing=True)
            if suffix:im.colorspace_settings.name='Non-Color'
            node=m.node_tree.nodes.new('ShaderNodeTexImage');node.image=im
            if suffix=='_normal':
                normal=m.node_tree.nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.35
                m.node_tree.links.new(node.outputs['Color'],normal.inputs['Color']);m.node_tree.links.new(normal.outputs['Normal'],p.inputs[socket])
            else:m.node_tree.links.new(node.outputs['Color'],p.inputs[socket])
    return m

def mesh(verts,faces,mat):
    key=(group,mat.name)
    if key not in buffers:buffers[key]=[[],[],mat]
    v,f,_=buffers[key];start=len(v);v.extend(verts);f.extend(tuple(start+i for i in face) for face in faces)

def box(at,size,mat):
    x,y,z=at;a,b,c=[s/2 for s in size]
    mesh([(x-a,y-b,z-c),(x+a,y-b,z-c),(x+a,y+b,z-c),(x-a,y+b,z-c),
          (x-a,y-b,z+c),(x+a,y-b,z+c),(x+a,y+b,z+c),(x-a,y+b,z+c)],
         [(0,3,2,1),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7)],mat)

def beam(a,b,r,mat,n=6):
    a,b=Vector(a),Vector(b);d=(b-a).normalized();u=d.cross(Vector((0,0,1)))
    if u.length<.1:u=d.cross(Vector((0,1,0)))
    u.normalize();v=d.cross(u)
    verts=[tuple(c+(u*math.cos(i*math.tau/n)+v*math.sin(i*math.tau/n))*r) for c in [a,b] for i in range(n)]
    mesh(verts,[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)],mat)

def cylinder(at,r,h,mat,n=12):
    x,y,z=at;beam((x,y,z-h/2),(x,y,z+h/2),r,mat,n)

def marker(kind,at,**props):
    ob=bpy.data.objects.new(kind,None);collection.objects.link(ob);ob.location=at
    for k,v in props.items():ob[k]=v
    markers.append(ob);return ob

def flush():
    for (category,name),(verts,faces,mat) in buffers.items():
        me=bpy.data.meshes.new(category+'_'+name);me.from_pydata(verts,[],faces);me.validate(clean_customdata=False);me.update()
        bm=bmesh.new();bm.from_mesh(me)
        # Most parts are closed primitives; unify face winding before export.
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free();me.update()
        uv=me.uv_layers.new(name='PhysicalSurfaceUV')
        for face in me.polygons:
            axis=max(range(3),key=lambda i:abs(face.normal[i]))
            for li in face.loop_indices:
                p=me.vertices[me.loops[li].vertex_index].co
                vertical=1.4 if 'Buff brick' in name else 2.0
                horizontal=.5 if 'Gravel' in name else 2.0
                uv.data[li].uv=((p.y/horizontal,p.z/vertical) if axis==0 else (p.x/horizontal,p.z/vertical) if axis==1 else (p.x/horizontal,p.y/horizontal))
        ob=bpy.data.objects.new(category+'_'+name,me);collection.objects.link(ob);me.materials.append(mat)

def roof(cx,cy,w,d,e,r,kind='hip'):
    global group
    old=group;group='Roofs'
    x0,x1=cx-w/2-.25,cx+w/2+.25;y0,y1=cy-d/2-.25,cy+d/2+.25
    if kind=='hip':
        ridge=max(.3,(w-d)/2)
        mesh([(x0,y0,e),(x1,y0,e),(x1,y1,e),(x0,y1,e),(cx-ridge,cy,r),(cx+ridge,cy,r)],[(0,1,5,4),(1,2,5),(2,3,4,5),(3,0,4)],steel)
        for sign in [-1,1]:
            if DETAIL:
                for i in range(int((w+.5)/.55)+1):
                    x=x0+i*(w+.5)/max(1,int((w+.5)/.55));rx=max(cx-ridge,min(cx+ridge,x))
                    beam((x,cy+sign*(d/2+.25),e+.02),(rx,cy,r+.02),.013,roof_edge,4)
            beam((x0,cy+sign*(d/2+.25),e),(x1,cy+sign*(d/2+.25),e),.055,roof_edge,8)
    else:
        mesh([(x0,y0,e),(x1,y0,e),(x1,y1,e),(x0,y1,e),(cx,y0,r),(cx,y1,r)],[(0,4,5,3),(4,1,2,5)],steel)
        for y in [y0+.20,y1-.20]:
            mesh([(x0+.20,y,e-.1),(x1-.20,y,e-.1),(cx,y,r-.08)],[(0,1,2)],gable_mat)
        if DETAIL:
            for i in range(int((d+.5)/.55)+1):
                y=y0+i*(d+.5)/max(1,int((d+.5)/.55))
                for x in [x0,x1]:beam((x,y,e+.02),(cx,y,r+.02),.013,roof_edge,4)
        for x in [x0,x1]:beam((x,y0,e),(x,y1,e),.055,roof_edge,8)
    for x in [x0+.12,x1-.12]:beam((x,y0,e),(x,y0,.3),.045,roof_edge,8)
    group=old

def window_front(x,y,z,w=1.25,h=1.45,angle=0,vacant=False):
    # Local front faces -Y. Parts are transformed into the actual facade frame.
    before={k:(len(v[0]),len(v[1])) for k,v in buffers.items()}
    def b(at,size,mat):box(at,size,mat)
    b((0,.015,z),(w+.16,.16,h+.16),dark)
    b((0,-.015,z),(w-.1,.05,h-.1),glass)
    for xx in [-w/2,0,w/2]:b((xx,-.075,z),(.065,.1,h+.07),ivory)
    for zz in [-h/2,h/2,.18]:b((0,-.075,z+zz),(w+.06,.1,.065),ivory)
    b((0,-.14,z-h/2-.07),(w+.30,.34,.10),concrete)
    if vacant:
        for zz in [-.28,.26]:b((0,-.16,z+zz),(w+.12,.035,.15),wood)
    elif DETAIL:
        for xx in [-w*.33,w*.33]:b((xx,.02,z),(.22,.015,h-.12),curtain)
    ca,sa=math.cos(angle),math.sin(angle)
    for key,(verts,faces,mat) in buffers.items():
        start=before.get(key,(0,0))[0]
        for i in range(start,len(verts)):
            a,b,c=verts[i];verts[i]=(x+a*ca-b*sa,y+a*sa+b*ca,c)

def wall(at,length,height,openings,mat,angle=0):
    # Build around real rectangular door/window apertures; no opaque plane behind glass.
    before={k:len(v[0]) for k,v in buffers.items()};last=-length/2
    for c,w,bottom,top in sorted(openings):
        left,right=c-w/2,c+w/2
        if left>last:box(((last+left)/2,0,(height+.4)/2),(left-last,.25,height-.4),mat)
        if bottom>.4:box((c,0,(bottom+.4)/2),(w,.25,bottom-.4),mat)
        if top<height:box((c,0,(height+top)/2),(w,.25,height-top),mat)
        last=right
    if last<length/2:box(((last+length/2)/2,0,(height+.4)/2),(length/2-last,.25,height-.4),mat)
    ca,sa=math.cos(angle),math.sin(angle)
    for key,(verts,faces,mm) in buffers.items():
        for i in range(before.get(key,0),len(verts)):
            x,y,z=verts[i];verts[i]=(at[0]+x*ca-y*sa,at[1]+x*sa+y*ca,z)

def main_house(cx,cy,params):
    global group,gable_mat
    group='House';w,d=params['house'];e=params['eaves'];r=params['ridge'];vac=params.get('vacant',False)
    face={'brick':brick,'plaster':plaster,'timber':timber}[params['wall']];gable_mat=face
    box((cx,cy,.2),(w+.08,d+.08,.4),plinth)
    if DETAIL:
        # Windows share the same measured apertures in every facade.
        for y,angle in [(cy-d/2,0),(cy+d/2,math.pi)]:
            front=angle==0
            xs=[-w*.31,w*.31] if front else [-w*.30,0,w*.30]
            openings=[(x,1.25,.95,2.40) for x in xs]
            if front:openings.append((0,1.0,.4,2.55))
            wall((cx,y),w,e,openings,face,angle)
            for x in xs:
                world_x=cx+x*math.cos(angle)
                window_front(world_x,y,1.675,angle=angle,vacant=vac)
        for x,angle in [(cx-w/2,-math.pi/2),(cx+w/2,math.pi/2)]:
            wall((x,cy),d,e,[(-d*.24,1.15,.95,2.4),(d*.24,1.15,.95,2.4)],face,angle)
            for yy in [-d*.24,d*.24]:window_front(x,cy+yy*math.sin(angle),1.675,w=1.15,angle=angle,vacant=vac)
    else:box((cx,cy,(e+.4)/2),(w,d,e-.4),face)
    box((cx,cy-d/2-.10,1.46),(1,.10,2.12),wood)
    for xx in [-.56,.56]:box((cx+xx,cy-d/2-.17,1.48),(.10,.12,2.30),ivory)
    box((cx,cy-d/2-.17,2.62),(1.25,.12,.10),ivory)
    if params.get('veranda',False):
        vw=4.8 if params['wall']=='plaster' else 3.2;vd=2.2
        vy=cy-d/2-vd/2
        box((cx,vy,.32),(vw,vd,.64),plinth)
        box((cx,vy-vd/2,1.30),(vw,.12,1.4),glass)
        for xx in [-vw/2,-vw/4,0,vw/4,vw/2]:box((cx+xx,vy-vd/2-.04,1.45),(.065,.1,1.65),ivory)
        for zz in [.65,1.4,2.25]:box((cx,vy-vd/2-.04,zz),(vw,.1,.065),ivory)
        for side in [-1,1]:
            box((cx+side*vw/2,vy,1.45),(.1,vd,1.65),glass)
            for yy in [-vd/2,0,vd/2]:box((cx+side*vw/2,vy+yy,1.45),(.1,.065,1.65),ivory)
        box((cx,vy-vd/2-.10,1.40),(.95,.07,2.1),wood)
        roof(cx,vy,vw+.1,vd+.1,2.45,2.9,'hip')
        front=vy-vd/2
    else:
        front=cy-d/2
        box((cx,front-.8,.35),(2.4,1.6,.20),concrete)
        box((cx,front-.75,2.75),(2.6,1.8,.14),steel)
        for xx in [-1.05,1.05]:box((cx+xx,front-1.45,1.55),(.07,.07,2.35),iron)
        front-=1.55
    for i in range(2):box((cx,front-.22-i*.32,.12+(1-i)*.12),(2.0,.7,.24+(1-i)*.24),concrete)
    roof(cx,cy,w,d,e+.05,r,params['roof'])
    box((cx+2.0,cy+1.4,r-.75),(.55,.6,1.65),brick)
    box((cx+2.0,cy+1.4,r+.10),(.72,.78,.12),concrete)
    if params.get('side_porch',False):
        px,py=cx+w/2+.9,cy-1.2
        box((px,py,.30),(1.8,2.8,.6),plinth)
        for sign in [-1,1]:
            box((px,py+sign*1.4,1.4),(1.8,.10,1.55),glass)
            for xx in [-.85,0,.85]:box((px+xx,py+sign*1.44,1.4),(.07,.10,1.65),ivory)
        box((px+.9,py,1.4),(.1,2.8,1.55),glass)
        for yy in [-1.35,0,1.35]:box((px+.94,py+yy,1.4),(.1,.07,1.65),ivory)
        roof(px,py,1.9,2.9,2.35,2.8,'hip')
    if params['wall']=='brick' and DETAIL and params['roof']=='hip':
        # Small attic light; its dormer is sized like a real window, not another floor.
        dy=cy-d*.22
        box((cx,dy,r-1.2),(1.7,1.2,1.0),face)
        window_front(cx,dy-.63,r-1.1,w=1.2,h=.75)
        roof(cx,dy,1.9,1.5,r-.65,r-.1,'gable')
    elif params['wall']=='brick' and DETAIL:
        window_front(cx,cy-d/2-.15,4.55,w=1.0,h=.95)

def small_building(cx,cy,w,d,garage=False,aged=False):
    global group,gable_mat
    group='Outbuildings';e=2.5 if garage else 2.25;r=3.25 if garage else 3.05
    face=plaster if garage else wood;gable_mat=face
    box((cx,cy,.15),(w+.10,d+.1,.3),concrete)
    box((cx,cy,e/2+.15),(w,d,e-.3),face)
    roof(cx,cy,w,d,e,r,'gable')
    if garage:
        door_w=w-.45
        box((cx,cy-d/2-.055,1.18),(door_w,.10,2.12),doorpaint)
        box((cx,cy-d/2-.12,1.18),(.055,.05,2.13),iron)
        for xx in [-door_w*.23,door_w*.23]:box((cx+xx,cy-d/2-.13,1.16),(.035,.05,.25),iron)
        for xx in [-w/2+.1,w/2-.1]:box((cx+xx,cy-d/2-.08,1.3),(.12,.12,2.5),concrete)
    else:
        box((cx,cy-d/2-.05,1.1),(.85,.1,1.95),wood)
        box((cx+w*.28,cy-d/2-.06,1.5),(.5,.06,.5),glass)

def fence_segment(a,b,front=False,timber_fence=False,age=False):
    global group
    group='Fence';dx,dy=b[0]-a[0],b[1]-a[1];length=math.hypot(dx,dy)
    if length<.15:return
    count=max(1,math.ceil(length/2.6));ux,uy=dx/length,dy/length
    h=1.55 if timber_fence else (1.75 if front else 1.65)
    for i in range(count+1):
        x,y=a[0]+dx*i/count,a[1]+dy*i/count
        box((x,y,h/2),(.26,.26,h),wood if timber_fence else brick)
        if not timber_fence:box((x,y,h+.04),(.36,.36,.10),concrete)
    # Opaque panels meet properly dimensioned posts; their length is adapted, not their height.
    for i in range(count):
        if age and i%9==5:continue
        x,y=a[0]+dx*(i+.5)/count,a[1]+dy*(i+.5)/count;span=length/count-.26
        size=(span,.07,h-.18) if abs(ux)>.5 else (.07,span,h-.18)
        box((x,y,.12+(h-.18)/2),size,wood if timber_fence else fencepaint)
        if DETAIL:
            for j in range(max(1,int(span/.27))):
                off=-span/2+j*.27
                box((x+ux*off,y+uy*off,h/2),(.028,.028,h-.2),wood if timber_fence else iron)

def gates(front,gx,foot_x,timber_fence=False):
    global group
    group='Fence';gate_w=3.4;h=1.6 if timber_fence else 1.75
    paint=wood if timber_fence else fencepaint
    for x in [gx-gate_w/2-.15,gx+gate_w/2+.15,foot_x-.65,foot_x+.65]:
        box((x,front,h/2),(.30,.30,h),wood if timber_fence else brick)
        if not timber_fence:box((x,front,h+.04),(.4,.4,.10),concrete)
    for sign in [-1,1]:
        box((gx+sign*.86,front,h/2),(1.68,.075,h-.12),paint)
        # Structural diagonal braces, not painted motifs.
        beam((gx+sign*.05,front-.065,.15),(gx+sign*1.63,front-.065,h-.15),.025,iron,4)
    # Open wicket folds into the parcel, leaving exactly1m clear between the piers.
    box((foot_x+.53,front+.49,.82),(.07,.96,1.52),paint)

def path_rect(cx,cy,w,d,mat):
    global group
    old=group;group='Ground';box((cx,cy,.045),(w,d,.035),mat);group=old

def greenhouse(cx,cy):
    global group
    group='Greenhouse';w,d=3.0,5.0;e=1.8;r=2.6
    # Muted translucent-looking glazing is opaque portable glass, avoiding sorting artifacts.
    for sign in [-1,1]:
        box((cx+sign*w/2,cy,.95),(.025,d,1.8),greenhouse_glass)
        mesh([(cx+sign*w/2,cy-d/2,e),(cx+sign*w/2,cy+d/2,e),(cx,cy+d/2,r),(cx,cy-d/2,r)],[(0,1,2,3)],greenhouse_glass)
    for i in range(6):
        y=cy-d/2+i*d/5
        beam((cx-w/2,y,.1),(cx-w/2,y,e),.026,ivory)
        beam((cx+w/2,y,.1),(cx+w/2,y,e),.026,ivory)
        for sign in [-1,1]:beam((cx+sign*w/2,y,e),(cx,y,r),.026,ivory)
    for x in [-w/2,0,w/2]:beam((cx+x,cy-d/2,.1),(cx+x,cy+d/2,.1),.035,concrete)
    box((cx,cy-d/2,1),(.05,.05,1.8),ivory)

def garden_bed(cx,cy,w=1.2,d=7):
    global group
    group='Ground';box((cx,cy,.075),(w,d,.08),soil)
    for sign in [-1,1]:box((cx+sign*(w/2+.03),cy,.10),(.06,d,.12),wood)
    group='SummerPlanting'
    for yy in range(int(d/.7)):
        for sign in [-1,1]:
            x,y=cx+sign*.29,cy-d/2+.4+yy*.7
            box((x,y,.24),(.35,.36,.24),leaves)
            box((x,y,.34),(.20,.28,.12),leaves_light)

def compose(name,family,width,depth,variant=0):
    global collection,buffers,markers,group,fencepaint,doorpaint
    buffers={};markers=[];group='Structure'
    collection=bpy.data.collections.new('asset_'+name);scene.collection.children.link(collection)
    params=CFG['families'][family];rng=random.Random(1200+variant)
    fencepaint=bluepaint if family=='new_brick' else greenpaint;doorpaint=fencepaint
    front=-depth/2+.6;hx=-3.0;hy=-depth/2+9.5
    if family in ['old_timber','vacant_timber']:hy=-depth/2+9.0
    main_house(hx,hy,params)
    w,d=params['house'];gx=min(8.0,width/2-2.8)
    if params['garage']=='attached':
        gx=hx+w/2+1.5;small_building(gx,hy-1.5,3,6,True)
    elif params['garage']=='separate':small_building(gx,-depth/2+8.5,3.5,6,True)
    foot=-3.0;timber_fence='timber' in family;vacant=params.get('vacant',False)
    lo,hi=-width/2+.5,width/2-.5;back=depth/2-.5
    gaps=sorted([(foot-.8,foot+.8),(gx-2,gx+2)])
    last=lo
    for a,b in gaps:
        fence_segment((last,front),(a,front),True,timber_fence,vacant);last=b
    fence_segment((last,front),(hi,front),True,timber_fence,vacant)
    fence_segment((lo,front),(lo,back),False,timber_fence,vacant)
    fence_segment((hi,front),(hi,back),False,timber_fence,vacant)
    fence_segment((lo,back),(hi,back),False,timber_fence,vacant)
    gates(front,gx,foot,timber_fence)
    path_rect(foot,-depth/2+1.9,1.2,2.6,concrete)
    drive_end=-depth/2+(5.1 if params['garage']=='attached' else 5.5)
    path_rect(gx,(front+drive_end)/2,3.35,drive_end-front,gravel)
    for sign in [-1,1]:path_rect(gx+sign*.78,(front+drive_end)/2,.48,drive_end-front,concrete)
    path_rect(gx,drive_end+.3,3.1,.6,concrete)
    spine=7.0 if params['garage']=='attached' else 4.0
    shed_x=hi-2.7;shed_y=back-2.4
    yard_start=-depth/2+4.2;yard_end=shed_y-1.5
    path_rect(spine,(yard_start+yard_end)/2,.85,yard_end-yard_start,gravel)
    path_rect((gx+spine)/2,yard_start,abs(gx-spine)+.85,.85,gravel)
    small_building(shed_x,shed_y,4,3,False,vacant)
    path_rect((spine+shed_x)/2,yard_end,abs(shed_x-spine)+.85,.85,gravel)
    bed_length=min(5.5,max(2.8,depth-18.0));garden_y=back-.8-bed_length/2
    if not vacant:
        for i in range(params['garden']):garden_bed(-2.8+i*1.5,garden_y,1.1,bed_length)
        if params.get('greenhouse',False):greenhouse(lo+2.5,back-3.2)
        group='YardDetails';line_y=hy+d/2+1.5
        for x in [4.8,7.5]:beam((x,line_y,.05),(x,line_y,2.0),.035,iron)
        beam((4.8,line_y,2),(7.5,line_y,2),.009,iron,4)
        group='SummerPlanting'
        for x in [5.1,6.0,6.9]:box((x,line_y,1.62),(.52,.02,.65),laundry)
        group='YardDetails';cylinder((shed_x-2.5,shed_y,.40),.30,.8,bluepaint)
    tree_positions=[(lo+2.0,hy+d/2+2.0),(lo+5.0,back-1.8),(hi-2.0,hy+d/2+1.8)]
    for i,(x,y) in enumerate(tree_positions):
        marker('FruitTree',(x,y,.04),height=3.7+(i%3)*.35)
        for dx,dy in [(-.7,.8),(.8,.7)]:
            marker('Shrub',(max(lo+.7,min(hi-.7,x+dx)),min(back-.7,y+dy),.04),scale=.19 if not vacant else .32)
    for x,y in [(lo+1.3,front+2.2),(hi-1.2,front+2.5)]:
        marker('Shrub',(x,y,.04),scale=.25 if not vacant else .38)
    if not vacant:
        group='Ground'
        for sign in [-1,1]:
            box((hx+sign*2.4,front+2.0,.08),(2.1,.85,.10),soil)
            marker('Flowerbed',(hx+sign*2.4,front+2.0,.1),width=2.0,depth=.7)
    marker('Entry_Wicket',(foot,front,.04));marker('Doorstep',(foot,-depth/2+1.8,.04))
    collection['family']=family;collection['frontage_m']=width;collection['depth_m']=depth
    flush()
    if STAGE=='prototypes':
        buffers={};group='ReviewVegetation'
        for ob in markers:
            if ob.name.startswith('FruitTree'):
                x,y,z=ob.location;hh=ob['height'];cylinder((x,y,hh*.4),.11,hh*.8,wood)
                box((x,y,hh*.74),(hh*.60,hh*.60,hh*.52),leaves)
        flush()
    planting=[]
    for ob in markers:
        kind=ob.name.split('.')[0]
        if kind not in ['FruitTree','Shrub','Flowerbed']:continue
        planting.append({'kind':kind,'at':[round(ob.location.x,4),round(ob.location.z,4),round(-ob.location.y,4)],'height':ob.get('height',4.0),'scale':ob.get('scale',.28),'width':ob.get('width',2.0),'depth':ob.get('depth',.7)})
    built=w*d+12+(18 if params['garage']=='attached' else 21 if params['garage']=='separate' else 0)
    circulation=3.35*(drive_end-front)+8+(.85*(yard_end-yard_start))+12
    garden_area=params['garden']*bed_length*2.4+48+(15 if params.get('greenhouse',False) else 0)
    return {'family':family,'frontage':width,'depth':depth,'wicket_local':[foot,front],'doorstep_local':[foot,-depth/2+1.8],'planting':planting,'area_m2':width*depth,'space_budget_m2':{'buildings':round(built,1),'circulation':round(circulation,1),'garden_and_service':round(garden_area,1),'need_with_30pct':round((built+circulation+garden_area)*1.3,1)}}

if STAGE!='export':
    brick=material('Buff brick',(.72,.68,.55),'buff_brick')
    plaster=material('Pale house plaster',(.78,.73,.57),'house_plaster')
    timber=material('Blue grey timber',(.28,.35,.36),'timber_boards')
    steel=material('Grey roof metal',(.28,.30,.30),'grey_roof',.73,.20)
    roof_edge=material('Roof folds and gutters',(.24,.27,.27),rough=.7,metal=.35)
    wood=material('Ordinary brown wood',(.26,.18,.10),'timber_boards')
    concrete=material('Yard concrete',(.53,.53,.48),'yard_concrete')
    gravel=material('Gravel driveway',(.42,.40,.33),'compacted_gravel')
    plinth=material('Masonry plinth',(.28,.23,.17),'buff_brick')
    soil=material('Garden soil',(.17,.12,.07),'garden_soil')
    greenpaint=material('Green fence steel',(.19,.25,.13),'fence_steel',.73,.25)
    bluepaint=material('Blue grey fence steel',(.24,.31,.35),rough=.75,metal=.25)
    iron=material('Dark household iron',(.065,.075,.065),rough=.75,metal=.4)
    ivory=material('Ivory window paint',(.76,.75,.67),rough=.82)
    dark=material('Deep window reveal',(.035,.045,.045),rough=.9)
    glass=material('Residential glazing',(.10,.17,.19),rough=.25,metal=.12)
    greenhouse_glass=material('Muted greenhouse glazing',(.36,.41,.32),rough=.38,metal=.15)
    curtain=material('Linen curtains',(.64,.59,.45),rough=.94)
    leaves=material('Vegetable foliage',(.17,.29,.10),rough=.96)
    leaves_light=material('Vegetable leaf tips',(.25,.36,.13),rough=.96)
    laundry=material('Plain household laundry',(.72,.72,.63),rough=.98)
    if STAGE=='prototypes':
        for i,family in enumerate(['new_brick','rebuilt_veranda','old_timber','new_gable']):compose('review_'+family,family,24,28,i)
    else:
        layout=(ROOT/'init/scripts/data/district_layout.gd').read_text(encoding='utf-8')
        plan={}
        for i,match in enumerate(re.finditer(r'"(d_\d+)":.*?Rect2\(([^)]+)\).*?"facing": "([nsew])"',layout)):
            id,raw,facing=match.groups();x,z,w,d=[float(a.strip()) for a in raw.split(',')]
            frontage,depth=(d,w) if facing in 'ew' else (w,d)
            family=CFG['parcels'][id];record=compose(id,family,frontage,depth,i)
            yaw={'s':0,'n':math.pi,'e':math.pi/2,'w':-math.pi/2}[facing]
            def world(v):
                xx,yy=v;zz=-yy
                return [round(x+w/2+xx*math.cos(yaw)+zz*math.sin(yaw),4),round(z+d/2-xx*math.sin(yaw)+zz*math.cos(yaw),4)]
            record.update({'center':[x+w/2,z+d/2],'yaw':yaw,'entrance':world(record['wicket_local']),'doorstep':world(record['doorstep_local']),'rect':[x,z,w,d]})
            plan[id]=record
        if len(plan)!=len(CFG['parcels']):raise RuntimeError('Missing fitted village parcels: '+str(len(plan)))
        (ROOT/'init/scripts/data/village_sites.json').write_text(json.dumps(plan,indent=2)+'\n',encoding='utf-8')
        for im in bpy.data.images:
            if im.source=='FILE':im.pack()
        bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'village_sites.blend'))
        print('COMPLETE_SITES_SOURCE_SAVED',len(plan),flush=True)

if STAGE=='export':
    reports=[]
    for col in list(scene.collection.children):
        if not col.name.startswith('asset_d_'):continue
        id=col.name.removeprefix('asset_')
        for summer in [False,True]:
            objects=[o for o in col.all_objects if o.type=='MESH' and o.name.startswith('SummerPlanting')==summer]
            if not objects:continue
            bpy.ops.object.select_all(action='DESELECT')
            for ob in objects:ob.select_set(True)
            bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();bpy.context.object.name='SummerPlanting' if summer else 'ParcelGeometry'
        bpy.ops.object.select_all(action='DESELECT')
        for ob in col.all_objects:ob.hide_set(False);ob.select_set(True)
        triangles=0
        for ob in col.all_objects:
            if ob.type=='MESH':ob.data.calc_loop_triangles();triangles+=len(ob.data.loop_triangles)
        if triangles>CFG['budgets']['complete_site_triangles_max']:raise RuntimeError(f'{id} exceeds geometry budget: {triangles}')
        path=OUT/(id+'.glb')
        bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,export_extras=True,export_materials='EXPORT')
        raw=path.read_bytes();size,kind=struct.unpack_from('<II',raw,12);doc=json.loads(raw[20:20+size])
        if len(doc.get('scenes',[]))!=1 or not 1<=len(doc.get('meshes',[]))<=2:raise RuntimeError('Unexpected parcel export '+id)
        if not any(n.get('name','').startswith('Entry_Wicket') for n in doc.get('nodes',[])):raise RuntimeError('Missing site marker '+id)
        reports.append({'id':id,'family':col['family'],'frontage_m':col['frontage_m'],'depth_m':col['depth_m'],'triangles':triangles,'meshes':len(doc['meshes']),'materials':len(doc.get('materials',[]))})
        print('EXPORTED_COMPLETE_PARCEL',id,triangles,flush=True)
    library=ROOT/'init/assets/materials/village'
    if library.exists():
        import importlib.util
        spec=importlib.util.spec_from_file_location('strip_glb_textures',ROOT/'tools/strip_glb_textures.py')
        strip_module=importlib.util.module_from_spec(spec);spec.loader.exec_module(strip_module)
        for report in reports:
            path=OUT/(report['id']+'.glb')
            document,binary=strip_module.read_glb(path)
            document,binary,info=strip_module.strip(document,binary,library)
            strip_module.write_glb(path,document,binary)
            report['embedded_images']=len(document.get('images',[]))
        print('SHARED_MATERIALS_RETAINED',len(reports),flush=True)
    (HERE/'export_report.json').write_text(json.dumps(reports,indent=2)+'\n')

if STAGE=='prototypes':
    import numpy as np
    scene.render.engine='BLENDER_WORKBENCH';scene.display.shading.color_type='MATERIAL';scene.display.shading.show_shadows=True;scene.display.shading.show_cavity=True
    scene.render.resolution_x=440;scene.render.resolution_y=440;scene.render.resolution_percentage=100
    camera=bpy.data.cameras.new('Whole parcel review');cam=bpy.data.objects.new('Whole parcel review',camera);scene.collection.objects.link(cam);scene.camera=cam;camera.type='ORTHO';camera.ortho_scale=48
    collections=[c for c in scene.collection.children if c.name.startswith('asset_review')]
    rows=[]
    for direction in [1,-1]:
        cells=[]
        for col in collections:
            for c in collections:c.hide_render=(c!=col)
            cam.location=(direction*45,-direction*55,46);cam.rotation_euler=(Vector((0,0,1))-cam.location).to_track_quat('-Z','Y').to_euler()
            path=SCRATCH/f'{col.name}_{direction}.png';scene.render.filepath=str(path);bpy.ops.render.render(write_still=True)
            im=bpy.data.images.load(str(path),check_existing=False);p=np.empty(440*440*4,dtype=np.float32);im.pixels.foreach_get(p);cells.append(p.reshape(440,440,4))
        rows.append(np.concatenate(cells,axis=1))
    pixels=np.concatenate(rows[::-1],axis=0);im=bpy.data.images.new('Complete parcel two-angle review',width=1760,height=880,alpha=True)
    im.pixels.foreach_set(pixels.ravel());im.file_format='PNG';im.filepath_raw=str(SCRATCH/'whole-parcel-review.png');im.save()
print('VILLAGE_STAGE_COMPLETE',STAGE,flush=True)
