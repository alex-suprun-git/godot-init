# Reusable moving access assembly: hinged/sliding leaves and hinged boom arms.
# set_open() may be driven by a location state or by an individual object event.
extends Node3D

const TRANSITION_SECONDS := 2.0
var _parts: Array[Dictionary] = []
var _tween: Tween
var _openness := 1.0
var openness: float:
	get:
		return _openness
	set(value):
		_openness = clampf(value,0.0,1.0)
		_apply_pose()

func add_hinged_leaf(scene: PackedScene, hinge: Vector3, width: float, side: float, angle: float) -> void:
	var leaf: Node3D = scene.instantiate()
	leaf.scale.x = width/4.5
	add_child(leaf)
	_parts.append({"kind": &"hinged", "node": leaf, "hinge": hinge,
		"offset": Vector3(side*width/2.0,0,0), "angle": side*angle})
	_apply_pose()

func add_sliding_leaf(scene: PackedScene, closed: Vector3, opened: Vector3, width: float) -> void:
	var leaf: Node3D = scene.instantiate()
	leaf.scale.x = width/4.5
	add_child(leaf)
	_parts.append({"kind": &"sliding", "node": leaf, "closed": closed, "opened": opened})
	_apply_pose()

func add_barrier(at: Vector3, length := 4.9) -> void:
	var housing := Node3D.new()
	housing.position = at
	add_child(housing)
	_box(housing,Vector3(0,.65,0),Vector3(.55,1.3,.55),Color("596b63"))
	_box(housing,Vector3(0,.07,0),Vector3(.68,.14,.68),Color("90988a"))
	var pivot := Node3D.new()
	pivot.name = "BoomPivot"
	pivot.position = Vector3(0,1.15,0)
	housing.add_child(pivot)
	var count := ceili(length/.45)
	var segment := length/count
	for i in count:
		_box(pivot,Vector3((i+.5)*segment,0,0),Vector3(segment,.14,.14),
			Color("c4c5b1") if i%2==0 else Color("a34432"))
	_box(pivot,Vector3(-.23,0,0),Vector3(.45,.24,.26),Color("596b63"))
	_parts.append({"kind": &"boom", "node": pivot, "angle": deg_to_rad(83.0)})
	_apply_pose()

func set_open(value: bool, animated := true) -> void:
	var target := 1.0 if value else 0.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if not animated or is_equal_approx(openness,target):
		openness = target
		return
	# Animation stays readable at x1/x2/x4 and can finish while game time is held.
	_tween = create_tween().set_ignore_time_scale(true)
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self,"openness",target,TRANSITION_SECONDS*absf(target-openness))

func _apply_pose() -> void:
	for part in _parts:
		var node: Node3D = part["node"]
		match part["kind"]:
			&"hinged":
				var angle: float = part["angle"]*openness
				node.rotation.y = angle
				node.position = part["hinge"]+Basis(Vector3.UP,angle)*part["offset"]
			&"sliding":
				var closed: Vector3 = part["closed"]
				node.position = closed.lerp(part["opened"],openness)
			&"boom":
				node.rotation.z = part["angle"]*openness

func _box(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = .75
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = at
	parent.add_child(node)
