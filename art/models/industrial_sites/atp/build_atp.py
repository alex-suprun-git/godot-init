"""Focused ATP finish. Prepared ImageGen surfaces plus modeled architecture.

Run in Blender background. Saves atp.blend; export is a separate stage.
The 64 x24m hall retains its placement. A12 x12m dispatcher attaches at its
east end, within the existing140 x120m parcel, as in the selected reference.
"""
from pathlib import Path
import json
import math
import runpy
import bpy
import numpy as np

HERE=Path(__file__).resolve().parent
H=runpy.run_path(str(HERE.parent/'build_assets.py'),run_name='industrial_helpers')
Mesh=H['Mesh']
SCENE=H['SCENE']
SCENE.name='ATP_Finished'
MATS=H['MATERIALS']
TEXTURES=HERE/'textures'
UV_METRES={}


def generated_map(name,values,color_space='Non-Color'):
    height,width=values.shape[:2]
    image=bpy.data.images.new(name,width,height)
    image.colorspace_settings.name=color_space
    image.pixels.foreach_set(values.astype(np.float32).ravel())
    image.filepath_raw=str(TEXTURES/(name+'.png'))
    image.file_format='PNG'
    image.save()
    image.pack()
    return image


def surface(name,filename,metres,roughness,tint=(1,1,1),brick=False):
    mat=bpy.data.materials.new('ATP '+name)
    mat.use_nodes=True
    shader=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    shader.inputs['Base Color'].default_value=(*tint,1)
    shader.inputs['Roughness'].default_value=roughness
    image=bpy.data.images.load(str(TEXTURES/filename),check_existing=True)
    image.pack()
    tex=mat.node_tree.nodes.new('ShaderNodeTexImage')
    tex.image=image
    # Multiply actual albedo in a bake, so exported glTF does not lose tint nodes.
    if tint!=(1,1,1):
        pixels=np.empty(image.size[0]*image.size[1]*4,dtype=np.float32)
        image.pixels.foreach_get(pixels)
        values=pixels.reshape(image.size[1],image.size[0],4)
        values[:,:,:3]*=np.array(tint)
        image=generated_map(name.replace(' ','_')+'_albedo',values,'sRGB')
        tex.image=image
    shader.inputs['Base Color'].default_value=(1,1,1,1)
    mat.node_tree.links.new(tex.outputs['Color'],shader.inputs['Base Color'])
    pixels=np.empty(image.size[0]*image.size[1]*4,dtype=np.float32)
    image.pixels.foreach_get(pixels)
    values=pixels.reshape(image.size[1],image.size[0],4)
    rgb=values[:,:,:3]
    # Surface response is authored from restrained luminance / mortar masks,
    # not presented as a physically scanned PBR set.
    luminance=rgb.mean(axis=2)
    if brick:
        saturation=rgb.max(axis=2)-rgb.min(axis=2)
        mortar=np.clip((.15-saturation)*10,0,1)
        height=-mortar*.006+(luminance-luminance.mean())*.002
    else:
        height=(luminance-luminance.mean())*.001
    grad_y,grad_x=np.gradient(height)
    normal=np.dstack((-grad_x*image.size[0]/metres[0],
                      -grad_y*image.size[1]/metres[1],np.ones_like(height)))
    normal/=np.linalg.norm(normal,axis=2,keepdims=True)
    normal_pixels=np.ones_like(values)
    normal_pixels[:,:,:3]=normal*.5+.5
    normal_image=generated_map(name.replace(' ','_')+'_normal',normal_pixels)
    normal_tex=mat.node_tree.nodes.new('ShaderNodeTexImage')
    normal_tex.image=normal_image
    node=mat.node_tree.nodes.new('ShaderNodeNormalMap')
    node.inputs['Strength'].default_value=.55 if brick else .25
    mat.node_tree.links.new(normal_tex.outputs['Color'],node.inputs['Color'])
    mat.node_tree.links.new(node.outputs['Normal'],shader.inputs['Normal'])
    rough=np.ones_like(values)
    rough_value=np.clip(roughness+(luminance-luminance.mean())*.12,.2,.98)
    rough[:,:,:3]=rough_value[:,:,None]
    rough_image=generated_map(name.replace(' ','_')+'_roughness',rough)
    rough_tex=mat.node_tree.nodes.new('ShaderNodeTexImage')
    rough_tex.image=rough_image
    mat.node_tree.links.new(rough_tex.outputs['Color'],shader.inputs['Roughness'])
    MATS.append(mat)
    index=len(MATS)-1
    UV_METRES[index]=metres
    return index


BRICK=surface('red brown brick','brick-v1.png',(2,2),.91,brick=True)
CONCRETE=surface('precast concrete','concrete-v1.png',(3,3),.92,tint=(.82,.82,.78))
ROOF=surface('oxide roofing','roof-v1.png',(4,4),.83,tint=(.65,.59,.56))
DOOR=surface('painted door steel','door-v1.png',(3,3),.71,tint=(.77,.81,.80))
PALE=surface('dispatch mineral facing','concrete-v1.png',(3,3),.89,tint=(.96,.94,.85))
STEEL=H['material']('ATP dark galvanized fittings',(.085,.115,.12),.66)
FRAME=H['material']('ATP grey window frames',(.25,.28,.26),.69)
GLASS=H['material']('ATP dusty industrial glass',(.045,.075,.085),.33)
GLASS_ALT=H['material']('ATP uneven glazing',(.07,.105,.11),.40)
BLACK=H['material']('ATP unlit interior',(.012,.019,.020),.98)
CREAM=H['material']('ATP cream lettering',(.65,.64,.54),.82)
SAFETY=H['material']('ATP faded warning ochre',(.40,.29,.085),.8)
TIMBER=H['material']('ATP repair timber',(.20,.13,.075),.91)
m=Mesh('atp_hall')


def box(at,size,mat):
    m.box(at,size,mat)


def beam(a,b,width,mat):
    m.beam(a,b,width,mat)


def facade_window(x,y,z,w,h,side=False,back=False):
    # Reveal, individual panes and double transoms have physical depth.
    def b(u,v,d,ww,hh,dd,mat):
        box((d,v,u) if side else (u,v,d),(dd,hh,ww) if side else (ww,hh,dd),mat)
    along=z if side else x
    depth=x if side else z
    sign=-1 if back else 1
    b(along,y,depth-sign*.20,w+.1,h+.10,.09,BLACK)
    divisions=max(2,round(w/.85))
    for i in range(divisions):
        u=along-w/2+(i+.5)*w/divisions
        b(u,y,depth-sign*.13,w/divisions-.055,h-.1,.035,GLASS_ALT if i%5==0 else GLASS)
    for u in [along-w/2,along+w/2]+[along-w/2+i*w/divisions for i in range(1,divisions)]:
        b(u,y,depth,.065,h+.1,.14,FRAME)
    for v in [y-h/2,y+h/2,y-h*.12]:
        b(along,v,depth,w+.1,.07,.14,FRAME)
    b(along,y-h/2-.08,depth+sign*.06,w+.26,.14,.40,CONCRETE)


def door_leaf(pivot,sign,angle):
    leaf=Mesh('door_leaf')
    width=2.84
    x=sign*width/2
    leaf.box((x,2.65,0),(width,5.22,.10),DOOR)
    for xx in [0,sign*width]:
        leaf.box((xx,2.65,.07),(.11,5.3,.10),STEEL)
    for yy in [.12,1.65,3.2,5.18]:
        leaf.box((x,yy,.07),(width,.11,.11),FRAME)
    for xx in [.45,.95,1.45,1.95,2.45]:
        leaf.box((sign*xx,2.6,.065),(.04,5.0,.045),FRAME)
    # Narrow glazed observation panel and service handle.
    leaf.box((x,4.35,.105),(1.65,.68,.035),BLACK)
    leaf.box((x,4.35,.13),(1.49,.54,.025),GLASS)
    for xx in [-.5,0,.5]:
        leaf.box((x+xx,4.35,.15),(.04,.6,.05),FRAME)
    leaf.box((sign*(width-.25),2.25,.19),(.06,.42,.12),CREAM)
    for yy in [.7,2.6,4.7]:
        leaf.box((sign*.08,yy,.14),(.19,.30,.13),STEEL)
    c,s=math.cos(angle),math.sin(angle)
    vertices=[(pivot[0]+v[0]*c+v[2]*s,v[1],pivot[1]-v[0]*s+v[2]*c) for v in leaf.vertices]
    offset=len(m.vertices)
    m.vertices.extend(vertices)
    m.faces.extend([tuple(offset+i for i in f) for f in leaf.faces])
    m.slots.extend(leaf.slots)


# Hall walls are strips around actual openings; no full box behind the doors.
box((0,7.8,0),(64,.4,24),BRICK)
box((0,5.65,12),(64,.7,.42),BRICK)
box((0,5.65,-12),(64,.7,.42),BRICK)
box((0,3.8,-12),(64,7.6,.4),BRICK)
for i in range(9):
    x=-32+i*8
    width=1.1 if i in [0,8] else 2.2
    xx=x+(.55 if i==0 else -.55 if i==8 else 0)
    box((xx,2.65,12),(width,5.3,.46),BRICK)
    box((x,4.0,12.20),(.36,8.0,.25),CONCRETE)
    box((xx,.28,12.04),(width,.56,.56),CONCRETE)
for x in [-32,32]:
    box((x,4,0),(.45,8,24),BRICK)
    box((x,.30,0),(.56,.6,24.1),CONCRETE)
    # End gable, continuing the same brick courses.
    m.poly([(x,8,-12),(x,8,12),(x,11.2,0)],[(0,1,2)],BRICK)
    for z in [-8.2,8.2]:
        facade_window(x+(.26 if x>0 else -.26),6.3,z,4.0,1.8,side=True,back=x<0)
for i in range(8):
    x=-28+i*8
    facade_window(x,6.8,12.13,7.15,1.35)
    facade_window(x,6.8,-12.23,7.15,1.35,back=True)
    opening=i==5
    door_leaf((x-2.87,11.90),1,math.radians(-67) if opening else 0)
    door_leaf((x+2.87,11.90),-1,math.radians(54) if opening else 0)
    # Deep unlit service recess visible only through the open bay.
    if opening:
        box((x,2.65,7.4),(5.8,5.3,.15),BLACK)
        box((x,.03,9.6),(5.8,.06,4.8),CONCRETE)
        for xx in [x-2.95,x+2.95]:
            box((xx,2.65,9.6),(.15,5.3,4.8),BRICK)
        box((x,5.33,9.6),(5.8,.08,4.8),BLACK)
        box((x+1.6,.8,9.0),(.8,1.6,.6),DOOR)
        box((x-1.8,.45,9.2),(1.0,.9,1.3),TIMBER)
    box((x,.06,12.4),(6,.12,1.0),CONCRETE)
    for dx in [-3.2,3.2]:
        m.cylinder((x+dx,.5,12.8),.10,1.0,SAFETY,segments=10)
    # Period wall light, conduit, numbered enamel plate.
    box((x,5.7,12.38),(1.0,.15,.30),FRAME)
    box((x,5.62,12.41),(.78,.04,.23),CREAM)
    box((x+3.25,5.5,12.33),(.7,.38,.06),DOOR)
    m.text(str(i+1),(x+3.25,5.37,12.38),.26,CREAM)
    beam((x+3.5,.4,12.32),(x+3.5,5.7,12.32),.035,STEEL)

# Corrugated roof: low-profile physical ribs across the64m length, two slopes.
for sign in [-1,1]:
    vertices=[]
    xs=np.linspace(-32.45,32.45,261)
    for x in xs:
        rib=.055*(.5+.5*math.cos((x+32.45)*math.tau/.75))
        for z,y in [(sign*12.45,8.0),(0,11.23)]:
            vertices.append((x,y+rib,z))
    faces=[(i*2,i*2+2,i*2+3,i*2+1) for i in range(len(xs)-1)]
    m.poly(vertices,faces,ROOF)
    for t in [.32,.65]:
        z=sign*12.45*t
        y=11.23-3.23*t+.07
        beam((-32.45,y,z),(32.45,y,z),.045,ROOF)
    # Box-profile eaves channel with a dark open centre and outer lip.
    box((0,7.99,sign*12.55),(65,.18,.28),STEEL)
    box((0,8.09,sign*12.63),(65,.10,.06),ROOF)
    for x in [-30.5,-.5,30.5]:
        m.cylinder((x,4,sign*12.57),.105,7.8,STEEL,segments=12)
        for y in [1.0,3.5,6]:
            box((x,y,sign*12.57),(.28,.07,.29),FRAME)
        beam((x,.18,sign*12.57),(x,.18,sign*13.0),.18,STEEL)
    # Visible gable flashing closes the roof's cut sheet edges.
    for x in [-32.45,32.45]:
        beam((x,8.02,sign*12.45),(x,11.33,0),.18,ROOF)
box((0,11.36,0),(65,.14,.45),ROOF)
for x in [-18,18]:
    m.cylinder((x,11.9,0),.31,1.4,STEEL,segments=16)
    box((x,12.67,0),(1.1,.15,1.0),ROOF)
    box((x,11.34,0),(1.4,.15,1.4),ROOF)

# Attached two-storey12x12m dispatcher, matching the concept's lower mass.
box((38,3.0,0),(12,6,12),PALE)
box((38,.25,0),(12.2,.50,12.2),CONCRETE)
box((38,6.1,0),(12.4,.2,12.4),H['BITUMEN'])
for z in [-6.1,6.1]:
    box((38,6.23,z),(12.5,.28,.18),CONCRETE)
    for x in [34,38,42]:
        for y in [1.75,4.55]:
            if z>0 and x==38 and y<3:
                continue
            facade_window(x,y,z,2.0,1.65,back=z<0)
for z in [-3.8,0,3.8]:
    for y in [1.75,4.55]:
        facade_window(44.12,y,z,1.9,1.65,side=True)
box((38,1.35,6.11),(2.0,2.7,.08),FRAME)
for x in [37.53,38.47]:
    box((x,1.50,6.17),(.84,2.27,.04),GLASS)
    box((x+.22,1.25,6.24),(.035,.36,.08),CREAM)
box((38,3.05,7.0),(4.8,.20,2.6),CONCRETE)
box((38,2.96,8.25),(4.85,.10,.08),STEEL)
for y,depth in [(.12,3.0),(.27,2.4),(.42,1.8)]:
    box((38,y,7.0),(4.5,.16,depth),CONCRETE)
box((38,3.45,6.2),(6.7,.45,.12),FRAME)
m.text('ДИСПЕТЧЕРСКАЯ',(38,3.30,6.31),.30,CREAM)
box((-28,5.66,12.33),(4.2,.58,.12),FRAME)
m.text('АТП',(-28,5.46,12.44),.50,CREAM)
for x in [33.1,42.8]:
    beam((x,.3,6.30),(x,5.8,6.30),.055,STEEL)
box((31,1.45,12.9),(.9,1.7,.42),DOOR)
box((31,1.45,13.13),(.7,1.45,.06),FRAME)
for y in [.95,1.1,1.25]:
    box((31,y,13.18),(.50,.035,.04),BLACK)

obj=m.finish()
# Override inherited world UVs with per-surface physical repeat dimensions.
uv=obj.data.uv_layers.active
for face in obj.data.polygons:
    normal=face.normal
    sx,sy=UV_METRES.get(face.material_index,(2,2))
    for loop in face.loop_indices:
        v=obj.data.vertices[obj.data.loops[loop].vertex_index].co
        if abs(normal.z)>.7:
            u,w=v.x/sx,-v.y/sy
        elif abs(normal.y)>abs(normal.x):
            u,w=v.x/sx,v.z/sy
        else:
            u,w=-v.y/sx,v.z/sy
        uv.data[loop].uv=(u,w)
obj.data.calc_loop_triangles()
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'atp.blend'))
report={'asset':'atp_hall','main_hall_metres':[64,24,8],
        'dispatcher_metres':[12,12,6],'source_surfaces':'art/source_images/atp/material-atlas-v1.png',
        'triangles':len(obj.data.loop_triangles),
        'overall_blender_dimensions':[round(v,3) for v in obj.dimensions],
        'status':'Implemented for in-game review; not final visual approval'}
(HERE/'build_report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('ATP_BUILD_COMPLETE',report,flush=True)
