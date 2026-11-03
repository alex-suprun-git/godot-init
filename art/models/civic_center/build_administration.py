"""Four-storey civic landmark; physical window bays, metres, front Blender -Y."""
from pathlib import Path
import bpy, math, json, random
from mathutils import Vector
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
OUT=HERE/'review_exports'
scene=bpy.data.scenes.new('Administration_Review')
bpy.context.window.scene=scene
scene.unit_settings.system='METRIC'
parts=[]

def mat(name,rgb,metal=0):
    m=bpy.data.materials.get('Civic_'+name)
    if m:return m
    m=bpy.data.materials.new('Civic_'+name);m.use_nodes=True;m.diffuse_color=(*rgb,1)
    bs=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    bs.inputs['Base Color'].default_value=(*rgb,1);bs.inputs['Metallic'].default_value=metal;bs.inputs['Roughness'].default_value=.8
    return m
stone=mat('Limestone',(.64,.61,.53))
# Portable fine stone grain, authored here rather than baking architectural light.
stone_bs=next(n for n in stone.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
stone_im=bpy.data.images.new('Civic_limestone_grain',width=256,height=256)
stone_pixels=[]
stone_rng=random.Random(1997)
for y in range(256):
    for x in range(256):
        delta=stone_rng.uniform(-.018,.018)+.012*math.sin(x*.09)*math.sin(y*.065)
        stone_pixels.extend((.57+delta,.55+delta,.49+delta,1))
stone_im.pixels=stone_pixels
stone_im.filepath_raw=str(HERE/'textures/limestone_grain.png');stone_im.save()
stone_tex=stone.node_tree.nodes.new('ShaderNodeTexImage');stone_tex.image=stone_im
stone.node_tree.links.new(stone_tex.outputs['Color'],stone_bs.inputs['Base Color'])
granite=mat('Granite',(.23,.24,.23))
roof=mat('Roof_Felt',(.12,.13,.135))
bs_roof=next(n for n in roof.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
roof_node=roof.node_tree.nodes.new('ShaderNodeTexImage')
roof_image=bpy.data.images.new('Civic_clean_roof_felt',width=256,height=256)
pixels=[]
rng=random.Random(97)
for y in range(256):
    for x in range(256):
        v=.20+rng.uniform(-.012,.012)
        if x%64<2 or y%128<2:v-=.025
        pixels.extend((v,v*1.015,v*1.025,1))
roof_image.pixels=pixels
roof_image.filepath_raw=str(HERE/'textures/clean_roof_felt.png');roof_image.save()
roof_node.image=roof_image
roof.node_tree.links.new(roof_node.outputs['Color'],bs_roof.inputs['Base Color'])
metal=mat('Painted_Iron',(.065,.085,.075),.5)
glass=mat('Smoked_Glass',(.075,.11,.13),.25)
frame=mat('Window_Frame',(.26,.255,.22),.45)
reveal=mat('Window_Reveal',(.23,.24,.23))
spandrel=mat('Spandrel',(.49,.48,.43))
bronze=mat('Patinated_Bronze',(.16,.19,.135),.68)
paper=mat('Notice_Paper',(.73,.68,.50))

def box(name,p,s,m,b=.02):
    bpy.ops.mesh.primitive_cube_add(size=1,location=p)
    o=bpy.context.object;o.name=name;o.dimensions=s
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if b:
        mod=o.modifiers.new('Edges','BEVEL');mod.width=b;mod.segments=2
        bpy.ops.object.modifier_apply(modifier=mod.name)
    o.data.materials.append(m);parts.append(o);return o

def rod(name,a,b,r,m):
    a,b=Vector(a),Vector(b)
    bpy.ops.mesh.primitive_cylinder_add(vertices=10,radius=r,depth=(b-a).length,location=(a+b)/2)
    o=bpy.context.object;o.name=name;o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();o.data.materials.append(m);parts.append(o)

def export(name):
    bpy.ops.object.select_all(action='DESELECT')
    for o in parts:o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.object.join();o=bpy.context.object;o.name=name
    o.data.calc_loop_triangles()
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,use_active_scene=True,export_apply=True,export_cameras=False,export_lights=False,export_animations=False)
    print(name, len(o.data.loop_triangles),list(o.dimensions))

box('Office four floors',(0,0,7),(28,14,14),stone)
box('Solid hall end block',(18,0,9),(8,14,18),stone)
for x,w,h in [(0,28,14),(18,8,18)]:
    box('Dark roof',(x,0,h+.025),(w-.3,13.7,.10),roof)
    for y in [-6.95,6.95]:box('Parapet',(x,y,h+.18),(w,.10,.38),stone)
    for sx in [-1,1]:box('Parapet',(x+sx*w/2,0,h+.18),(.10,14,.38),stone)
    for seam in range(1,int(w/2)):
        box('Roof felt lap',(x-w/2+seam*2,0,h+.085),(.035,13.6,.012),roof,0)
box('Plinth',(4,0,.34),(36,14.07,.68),granite)
# Physical bays replace the rejected stretched generated facade. Raised piers and
# lintels put the glass behind a deep architectural grid on both long elevations.
for side in [-1,1]:
    for floor in range(4):
        z=1.95+floor*3.5
        box('Recessed spandrel',(0,side*7.09,z-1.25),(27.9,.14,.62),spandrel)
        for bay in range(7):
            x=-12+bay*4
            if side==-1 and floor==0 and bay in [2,3,4]:continue
            box('Window shadow pocket',(x,side*7.19,z),(3.1,.22,2.05),reveal)
            box('Window glass',(x,side*7.315,z),(2.82,.035,1.78),glass,.005)
            for dx in [-1.47,0,1.47]:
                box('Window mullion',(x+dx,side*7.35,z),(.065,.075,1.9),frame,.008)
            for dz in [-.93,.40,.93]:
                box('Window transom',(x,side*7.35,z+dz),(2.98,.075,.065),frame,.008)
            box('Stone sill',(x,side*7.43,z-1.05),(3.25,.52,.14),stone)
            # A few restrained opaque blinds, behind the glazing frame.
            if (bay+floor*3+(1 if side>0 else 0))%5==0:
                box('Pale blind',(x-.72,side*7.34,z+.45),(1.30,.02,.65),paper,.005)
        box('Floor lintel',(0,side*7.38,z+1.30),(28,.72,.45),stone)
    for x in range(-14,15,4):
        box('Vertical stone pier',(x,side*7.40,7.0),(.54,.80,13.5),stone)
    box('Upper cornice',(0,side*7.35,13.85),(28.3,.85,.28),stone)
# The public lobby is only on the square elevation; its doors remain human-sized.
for x in [-4,-2,0,2,4]:
    box('Lobby glazing',(x,-7.37,1.80),(1.88,.06,2.40),glass)
    for dx in [-.96,.96]:box('Lobby upright',(x+dx,-7.45,1.80),(.065,.1,2.45),frame)
    box('Lobby transom',(x,-7.46,2.70),(1.94,.10,.065),frame)
    if x in [-2,0,2]:
        box('Door meeting rail',(x,-7.46,1.55),(.05,.08,1.9),frame)
        box('Door pull',(x+.15,-7.53,1.55),(.035,.10,.36),bronze)
box('Service door',(10,7.48,1.1),(1.1,.1,2.2),metal)
box('Service door lintel',(10,7.56,2.30),(1.4,.28,.12),stone)
for z in [3.5,7,10.5]:
    box('Side floor joint',(-14.025,0,z),(.03,14,.035),granite,0)
for y in [-5,-2,1,4]:box('Side vertical joint',(-14.025,y,7),(.03,.025,14),granite,0)
joint=mat('Stone_Panel_Joint',(.52,.50,.45))
for z in range(2,18,2):
    box('Hall stone joint',(22.025,0,z),(.035,14,.025),joint,0)
    box('Hall front joint',(18,-7.03,z),(8,.035,.025),joint,0)
    box('Hall rear joint',(18,7.03,z),(8,.035,.025),joint,0)
for y in range(-6,7,2):box('Hall vertical joint',(22.025,y,9),(.035,.025,18),joint,0)
for x in [15,17,19,21]:
    box('Hall front vertical',(x,-7.03,9),(.025,.035,18),joint,0)
    box('Hall rear vertical',(x,7.03,9),(.025,.035,18),joint,0)
# A high meeting-hall clerestory breaks the blank slab without inventing floors.
for side in [-1,1]:
    for x in [15.2,17.05,18.9,20.75]:
        box('Hall high reveal',(x,side*7.09,16.35),(1.55,.16,1.05),reveal)
        box('Hall high glass',(x,side*7.19,16.35),(1.30,.04,.80),glass)
    box('Hall clerestory brow',(18,side*7.23,17.08),(8.2,.45,.18),stone)
# Main entrance and broad shallow steps belong to the square-facing wall only.
for i in range(5):box('Entry stair',(0,-8.4-i*.32,.06*(5-i)),(12.8,3.0-i*.32,.12*(5-i)),granite,.015)
box('Canopy',(0,-8.60,3.35),(12,3.40,.30),stone,.04)
for x in [-5,5]:box('Entry pier',(x,-9.55,1.85),(.28,.28,3),bronze)
# Accessible side ramp to the shallow entrance landing.
verts=[(6.4,-15,0),(8,-15,0),(8,-7,.6),(6.4,-7,.6),(6.4,-7,0),(8,-7,0)]
me=bpy.data.meshes.new('Entrance ramp');me.from_pydata(verts,[],[(0,1,2,3),(3,2,5,4),(0,3,4),(1,5,2),(0,4,5,1)]);me.materials.append(granite)
ob=bpy.data.objects.new('Side ramp',me);scene.collection.objects.link(ob);parts.append(ob)
for x in [6.5,7.9]:
    rod('Ramp handrail',(x,-15,.95),(x,-7,1.55),.025,bronze)
    for y,z in [(-15,.45),(-11,.75),(-7,1.05)]:rod('Ramp rail post',(x,y,z-.45),(x,y,z+.5),.025,bronze)
for x in [-7,7]:
    box('Notice case',(x,-7.15,1.75),(1.0,.12,.80),metal)
    box('Notice papers',(x,-7.22,1.75),(.84,.025,.65),paper)
for x in [-9,0,9]:box('Roof ventilation',(x,0,14.55),(1.3,1.0,.75),stone)
rod('Roof antenna',(10,3,14.2),(10,3,16.3),.025,metal)
rod('Antenna crossbar',(9.2,3,15.9),(10.8,3,15.9),.018,metal)
# Single large geometric relief, visible on the square-facing solid block.
for i,(y,z,h) in enumerate([(-1.9,8.9,4.0),(-.8,10,5.0),(.3,9.4,4.8),(1.4,8.6,3.3)]):
    box('Relief vertical',(22.12,y,z),(.18,.22,h),bronze,.03)
    if i%2==0:box('Relief crosspiece',(22.12,y+.35,z+.6),(.18,.9,.35),bronze,.04)
for z in [6.5,10.1]:box('Relief horizontal',(22.12,-.1,z),(.18,2.6,.18),bronze)
# Abstract rail wheel and rising tracks, made as raised metal rather than a decal.
for i in range(32):
    a=i*math.tau/32;b=(i+1)*math.tau/32
    rod('Relief wheel',(22.2,-.2+1.5*math.cos(a),7.7+1.5*math.sin(a)),(22.2,-.2+1.5*math.cos(b),7.7+1.5*math.sin(b)),.085,bronze)
for a in range(0,360,60):
    t=math.radians(a);rod('Relief spoke',(22.2,-.2,7.7),(22.2,-.2+1.4*math.cos(t),7.7+1.4*math.sin(t)),.055,bronze)
export('administration_four_storey_review')
parts=[]
# A small independent service garage; no cars merged into it.
box('Garage body',(0,0,1.6),(11,5.8,3.2),stone)
box('Garage roof',(0,0,3.25),(11.3,6.0,.16),roof)
for x in [-3.5,0,3.5]:
    box('Garage frame',(x,-2.94,1.45),(3.0,.12,2.85),metal)
    box('Garage doors',(x,-3.01,1.43),(2.86,.04,2.72),glass)
    box('Garage seam',(x,-3.04,1.43),(.025,.02,2.72),metal,0)
    for z in [.4,.85,1.3,1.75,2.2,2.65]:box('Garage door seam',(x,-3.04,z),(2.84,.025,.022),metal,0)
    box('Garage handle',(x+.2,-3.10,1.15),(.06,.10,.25),bronze)
box('Garage fascia',(0,-3.03,3.15),(11.4,.25,.28),stone)
export('service_garage_review')
parts=[]
rod('Flag pole',(0,0,0),(0,0,6.5),.045,metal)
box('Flagpole base',(0,0,.12),(.6,.6,.24),granite)
flag=mat('Blank_Flag',(.29,.065,.075))
verts=[(0,0,6.2),(.75,.10,6.1),(1.5,-.10,5.9),(0,0,5.35),(.75,.10,5.25),(1.5,-.10,5.05)]
me=bpy.data.meshes.new('Blank cloth');me.from_pydata(verts,[],[(0,1,4,3),(1,2,5,4)]);me.materials.append(flag)
ob=bpy.data.objects.new('Blank fictional flag review',me);scene.collection.objects.link(ob);parts.append(ob)
export('blank_flagpole_review')
bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'administration_review.blend'))
