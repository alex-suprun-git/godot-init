"""Prepare isolated preview using this export and the current game benchmarks."""
from pathlib import Path
import shutil
here=Path(__file__).resolve().parent
root=here.parents[2]
target=here/'preview_project/models';target.mkdir(parents=True,exist_ok=True)
for name in ['gazelle_2705','gazelle_2705_blue','gazelle_2705_sand']:
    shutil.copy2(here/f'{name}.glb',target/f'{name}.glb')
for name in ['volga_gaz24','truck_zil_flatbed']:
    shutil.copy2(root/'init/assets/models/vehicles'/f'{name}.glb',target/f'{name}.glb')
print(target.parent)
