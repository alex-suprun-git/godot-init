"""Original civic venues, metres, Blender -Y front -> Godot +Z.

Run Blender --background --factory-startup --python this_file. Builds a separate
scene; joins each export by material, preserves editable source and reports.
Generated atlas must first be prepared with tools/optimize_asset.py.
"""
from pathlib import Path
import bpy
import math
import json
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
OUT = HERE / 'exports'
OUT.mkdir(parents=True, exist_ok=True)
scene = bpy.data.scenes.new('CivicVenues_Originals')
bpy.context.window.scene = scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1.0
parts = []
report = []

def material(name, color, metallic=0, roughness=.8, texture=False):
    m = bpy.data.materials.new('Venues_' + name)
    m.use_nodes = True
    m.diffuse_color = (*color, 1)
    bs = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bs.inputs['Base Color'].default_value = (*color, 1)
    bs.inputs['Metallic'].default_value = metallic
    bs.inputs['Roughness'].default_value = roughness
    if texture:
        node = m.node_tree.nodes.new('ShaderNodeTexImage')
        node.image = bpy.data.images.load(str(HERE/'textures/material-atlas-v1.png'), check_existing=True)
        m.node_tree.links.new(node.outputs['Color'], bs.inputs['Base Color'])
    return m

atlas = material('Prepared_albedo_atlas', (1, 1, 1), texture=True)
def tinted_atlas(name, tint, roughness=.75):
    m = material(name, (1,1,1), roughness=roughness, texture=True)
    bs = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    tex = next(n for n in m.node_tree.nodes if n.type == 'TEX_IMAGE')
    mix = m.node_tree.nodes.new('ShaderNodeMix')
    mix.data_type = 'RGBA'
    mix.blend_type = 'MULTIPLY'
    mix.inputs[0].default_value = 1
    color_a = next(s for s in mix.inputs if s.identifier == 'A_Color')
    color_b = next(s for s in mix.inputs if s.identifier == 'B_Color')
    color_b.default_value = (*tint,1)
    m.node_tree.links.new(tex.outputs['Color'],color_a)
    m.node_tree.links.new(next(s for s in mix.outputs if s.type == 'RGBA'),bs.inputs['Base Color'])
    return m

roof_atlas = tinted_atlas('Charcoal_roof_albedo', (.22,.24,.25))
stone_atlas = tinted_atlas('Polished_red_brown_stone', (.52,.47,.43), .42)
metal = material('Bronze_and_dark_metal', (.16, .13, .085), .65, .42)
glass = material('Bronze_glazing', (.15, .12, .073), .28, .22)
dk_glass = material('Older_blue_grey_glazing', (.14, .20, .22), .18, .32)
felt = material('Bitumen_roof', (.035, .04, .038))
curtain = material('Warm_curtains', (.36, .23, .10))
light = material('Warm_lamp_glass', (.85, .62, .28), 0, .4)
dark = material('Dark_clothing_and_fittings', (.065, .075, .08))
skin = material('Skin', (.57, .42, .29))
white = material('Barrier_cream', (.82, .80, .68))
red = material('Barrier_red', (.54, .10, .07))
font = bpy.data.fonts.load(str(ROOT/'init/assets/fonts/golos_text.ttf'))

def surface_material(name, metallic=0.0, tint=(1,1,1), normal_strength=.75):
    """Portable albedo, tangent normal and roughness, all using one UV channel."""
    m=material(name,(1,1,1),metallic=metallic)
    bs=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    nodes={}
    for kind in ['albedo','normal','roughness']:
        image=bpy.data.images.load(str(HERE/'textures/pbr-v2'/('surfaces-'+kind+'-v2.png')),check_existing=True)
        if kind!='albedo':image.colorspace_settings.name='Non-Color'
        node=m.node_tree.nodes.new('ShaderNodeTexImage');node.image=image;nodes[kind]=node
    if tint!=(1,1,1):
        mix=m.node_tree.nodes.new('ShaderNodeMix');mix.data_type='RGBA';mix.blend_type='MULTIPLY'
        mix.inputs[0].default_value=1
        a=next(s for s in mix.inputs if s.identifier=='A_Color')
        b=next(s for s in mix.inputs if s.identifier=='B_Color');b.default_value=(*tint,1)
        m.node_tree.links.new(nodes['albedo'].outputs['Color'],a)
        m.node_tree.links.new(next(s for s in mix.outputs if s.type=='RGBA'),bs.inputs['Base Color'])
    else:m.node_tree.links.new(nodes['albedo'].outputs['Color'],bs.inputs['Base Color'])
    normal_map=m.node_tree.nodes.new('ShaderNodeNormalMap');normal_map.inputs['Strength'].default_value=normal_strength
    m.node_tree.links.new(nodes['normal'].outputs['Color'],normal_map.inputs['Color'])
    m.node_tree.links.new(normal_map.outputs['Normal'],bs.inputs['Normal'])
    channels=m.node_tree.nodes.new('ShaderNodeSeparateColor');channels.mode='RGB'
    m.node_tree.links.new(nodes['roughness'].outputs['Color'],channels.inputs[0])
    m.node_tree.links.new(channels.outputs['Green'],bs.inputs['Roughness'])
    return m

surface_pbr=surface_material('Architectural_surfaces_PBR')
concrete_pbr=surface_material('Concrete_surfaces_PBR',tint=(.88,.90,.89))
metal_roof_pbr=surface_material('Standing_seam_PBR',metallic=.12,tint=(.72,.75,.78),normal_strength=.35)
warm_glass_pbr=surface_material('Curtained_restaurant_glazing_PBR',metallic=.12)
old_glass_pbr=surface_material('Older_civic_glazing_PBR',metallic=.06,tint=(.85,.95,1))
seam_metal=material('Painted_standing_seam_edges',(.055,.06,.063),.2,.65)
# Cell bounds are normalized image UVs, v upward.
CELLS = [(0,.5,.25,1),(.25,.5,.5,1),(.5,.5,.75,1),(.75,.5,1,1),
         (0,0,.25,.5),(.25,0,.5,.5),(.5,0,.75,.5),(.75,.235,1,.5),
         (.75,0,.872,.23),(.876,0,1,.23)]

def mesh(name, verts, faces, mat, uvs=None):
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.update()
    ob = bpy.data.objects.new(name, data)
    scene.collection.objects.link(ob)
    ob.data.materials.append(mat)
    if uvs:
        layer = data.uv_layers.new(name='UVMap')
        for poly, coords in zip(data.polygons, uvs):
            for li, uv in zip(poly.loop_indices, coords):
                layer.data[li].uv = uv
    parts.append(ob)
    return ob

def quad(name, corners, cell, tile=0):
    if cell in [0,1,2,3,4]:
        index={0:3,1:4,2:2,3:3,4:1}[cell]
        mat=metal_roof_pbr if cell==4 else concrete_pbr if cell==3 else surface_pbr
        return surface_quad(name,corners,index,mat,4.0 if tile else 0)
    # Split large surfaces to repeat inside one atlas cell without bleeding.
    p0,p1,p2,p3 = map(Vector, corners)
    w,h = (p1-p0).length, (p3-p0).length
    nx,ny = (max(1,math.ceil(w/tile)), max(1,math.ceil(h/tile))) if tile else (1,1)
    a,b,c,d = CELLS[cell]
    pad=.012 if cell < 6 else .0015
    verts,faces,uvs=[],[],[]
    for iy in range(ny):
        for ix in range(nx):
            u0,u1=ix/nx,(ix+1)/nx
            v0,v1=iy/ny,(iy+1)/ny
            ps=[p0+(p1-p0)*u+(p3-p0)*v for u,v in [(u0,v0),(u1,v0),(u1,v1),(u0,v1)]]
            base=len(verts);verts.extend(ps);faces.append(tuple(range(base,base+4)))
            fu=min(1,w/nx/tile) if tile else 1
            fv=min(1,h/ny/tile) if tile else 1
            uvs.append([(a+pad,b+pad),(a+pad+(c-a-2*pad)*fu,b+pad),
                        (a+pad+(c-a-2*pad)*fu,b+pad+(d-b-2*pad)*fv),
                        (a+pad,b+pad+(d-b-2*pad)*fv)])
    mat = roof_atlas if cell == 4 else stone_atlas if cell == 1 else atlas
    return mesh(name,verts,faces,mat,uvs)

def surface_quad(name,corners,index,mat=None,tile=4.0,window_half=None):
    mat=mat or surface_pbr
    p0,p1,p2,p3=map(Vector,corners)
    w,h=(p1-p0).length,(p3-p0).length
    nx,ny=(max(1,math.ceil(w/tile)),max(1,math.ceil(h/tile))) if tile else (1,1)
    col,row=index%3,index//3
    a,b,c,d=col/3,(1-row)/2,(col+1)/3,(2-row)/2
    if window_half is not None:
        mid=(a+c)/2
        if window_half==0:c=mid
        else:a=mid
    # Prevent pale neighboring tiles from leaking into dark roofs at map mip levels.
    pad=.012 if index==5 else .02
    a+=pad;b+=pad;c-=pad;d-=pad
    verts,faces,uvs=[],[],[]
    for iy in range(ny):
        for ix in range(nx):
            u0,u1=(ix*tile/w,min(w,(ix+1)*tile)/w) if tile else (0,1)
            v0,v1=(iy*tile/h,min(h,(iy+1)*tile)/h) if tile else (0,1)
            points=[p0+(p1-p0)*u+(p3-p0)*v for u,v in [(u0,v0),(u1,v0),(u1,v1),(u0,v1)]]
            start=len(verts);verts.extend(points);faces.append(tuple(range(start,start+4)))
            fu=(u1-u0)*w/tile if tile else 1
            fv=(v1-v0)*h/tile if tile else 1
            uvs.append([(a,b),(a+(c-a)*fu,b),(a+(c-a)*fu,b+(d-b)*fv),(a,b+(d-b)*fv)])
    return mesh(name,verts,faces,mat,uvs)

def box(name, at, size, mat=metal, cell=None, bevel=0):
    x,y,z=at; sx,sy,sz=(s/2 for s in size)
    v=[(x-sx,y-sy,z-sz),(x+sx,y-sy,z-sz),(x+sx,y+sy,z-sz),(x-sx,y+sy,z-sz),
       (x-sx,y-sy,z+sz),(x+sx,y-sy,z+sz),(x+sx,y+sy,z+sz),(x-sx,y+sy,z+sz)]
    fs=[(0,3,2,1),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7)]
    if cell is None and mat in [felt,glass,dk_glass]:
        for face in fs:
            corners=[v[i] for i in face]
            if mat==felt:result=surface_quad(name,corners,0,surface_pbr,4.0)
            else:
                result=surface_quad(name,corners,5,warm_glass_pbr if mat==glass else old_glass_pbr,
                    0,0 if mat==glass else 1)
        return result
    if cell is not None:
        result=None
        for f in fs:
            result=quad(name,[v[i] for i in f],cell,2.0 if cell==2 else 3.0)
        return result
    ob=mesh(name,v,fs,mat)
    if bevel:
        bpy.context.view_layer.objects.active=ob
        mod=ob.modifiers.new('Small physical edges','BEVEL');mod.width=bevel;mod.segments=1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return ob

def rod(name,a,b,r=.035,mat=metal):
    a,b=Vector(a),Vector(b)
    bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=r,depth=(b-a).length,location=(a+b)/2)
    ob=bpy.context.object;ob.name=name
    ob.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
    ob.data.materials.append(mat);parts.append(ob)
    return ob

def text(body, at, size=.4, mat=metal):
    curve=bpy.data.curves.new('Authored Cyrillic sign','FONT')
    curve.body=body;curve.font=font;curve.size=size;curve.align_x='CENTER';curve.extrude=.004
    ob=bpy.data.objects.new(body,curve);scene.collection.objects.link(ob)
    ob.location=at;ob.rotation_euler[0]=math.pi/2;ob.data.materials.append(mat)
    bpy.context.view_layer.objects.active=ob;ob.select_set(True)
    bpy.ops.object.convert(target='MESH');ob.select_set(False);parts.append(ob)

def front_window(x,y,z,w,h,old=False):
    glazing=dk_glass if old else glass
    box('Deep glazing reveal',(x,y+.035,z),(w+.16,.2,h+.16),metal)
    box('Opaque tinted glazing',(x,y-.08,z),(w,.035,h),glazing)
    for dx in [-w/2,w/2]: box('Vertical glazing bar',(x+dx,y-.11,z),(.075,.09,h+.08),metal)
    for dz in [-h/2,h/2]: box('Horizontal glazing bar',(x,y-.11,z+dz),(w+.06,.09,.075),metal)
    box('Glazing transom',(x,y-.12,z+.05),(w,.09,.055),metal)
    # Visible curtain strips avoid an empty shell, without a hidden interior.
    if not old:
        for dx in [-w*.39,w*.39]:
            box('Curtain behind window edge',(x+dx,y-.095,z),(.22,.018,h-.1),curtain)
        box('Reflected warm light',(x+.25,y-.105,z-.25),(.10,.016,.20),light)

def roof(x,y,w,d,eaves,rise):
    a,b=x-w/2,x+w/2; f,r=y-d/2,y+d/2
    quad('Front standing seam roof',[(a,f,eaves),(b,f,eaves),(b,y,eaves+rise),(a,y,eaves+rise)],4,3)
    quad('Rear standing seam roof',[(b,r,eaves),(a,r,eaves),(a,y,eaves+rise),(b,y,eaves+rise)],4,3)
    mesh('Roof gable closure',[(a,f,eaves),(a,y,eaves+rise),(a,r,eaves),
                              (b,f,eaves),(b,r,eaves),(b,y,eaves+rise)],[(0,1,2),(3,4,5)],metal)
    for xx in [a,b]:
        rod('Roof edge',(xx,f,eaves),(xx,y,eaves+rise),.045)
        rod('Roof edge',(xx,y,eaves+rise),(xx,r,eaves),.045)
    for yy in [f,r]: rod('Gutter',(a,yy,eaves),(b,yy,eaves),.07)
    rod('Ridge',(a,y,eaves+rise),(b,y,eaves+rise),.055)
    # The fold silhouette must survive the standard map camera, not only close-up normals.
    for i in range(1,int(w/.6)):
        xx=a+i*.6
        rod('Raised standing seam',(xx,f,eaves+.02),(xx,y,eaves+rise+.02),.018,seam_metal)
        rod('Raised standing seam',(xx,y,eaves+rise+.02),(xx,r,eaves+.02),.018,seam_metal)

def lamp(x,y,z):
    box('Wall lamp backing',(x,y,z),(.20,.14,.40))
    box('Wall lamp glass',(x,y-.09,z),(.15,.14,.28),light,bevel=.02)

def stairs(x,y,w):
    for i in range(3):
        box('Entrance step',(x,y+i*.32,.09+i*.08),(w,1.5-i*.32,.18+i*.16),cell=3)

def table(x,y,z=.0):
    rod('Table stem',(x,y,z),(x,y,z+.75),.055)
    box('Table top',(x,y,z+.78),(1.1,1.1,.07),cell=5)
    for dx in [-.85,.85]:
        box('Chair seat',(x+dx,y,z+.46),(.48,.5,.07),cell=5)
        box('Chair back',(x+dx*1.2,y,z+.74),(.06,.5,.45),cell=5)
        for dy in [-.19,.19]: rod('Chair leg',(x+dx,y+dy,z),(x+dx,y+dy,z+.45),.025)

def restaurant():
    # 26 x18 m body, front -Y. Higher wing is front-right, north on map.
    box('Hall base',(-4,0,.55),(18,18,1.1),cell=1)
    box('Hall rear',(-4,8.85,3.4),(18,.30,4.7),cell=0)
    box('Hall left',(-12.85,0,3.4),(.30,18,4.7),cell=0)
    box('Hall right',(4.85,0,3.4),(.30,18,4.7),cell=0)
    box('Hall ceiling',(-4,0,5.72),(18,18,.20),cell=0)
    for x in [-12.5,4.5]: box('Stone front pier',(x,-9.04,3.05),(.8,.42,6.1),cell=1)
    for i in range(6): front_window(-10.9+i*2.75,-9.04,3.35,2.6,4.55)
    roof(-4,0,18.8,18.8,5.8,1.0)
    box('Private wing',(9,0,3.7),(8,18,7.4),cell=0)
    box('Wing stone base',(9,-9.03,.55),(8.05,.12,1.1),cell=1)
    for x in [5.35,12.65]: box('Wing entrance stone',(x,-9.16,2.0),(.65,.35,4),cell=1)
    for x in [7.1,10.9]: front_window(x,-9.05,5.65,2.25,2.2)
    for x in [7.9,10.1]: front_window(x,-9.16,1.8,2.05,2.7)
    box('Heavy bronze entrance canopy',(9,-10.15,3.65),(8.5,2.7,.25),metal,bevel=.035)
    stairs(9,-11.4,7.2)
    roof(9,0,8.8,18.8,7.4,.8)
    for x in [5.7,12.3]: lamp(x,-9.42,2.65)
    for yy in [-5.5,.0,5.5]:
        # Side windows, physically oriented to face +X.
        before=len(parts);front_window(0,0,0,1.5,1.9)
        for ob in parts[before:]:
            for v in ob.data.vertices:
                a,b,c=v.co;v.co=(13-b,yy+a,5.5+c)
    box('Kitchen rear door',(-6,9.035,1.4),(1.3,.12,2.6),cell=5)
    for x in [-10,-2]: box('Kitchen high window',(x,9.08,3.6),(2.0,.09,.9),glass)
    for x in [-11.9,12.8]: rod('Rainwater downpipe',(x,8.9,.3),(x,8.9,5.7),.055)
    for x in [-6,9]: box('Chimney',(x,2,7.25 if x<0 else 8.5),(.5,.6,.9),cell=2)

def terrace():
    box('Terrace deck',(0,0,.12),(3.8,8.8,.24),cell=3)
    for y in [-4.25,4.25]:
        box('Wind screen',(0,y,1.45),(3.7,.06,1.5),glass)
        rod('Screen top',(-1.85,y,2.25),(1.85,y,2.25),.035)
    box('Long wind screen',(-1.85,0,1.45),(.06,8.5,1.5),glass)
    for y in [-4,-2,0,2,4]: rod('Terrace frame',(-1.85,y,.15),(-1.85,y,2.7),.035)
    for yy in [-2.7,0,2.7]: table(0,yy,.24)

def culture_house():
    # 30 m foyer plus side tenant, overall32 x24 m; front -Y.
    box('Foyer plinth',(0,-7,.38),(30.4,10.4,.76),cell=3)
    box('Foyer rear wall',(0,-2.1,3.1),(30,.3,6.0),cell=2)
    for x in [-14.65,14.65]: box('Foyer concrete end pier',(x,-7,3.25),(.7,10.0,6.5),cell=3)
    for x in range(-12,13,4):
        front_window(x,-12.08,3.1,3.7,5.0,True)
        box('Foyer structural pier',(x+1.95,-12.17,3.15),(.25,.35,6),cell=3)
    # Glazed side of foyer, visible from the standard map camera.
    for yy in [-10,-6]:
        before=len(parts);front_window(0,0,0,3.6,4.8,True)
        for ob in parts[before:]:
            for v in ob.data.vertices:
                a,b,c=v.co;v.co=(15.02-b,yy+a,3.2+c)
    box('Foyer flat roofing',(0,-7,6.28),(30.8,10.8,.28),felt)
    for y in [-12.35,-1.65]: box('Foyer roof coping',(0,y,6.42),(30.8,.16,.19),cell=3)
    box('Auditorium',(0,5,5.65),(26,14,11.3),cell=2)
    # Pale precast face between contrasting brick corners.
    quad('Auditorium front precast',[(-10,-2.035,6.4),(10,-2.035,6.4),(10,-2.035,11.1),(-10,-2.035,11.1)],3,3)
    for x in range(-10,11,4): box('Precast vertical seam',(x,-2.06,8.75),(.045,.035,4.6),metal)
    box('Auditorium flat roof',(0,5,11.44),(26.5,14.5,.3),felt)
    for y in [-2.2,12.2]: box('Auditorium coping',(0,y,11.57),(26.6,.18,.17),cell=3)
    for x in [-13.2,13.2]: box('Auditorium coping',(x,5,11.57),(.18,14.6,.17),cell=3)
    # Intact mosaic is behind a separate removable banner.
    quad('Ceramic civic mosaic',[(13.035,-.5,1.2),(13.035,10.5,1.2),(13.035,10.5,10.8),(13.035,-.5,10.8)],6)
    quad('Cheap vinyl over mosaic',[(13.09,.45,4.3),(13.09,9.55,4.3),(13.09,9.55,7.8),(13.09,.45,7.8)],7)
    for yy in [.4,9.6]:
        for zz in [4.25,7.85]: rod('Banner wall fastening',(13.13,yy,zz),(13.30,yy,zz+.08),.035)
    box('Entrance canopy',(0,-12.9,2.7),(11,2.2,.22),cell=3)
    for x in [-3.5,0,3.5]:
        front_window(x,-12.26,1.5,2.9,2.5,True)
        rod('Door handle',(x+.8,-12.45,1.15),(x+.8,-12.45,1.65),.035)
    box('Institutional sign backing',(0,-12.32,3.25),(11.4,.12,.8),metal)
    text('ДОМ КУЛЬТУРЫ',(0,-12.41,3.1),.45,white)
    stairs(0,-14.2,14)
    # Small rental tenant at the front-left end, coherent across projections.
    box('Video rental tenant',(-15,-10,1.6),(3,4,3.2),cell=2)
    front_window(-15,-12.09,1.55,2.1,2.1,True)
    box('Tenant sign',(-15,-12.3,3.25),(3.6,.12,.65),dk_glass)
    text('ВИДЕОПРОКАТ',(-15,-12.4,3.14),.22,white)
    quad('Disco poster',[(10.2,-12.31,.9),(12.3,-12.31,.9),(12.3,-12.31,3.5),(10.2,-12.31,3.5)],8)
    quad('Video notice',[(7.4,-12.32,1.1),(9.4,-12.32,1.1),(9.4,-12.32,3.2),(7.4,-12.32,3.2)],9)
    box('Rear service annex',(0,12.6,1.7),(15,2.8,3.4),cell=2)
    box('Service door',(0,14.05,1.3),(2,.12,2.6),metal)
    for x in [-5,5]: box('Rear service window',(x,14.06,2.45),(2.8,.10,.7),dk_glass)
    for x,y,h in [(-5,5,12),(6,-7,7.0),(1,8,12.2)]: box('Roof vent',(x,y,h),(.9,1.1,.8),cell=3)

def fence():
    box('Solid privacy panel',(0,0,1.4),(6,.35,2.8),cell=0)
    box('Wall base',(0,0,.25),(6,.48,.5),cell=1)
    box('Privacy wall coping',(0,0,2.82),(6,.48,.14),metal)
    box('Masonry pier',(-3,0,1.48),(.68,.66,2.96),cell=1)
    box('Pier cap',(-3,0,3.0),(.8,.78,.15),cell=3)

def gate():
    box('High gate leaf',(0,0,1.35),(3.8,.12,2.7),metal)
    for x in [i*.19-1.8 for i in range(20)]: box('Gate vertical fluting',(x,-.075,1.35),(.035,.04,2.56),metal)

def guardhouse():
    box('Guardhouse',(0,0,1.45),(4,4,2.9),cell=0)
    box('Guardhouse base',(0,0,.3),(4.15,4.15,.6),cell=1)
    for x in [-.95,.95]: front_window(x,-2.04,1.8,1.75,1.65)
    box('Guardhouse roof',(0,0,3.03),(4.5,4.5,.25),metal)
    box('Guardhouse door',(-2.06,.8,1.2),(.1,1.2,2.3),cell=5)

def guard():
    # Grounded 1.78 m person. No invisible facial detail.
    for x in [-.13,.13]:
        rod('Trouser leg',(x,0,.12),(x,0,.86),.095,dark)
        box('Shoe',(x,-.07,.09),(.19,.34,.16),dark,bevel=.025)
    box('Jacket',(0,0,1.13),(.47,.30,.56),dark,bevel=.07)
    rod('Left sleeve',(-.25,0,1.35),(-.31,-.04,.86),.075,dark)
    rod('Right sleeve',(.25,0,1.35),(.30,-.04,.86),.075,dark)
    for x in [-.31,.30]: box('Hand',(x,-.04,.83),(.11,.12,.14),skin,bevel=.025)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=1,location=(0,0,1.59))
    ob=bpy.context.object;ob.name='Guard head';ob.scale=(.12,.105,.16);ob.data.materials.append(skin);parts.append(ob)
    box('Peaked cap',(0,-.01,1.73),(.29,.26,.09),dark,bevel=.025)
    box('Cap visor',(0,-.15,1.70),(.24,.12,.035),dark)

if __name__ == "__main__":
    builders={'restaurant':restaurant,'restaurant_terrace':terrace,'culture_house':culture_house,
              'privacy_wall_6m':fence,'gate_leaf':gate,'guardhouse':guardhouse,'security_guard':guard}
    for name,build in builders.items():
        parts=[]
        bpy.ops.object.select_all(action='DESELECT')
        build()
        # Preserve semantic component names in .blend, export a single joined game mesh.
        collection=bpy.data.collections.new(name+'_editable');scene.collection.children.link(collection)
        for ob in parts:
            for old in list(ob.users_collection): old.objects.unlink(ob)
            collection.objects.link(ob)
        bpy.ops.object.select_all(action='DESELECT')
        clones=[]
        for source in parts:
            clone=source.copy();clone.data=source.data.copy();scene.collection.objects.link(clone)
            clone.select_set(True);clones.append(clone)
        bpy.context.view_layer.objects.active=clones[0]
        bpy.ops.object.join()
        asset=bpy.context.object;asset.name=name
        scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
        for image in bpy.data.images:
            if image.source=='FILE' and not image.packed_file:image.pack()
        path=OUT/(name+'.glb')
        bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,
            use_active_scene=True,export_yup=True,export_apply=True,export_materials='EXPORT')
        asset.data.calc_loop_triangles()
        report.append({'asset':name,'triangles':len(asset.data.loop_triangles),
            'materials':len(asset.data.materials),'dimensions_blender_m':list(asset.dimensions),
            'export':path.relative_to(ROOT).as_posix(),'objects_exported':1})
        bpy.data.objects.remove(asset,do_unlink=True)
        for ob in parts:ob.hide_set(True)
        print('VENUE_EXPORTED',name,flush=True)
    for ob in scene.objects:ob.hide_set(False)
    bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'civic_venues.blend'))
    (HERE/'export_report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print('CIVIC_VENUES_COMPLETE',flush=True)
