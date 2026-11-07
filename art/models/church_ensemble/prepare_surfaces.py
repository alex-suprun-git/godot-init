"""Extract authored atlas tiles; author portable roughness/normal response.
Run in Blender background, then run optimize_asset.py separately for every tile.
"""
from pathlib import Path
import bpy, numpy as np
ROOT = Path(__file__).resolve().parents[3]
HERE = ROOT / 'art/source_images/church_ensemble'
im = bpy.data.images.load(str(HERE/'materials-v1.png'), check_existing=False)
w,h = im.size
p = np.empty(w*h*4,dtype=np.float32); im.pixels.foreach_get(p)
p=p.reshape(h,w,4)
for name,c,r,rough in [('plaster',0,1,.88),('green_metal',1,1,.72),('limestone',0,0,.86),('wood',1,0,.82)]:
    a=p[r*(h//2):(r+1)*(h//2),c*(w//2):(c+1)*(w//2)].copy()
    th,tw=a.shape[:2]
    def save(suffix, pixels, noncolor=False):
        out=bpy.data.images.new(name+suffix,width=tw,height=th,alpha=True)
        if noncolor:out.colorspace_settings.name='Non-Color'
        out.pixels.foreach_set(pixels.ravel());out.file_format='PNG'
        out.filepath_raw=str(HERE/(name+suffix+'.png'));out.save()
    save('',a)
    yy,xx=np.mgrid[0:th,0:tw].astype(np.float32)
    grain=(np.sin(xx*1.7+np.sin(yy*.71))+np.sin(yy*2.13+xx*.43))*.5
    height=grain*(.00012 if name=='green_metal' else .0004)
    if name=='wood':height+=.0004*np.sin(xx*.4+np.sin(yy*.03))
    dy,dx=np.gradient(height,2/th,2/tw)
    n=np.stack([-dx,-dy,np.ones_like(dx)],axis=-1);n/=np.linalg.norm(n,axis=-1,keepdims=True)
    normal=np.ones_like(a);normal[:,:,:3]=n*.5+.5
    save('_normal',normal,True)
    roughness=np.ones_like(a);roughness[:,:,:3]=np.clip(rough+grain[:,:,None]*.025,0,1)
    save('_roughness',roughness,True)
    print('SURFACE_SOURCE',name,tw,th,flush=True)
