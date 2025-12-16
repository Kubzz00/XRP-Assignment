extends StaticBody3D
class_name SeedSpawner

@export var seed_scene: PackedScene
@export var max_seeds: int = 2
@export var spawn_height: float = 0.15

var spawned_count: int = 0
var touch_detector: Area3D

func _ready():
	print("🌱 SeedSpawner ready!")
	
	if not seed_scene:
		seed_scene = load("res://Scenes/newSeed.tscn")
	
	# NEW: Test if scene loads
	if seed_scene:
		print("✅ Seed scene loaded successfully!")
	else:
		print("❌ FAILED to load seed scene!")
	
	touch_detector = $TouchDetector
	if touch_detector:
		touch_detector.area_entered.connect(_on_hand_touch)
		print("✅ Touch detector connected")
	else:
		print("❌ TouchDetector not found!")

func _on_hand_touch(area: Area3D):
	if "Hand" in area.name:
		print("👋 Hand touched button!")
		spawn_seed()

func spawn_seed():
	if spawned_count >= max_seeds:
		print("❌ Max seeds reached! (", spawned_count, "/", max_seeds, ")")
		return
	
	if not seed_scene:
		print("❌ No seed scene!")
		return
	
	var seed = seed_scene.instantiate()
	get_tree().root.get_child(get_tree().root.get_child_count() - 1).add_child(seed)
	seed.global_position = global_position + Vector3(0, spawn_height, 0)
	
	spawned_count += 1
	print("✅ Seed #", spawned_count, " spawned!")
	
	flash_button()

func flash_button():
	var mesh = $ButtonMesh
	if mesh:
		var tween = create_tween()
		tween.tween_property(mesh, "scale", Vector3(1.2, 1.2, 1.2), 0.1)
		tween.tween_property(mesh, "scale", Vector3(1, 1, 1), 0.1)
