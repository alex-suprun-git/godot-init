"""Original early GAZ-2705 panel van. Run with background Blender --python.
Metres, -Y forward; independent file/process, no shared live Blender edits.
"""
from pathlib import Path
import math
import bpy
import bmesh
from mathutils import Vector

HERE = Path(__file__).resolve().parent
COLORS = dict(paint='D5D8CE', panel='C7CBC1', seam='858F87', glass='3E5660',
              rubber='282E2D', steel='8F9996', dark='485451', lamp='DDDCC1',
              amber='B9823A', red='9E453A', reflection='68818A')

def linear(hex):
    rgb=[int(hex[i:i+2],16)/255 for i in (0,2,4)]
    return tuple(c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4 for c in rgb)+(1,)

def build():
    # This is a fresh background process. Keep only this asset's named scene.
    scene=bpy.data.scenes.new('GAZ_2705'); bpy.context.window.scene=scene
    scene.unit_settings.system='METRIC'
    col=bpy.data.collections.new('GAZ_2705 geometry'); scene.collection.children.link(col)
    root=bpy.data.objects.new('GAZ_2705',None);col.objects.link(root)
    root['forward']='Blender -Y / Godot +Z'
    mats=[]
    for name,rough,metal in [('paint',.49,.12),('glass',.23,.15),('fittings',.64,.20)]:
        mat=bpy.data.materials.new('Gazelle '+name);mat.use_nodes=True
        bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
        bs.inputs['Roughness'].default_value=rough;bs.inputs['Metallic'].default_value=metal
        vc=mat.node_tree.nodes.new('ShaderNodeVertexColor');vc.layer_name='Color'
        mat.node_tree.links.new(vc.outputs['Color'],bs.inputs['Base Color']);mats.append(mat)

    def adopt(obj,color,mat=0):
        for c in list(obj.users_collection):c.objects.unlink(obj)
        col.objects.link(obj);obj.parent=root;obj.data.materials.append(mats[mat])
        ca=obj.data.color_attributes.new(name='Color',type='FLOAT_COLOR',domain='CORNER')
        for c in ca.data:c.color=linear(COLORS[color])
        return obj
    def mesh(name,vs,fs,color,mat=0,smooth=False):
        data=bpy.data.meshes.new(name);data.from_pydata(vs,[],fs);data.update()
        bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(data);bm.free()
        ob=bpy.data.objects.new(name,data);adopt(ob,color,mat)
        for p in data.polygons:p.use_smooth=smooth
        return ob
    def box(name,pos,size,color,bevel=.012,mat=2,segments=1):
        bpy.ops.mesh.primitive_cube_add(size=1,location=pos);o=bpy.context.object;o.name=name
        o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        adopt(o,color,mat)
        if bevel:
            m=o.modifiers.new('Rolled edge','BEVEL');m.width=bevel;m.segments=segments
            o.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
        return o
    def line(name,points,r,color,mat=2):
        # Explicit small polygon tubes keep exports deterministic and editable.
        vs=[];n=4
        for i,p in enumerate(points):
            p=Vector(p);t=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(i-1,0)])
            t.normalize();a=t.cross(Vector((0,0,1)))
            if a.length<.01:a=t.cross(Vector((0,1,0)))
            a.normalize();b=t.cross(a).normalized()
            for j in range(n):vs.append(p+r*(a*math.cos(j*math.tau/n)+b*math.sin(j*math.tau/n)))
        fs=[tuple(range(n-1,-1,-1)),tuple((len(points)-1)*n+j for j in range(n))]
        fs += [(i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j) for i in range(len(points)-1) for j in range(n)]
        return mesh(name,vs,fs,color,mat,True)
    def cylinder(name,pos,r,depth,color,mat=2,segments=16):
        bpy.ops.mesh.primitive_cylinder_add(vertices=segments,radius=r,depth=depth,location=pos,rotation=(0,math.pi/2,0))
        o=bpy.context.object;o.name=name;adopt(o,color,mat)
        mod=o.modifiers.new('Tire shoulder','BEVEL');mod.width=.015;mod.segments=1
        o.modifiers.new('Wheel normals','WEIGHTED_NORMAL');return o

    # One continuous body. Each longitudinal section shares the same roof/side topology.
    # y, half-width, upper side shoulder, roof height. Front low hood flows into cabin.
    sections=[(-2.64,.80,1.04,1.16),(-2.59,.88,1.07,1.19),(-2.47,.955,1.11,1.255),
              (-2.30,.980,1.21,1.345),(-2.12,.982,1.30,1.435),(-2.02,.982,1.40,1.535),
              (-1.86,.982,1.64,1.77),(-1.66,.982,1.89,2.02),(-1.47,.982,2.04,2.19),
              (-1.30,.982,2.10,2.27),(-1.10,.982,2.14,2.285),(-.65,.982,2.14,2.285),
              (.15,.982,2.14,2.285),(1.40,.982,2.14,2.285),(2.38,.982,2.14,2.285),
              (2.62,.94,2.09,2.24),(2.66,.90,2.02,2.16)]
    def cross(w,shoulder,h):
        # Rolled roof shoulders use real quarter-circle sections rather than
        # a single chamfer. Keep the broad roof crown and straight cargo walls.
        radius=min(.18,max(.08,h-shoulder+.04))
        crown=.075 if h>2.20 else .065
        edge_top=h-crown
        side=w*.976;belt=min(1.06,edge_top-radius-.20)
        half=[(-w,.53),(-w,belt),(-w*.995,edge_top-radius-.06)]
        half += [(-side+radius-radius*math.cos(a),edge_top-radius+radius*math.sin(a))
                 for a in [i*math.pi/12 for i in range(7)]]
        half += [(-w*.63,h-crown*.42),(-w*.32,h-crown*.10)]
        return half+[(0,h)]+[(-x,z) for x,z in reversed(half)]
    vs=[(x,y,z) for y,w,s,h in sections for x,z in cross(w,s,h)];n=len(cross(.98,2.14,2.285))
    fs=[tuple(range(n-1,-1,-1)),tuple((len(sections)-1)*n+j for j in range(n))]
    fs += [(i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j) for i in range(len(sections)-1) for j in range(n)]
    shell=mesh('Continuous crowned panel-van shell',vs,fs,'paint',smooth=True)
    def section_at(y):
        for a,b in zip(sections,sections[1:]):
            if a[0]<=y<=b[0]:
                t=(y-a[0])/(b[0]-a[0])
                return [a[i]+t*(b[i]-a[i]) for i in range(1,4)]
        return list(sections[0 if y<sections[0][0] else -1][1:])
    def upper_surface(x,y):
        pts=cross(*section_at(y));half=len(pts)//2
        # Crown and rolled shoulders, ordered across X.
        upper=pts[3:-3]
        for a,b in zip(upper,upper[1:]):
            if a[0]<=x<=b[0]:
                t=(x-a[0])/(b[0]-a[0]);return a[1]+t*(b[1]-a[1])
        return pts[half][1]
    def side_surface(y,z):
        pts=cross(*section_at(y));half=pts[:len(pts)//2+1]
        for a,b in zip(half,half[1:]):
            if a[1]<=z<=b[1] and b[1]>a[1]:
                t=(z-a[1])/(b[1]-a[1]);return -(a[0]+t*(b[0]-a[0]))
        return .97
    def rounded_polygon(points,r):
        out=[]
        for i,p in enumerate(points):
            p=Vector(p);prev=Vector(points[i-1]);nxt=Vector(points[(i+1)%len(points)])
            a=p+(prev-p).normalized()*min(r,(prev-p).length*.3)
            b=p+(nxt-p).normalized()*min(r,(nxt-p).length*.3)
            for j in range(5):
                t=j/4;out.append((1-t)**2*a+2*(1-t)*t*p+t*t*b)
        return out
    # Real open wheel arches, not black circles pasted over bodywork.
    for y in [-1.76,1.14]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=.445,depth=2.6,location=(0,y,.385),rotation=(0,math.pi/2,0))
        cutter=bpy.context.object
        bpy.context.view_layer.objects.active=shell
        mod=shell.modifiers.new('Wheel aperture','BOOLEAN');mod.operation='DIFFERENCE';mod.object=cutter
        bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cutter,do_unlink=True)
    # Cutters create new loops; reassign palette after construction.
    for c in shell.data.color_attributes['Color'].data:c.color=linear(COLORS['paint'])
    bevel=shell.modifiers.new('Soft pressed-metal corners','BEVEL')
    bevel.width=.05;bevel.segments=3;bevel.limit_method='ANGLE';bevel.angle_limit=.60
    shell.modifiers.new('Broad panel normals','WEIGHTED_NORMAL')
    box('Underbody',(0,0,.43),(1.56,4.8,.19),'rubber',.02)
    for y in [-1.76,1.14]:
        for side in [-1,1]:
            xs=[side*.85] if y<0 else [side*.69,side*.88]
            for x in xs:cylinder('Commercial tire',(x,y,.38),.38,.19,'rubber',segments=20)
            x=side*(.965 if y<0 else .985)
            cylinder('Steel wheel',(x,y,.38),.225,.025,'steel')
            cylinder('Recessed hub',(x+side*.018,y,.38),.135,.028,'dark')
            cylinder('Hub cap',(x+side*.035,y,.38),.095,.035,'steel',segments=16)
            for j in range(6):
                a=j*math.tau/6
                cylinder('Wheel vent',(x+side*.018,y+math.sin(a)*.177,.38+math.cos(a)*.177),.028,.012,'dark',segments=6)
            # Painted rolled lip follows the actual arch.
            line('Wheel arch lip',[(side*.989,y+math.cos(a)*.451,.385+math.sin(a)*.451) for a in [i*math.pi/20 for i in range(21)]],.020,'panel',0)
            box('Mudflap',(side*.87,y+.39,.31),(.22,.035,.38),'rubber',.003)
    # Windshield sampled on the actual sloping front upper surface.
    def wind(u,v,offset=0):
        y=-2.09+.59*v;width=.86-.025*v
        # Rounded corners and crown sampled from the same body surface.
        corner=.09
        d=min(v,1-v)
        inset=corner-math.sqrt(max(0,corner*corner-(corner-d)**2)) if d<corner else 0
        x=u*(width-inset)
        return (x,y-.012-offset,upper_surface(x,y)+.017)
    verts=[wind(-1+2*i/16,j/10) for j in range(11) for i in range(17)]
    faces=[(j*17+i,j*17+i+1,(j+1)*17+i+1,(j+1)*17+i) for j in range(10) for i in range(16)]
    mesh('Broad single-piece windshield',verts,faces,'glass',1)
    border=[wind(-1+2*i/16,0,.005) for i in range(17)]+[wind(1,j/10,.005) for j in range(1,11)]+[wind(1-2*i/16,1,.005) for i in range(1,17)]+[wind(-1,1-j/10,.005) for j in range(1,11)]
    line('Windshield rubber',border+[border[0]],.018,'rubber')
    for x in [-.43,.36]:
        line('Wiper arm',[(x,-2.12,1.46),(x+.20,-2.02,1.56)],.010,'rubber')
        line('Wiper blade',[(x-.07,-2.04,1.53),(x+.36,-2.04,1.53)],.012,'rubber')
    for side in [-1,1]:
        # Side glass inset above beltline, with strongly raked leading edge.
        contour=rounded_polygon([(-1.99,1.41),(-1.45,2.075),(-.79,2.09),(-.70,2.025),(-.70,1.41)],.07)
        pts=[(side*(side_surface(y,z)+.012),y,z) for y,z in contour]
        # Sample every ring on the shell: a flat polygon would cut through the
        # rolled shoulder and expose body paint in the middle of the glass.
        center=sum(contour,Vector((0,0)))/len(contour)
        def glass_point(p):
            y,z=p
            return (side*(side_surface(y,z)+.018),y,z)
        gv=[glass_point(center)];gf=[];count=len(contour)
        for ring in range(1,6):
            t=ring/5
            gv.extend(glass_point(center+(p-center)*t) for p in contour)
            start=1+(ring-1)*count
            if ring==1:
                gf.extend((0,start+i,start+(i+1)%count) for i in range(count))
            else:
                prev=start-count
                gf.extend((prev+i,prev+(i+1)%count,start+(i+1)%count,start+i) for i in range(count))
        mesh('Cab door glass',gv,gf,'glass',1,True)
        line('Door window gasket',pts+[pts[0]],.017,'rubber')
        line('Quarterlight divider',[(side*(side_surface(-1.76,1.43)+.021),-1.76,1.43),
                                     (side*(side_surface(-1.42,2.06)+.021),-1.42,2.06)],.011,'rubber')
        door=[(side*.995,-2.03,1.35),(side*.997,-.65,1.35),(side*.997,-.65,.57),(side*.997,-1.28,.57)]
        line('Cab door shut line',door,.007,'seam')
        box('Cab door handle',(side*1.006,-.83,1.19),(.026,.17,.043),'rubber',.009)
        box('Side indicator',(side*1.00,-2.12,1.20),(.026,.105,.045),'amber',.009)
        # Stamped window blanks distinguish a cargo van from a smooth box.
        for start,end in [(-.49,.77),(.88,2.03),(2.13,2.48)]:
            contour=rounded_polygon([(start,1.40),(start,2.015),(end,2.015),(end,1.40)],.07)
            outer=[(side*(side_surface(y,z)+.004),y,z) for y,z in contour]
            # Broad shallow pressed fields, with a narrow paint-colour rolled rim.
            mesh('Shallow cargo pressing',outer,[tuple(range(len(outer)))],'panel',0)
            line('Soft cargo pressing edge',outer+[outer[0]],.006,'paint',0)
        line('Body belt pressing',[(side*.988,-.54,1.20),(side*.992,2.49,1.20)],.014,'panel',0)
        line('Lower flank pressing',[(side*.993,-1.31,.75),(side*.993,.72,.75)],.009,'panel',0)
        line('Roof rain gutter',[(side*.971,-1.31,2.12),(side*.978,2.44,2.12)],.014,'panel',0)
        if side==1:
            line('Sliding door seam',[(1.002,-.56,.58),(1.002,-.56,2.10),(1.002,1.0,2.10),(1.002,1.0,.84)],.007,'seam')
            line('Sliding door rail',[(1.004,.78,1.22),(1.004,2.43,1.22)],.015,'dark')
            box('Cargo handle',(1.016,-.38,1.24),(.024,.052,.13),'rubber',.008)
        line('Mirror stalk',[(side*.99,-1.65,1.42),(side*1.16,-1.74,1.42)],.018,'rubber')
        box('Period mirror',(side*1.18,-1.78,1.48),(.125,.14,.27),'rubber',.042)
        box('Mirror glass',(side*1.18,-1.704,1.48),(.091,.008,.217),'glass',.015,1)
    # Early front: small rectangular headlights; two-row grille, no modern teardrops.
    box('Front bumper',(0,-2.64,.595),(1.90,.29,.31),'rubber',.10,segments=4)
    for side in [-1,1]:
        box('Bumper wraparound',(side*.914,-2.48,.595),(.15,.42,.29),'rubber',.065,segments=3)
    box('Front lower valance',(0,-2.61,.415),(1.67,.12,.06),'paint',.025,0)
    box('Radiator opening',(0,-2.655,.92),(1.03,.025,.255),'rubber',.027)
    for x in [-.53,.53]:box('Grille outer upright',(x,-2.677,.92),(.025,.024,.26),'steel',.006)
    for z in [.80,.92,1.04]:box('Grille horizontal bar',(0,-2.680,z),(1.07,.025,.018),'steel',.004)
    for i in range(-5,6):box('Grille vertical bar',(i*.095,-2.683,.92),(.014,.02,.25),'steel',.003)
    for side in [-1,1]:
        box('Headlight gasket',(side*.733,-2.623,.925),(.376,.04,.254),'rubber',.025)
        box('Rectangular headlamp',(side*.704,-2.648,.928),(.267,.026,.204),'lamp',.018)
        box('Corner indicator',(side*.895,-2.60,.928),(.083,.045,.204),'amber',.015)
        for x in [.64,.70,.76]:box('Lamp fluting',(side*x,-2.664,.93),(.007,.006,.17),'steel',.002)
    box('Blank front plate',(0,-2.792,.605),(.43,.012,.105),'lamp',.008)
    # Bonnet seam and cowl vents; no exaggerated damage or modern accessories.
    line('Bonnet leading seam',[(x,-2.57,upper_surface(x,-2.57)+.009) for x in [-.75,-.5,0,.5,.75]],.006,'seam')
    for x in [-.43,.43]:box('Cowl vent',(x,-2.11,upper_surface(x,-2.11)+.015),(.37,.07,.012),'rubber',.009)
    # Two unglazed rear cargo doors, modest stacked rear lamps and step bumper.
    for side in [-1,1]:
        x=side*.45
        box('Rear door upper pressing',(x,2.671,1.71),(.74,.014,.59),'panel',.045,0)
        box('Rear door inner field',(x,2.684,1.71),(.68,.008,.53),'paint',.04,0)
        for z in [.89,1.97]:box('Rear hinge',(side*.87,2.684,z),(.095,.036,.045),'steel',.008)
        box('Rear lamp surround',(side*.88,2.665,.92),(.115,.044,.36),'rubber',.016)
        for z,color in [(.81,'lamp'),(.92,'red'),(1.03,'amber')]:
            box('Rear lamp',(side*.88,2.692,z),(.087,.022,.092),color,.008)
    line('Rear central door gap',[(0,2.691,.56),(0,2.691,2.10)],.008,'seam')
    line('Rear door base gap',[(-.78,2.687,.62),(.78,2.687,.62)],.007,'seam')
    box('Rear handle',(.11,2.705,1.17),(.15,.027,.043),'rubber',.008)
    box('Rear bumper',(0,2.68,.49),(1.96,.14,.14),'dark',.03)
    box('Blank rear plate',(-.30,2.71,.83),(.43,.012,.105),'lamp',.008)
    bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'gazelle_2705.blend'))
    print('GAZELLE_BUILD_DONE',len(root.children))

if __name__=='__main__':build()
