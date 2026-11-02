from pathlib import Path
import runpy

helper = Path(__file__).resolve().parents[1]/'uaz_service/vehicle_build.py'
runpy.run_path(str(helper))['build']('raf')
