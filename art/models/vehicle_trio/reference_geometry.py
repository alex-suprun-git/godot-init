"""Prototype-specific metre landmarks; provenance in README.md.

length is the construction span BEFORE bumper/spare extensions. Roof/window
positions are interpreted from real photographs, not certified drawing values.
"""
TARGETS = {
 'luxury_suv': dict(overall_length=4.490,body_width=1.800,height=1.970,wheelbase=2.850,
  tracks=(1.475,1.475),tire_width=.265,rim_radius=.2032,
  length=4.113,width=1.800,axles=(-1.385,1.465),radius=.3887,paint='252D32',belt=1.265,
  roof_front=-.72,roof_rear=1.900,roof_width=.795,cabin_front=-.99,cabin_rear=1.965,roof_edge=1.880,crown=.060,
  windows=[(-.875,-.685,.10,.10),(.185,.185,.94,.94),(1.035,1.035,1.825,1.810)],
  doors=[(-.92,.15),(.15,1.015)],handles=[-.035,.845],
  deck=[(-2.10,1.200),(-1.35,1.235),(-.99,1.265),(1.965,1.265),(2.10,1.265)]),
 'luxury_sedan': dict(overall_length=5.213,body_width=1.886,height=1.486,wheelbase=3.140,
  tracks=(1.606,1.579),tire_width=.235,rim_radius=.2032,
  length=4.985,width=1.886,axles=(-1.550,1.590),radius=.3442,paint='451B29',belt=1.035,
  roof_front=-.64,roof_rear=1.145,roof_width=.755,cabin_front=-1.175,cabin_rear=1.775,roof_edge=1.425,crown=.049,
  windows=[(-1.075,-.595,.16,.16),(.245,.245,1.545,1.105)],
  doors=[(-1.145,.20),(.20,1.59)],handles=[.005,1.29],
  deck=[(-2.50,.905),(-1.72,.96),(-1.175,1.035),(1.775,1.035),(2.50,.955)]),
 'rural_4x4': dict(overall_length=3.720,body_width=1.680,height=1.640,wheelbase=2.200,
  tracks=(1.430,1.400),tire_width=.175,rim_radius=.2032,
  length=3.492,width=1.680,axles=(-1.070,1.130),radius=.334,paint='717650',belt=1.055,
  roof_front=-.405,roof_rear=1.340,roof_width=.690,cabin_front=-.855,cabin_rear=1.635,roof_edge=1.590,crown=.042,
  windows=[(-.755,-.375,.39,.39),(.485,.485,1.495,1.285)],doors=[(-.795,.44)],handles=[.255],
  deck=[(-1.80,.960),(-1.30,1.005),(-.855,1.055),(1.635,1.055),(1.80,1.020)]),
}

def interpolate(points,y):
 for a,b in zip(points,points[1:]):
  if y<=b[0]:
   t=max(0,min(1,(y-a[0])/(b[0]-a[0])));return a[1]+(b[1]-a[1])*t
 return points[-1][1]
