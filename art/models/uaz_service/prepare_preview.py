"""Copy actual exports/benchmarks into an isolated Godot preview project."""
from pathlib import Path
import shutil

root=Path(__file__).resolve().parents[3]
target=Path(__file__).parent/'preview_project/models'
target.mkdir(parents=True,exist_ok=True)
for name in ['uaz_police.glb','raf_ambulance.glb','volga_gaz24.glb','bus_paz_3205.glb','truck_zil_flatbed.glb']:
    shutil.copy2(root/'init/assets/models/vehicles'/name,target/name)
print(target.parent)
