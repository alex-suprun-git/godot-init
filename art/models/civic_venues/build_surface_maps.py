"""Author portable tangent normal and roughness maps for the six v2 surfaces.

Native Blender material preparation, not a modification of the AI albedo source.
Metre-scale analytic height patterns match the atlas families; the normal map
contains no baked illumination. Run in Blender CLI, then optimize separately.
"""
from pathlib import Path
import bpy
import numpy as np
import json

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'art/source_images/civic_venues/pbr-v2'
OUT.mkdir(parents=True,exist_ok=True)
SIZE=512
y,x=np.mgrid[0:SIZE,0:SIZE].astype(np.float32)/SIZE
normal=np.ones((SIZE*2,SIZE*3,4),dtype=np.float32)
rough=np.ones_like(normal)
metadata=[]

def soft_edge(distance,width):
    return np.clip(distance/width,0,1)

def noise(scale):
    return (np.sin(x*scale*6.283+np.cos(y*scale*4.13))+
            np.sin(y*scale*5.17+np.sin(x*scale*3.77)))*.25

for tile in range(6):
    fine=noise(71)
    broad=noise(3)
    if tile==0:
        f=(x*4)%1
        seam=np.exp(-(np.minimum(f,1-f)/.023)**2)
        height=.008*seam+.0005*fine
        # Raised edges of two repaired felt rectangles, not broken roof holes.
        for cx,cy,w,h in [(.25,.25,.22,.12),(.71,.68,.32,.18)]:
            edge=np.minimum(w/2-np.abs(x-cx),h/2-np.abs(y-cy))
            height+=.003*soft_edge(edge,.006)
        base=.92
    elif tile==1:
        # Actual roof folds are modeled. A second strong bump fold caused moire
        # against those ridges at the map camera, so retain fine paint relief only.
        height=.00015*fine
        base=.82
    elif tile==2:
        row=np.floor(y*50)
        fx=(x*16+(row%2)*.5)%1
        fy=(y*50)%1
        mortar=np.minimum(np.minimum(fx,1-fx)*.25,np.minimum(fy,1-fy)*.08)
        height=.010*soft_edge(mortar,.006)+.0007*fine
        base=.84
    elif tile==3:
        height=.0005*fine+.0012*broad
        base=.88
    elif tile==4:
        fx=(x*5)%1;fy=(y*8)%1
        joint=np.minimum(np.minimum(fx,1-fx)*.8,np.minimum(fy,1-fy)*.5)
        height=.0035*soft_edge(joint,.005)+.0001*fine
        base=.28
    else:
        height=.0002*noise(5)
        base=.23
    dy,dx=np.gradient(height,4/SIZE,4/SIZE)
    n=np.stack([-dx,-dy,np.ones_like(dx)],axis=-1)
    n/=np.linalg.norm(n,axis=-1,keepdims=True)
    col=tile%3
    # Tiles0..2 are the image's top row; Blender pixels start bottom-left.
    row=1-tile//3
    ys=slice(row*SIZE,(row+1)*SIZE);xs=slice(col*SIZE,(col+1)*SIZE)
    normal[ys,xs,:3]=n*.5+.5
    r=np.clip(base+.065*broad+.022*fine,.12,.98)
    rough[ys,xs,:3]=r[:,:,None]
    metadata.append({'surface':tile,'physical_tile_m':4,'roughness_base':base})

for name,pixels in [('surfaces-normal-v2',normal),('surfaces-roughness-v2',rough)]:
    image=bpy.data.images.new(name,width=SIZE*3,height=SIZE*2,alpha=True)
    image.colorspace_settings.name='Non-Color'
    image.pixels.foreach_set(pixels.ravel())
    image.filepath_raw=str(OUT/(name+'.png'))
    image.file_format='PNG'
    image.save()
    print('SURFACE_MAP_SAVED',image.filepath_raw,flush=True)
(OUT/'technical-maps.json').write_text(json.dumps(metadata,indent=2),encoding='utf-8')
