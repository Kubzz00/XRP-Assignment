extends Node3D

@export var seed_scene: PackedScene
@export var max_seeds: int = 2
@export var spawn_offset: Vector3 = Vector3(0, 0.2, 0)

var spawned_seeds: Array = []

func _ready():
	# Load seed scene if not assigned
	if not seed_scene:
		seed_scene = load("res://Scenes/seed.tscn")
	
	# Connect button press detection
	$ButtonArea.area_entered.connect(_on_button_pressed)
	
	print("✅ Seed Spawner ready! Max seeds: ", max_seeds)

func _on_button_pressed(area: Area3D):
	# Check if it's a hand touching the button
	if "Hand" in area.name:
		print("Button pressed by hand!")
		spawn_seed()

func spawn_seed():
	# Clean up invalid seeds from array
	spawned_seeds = spawned_seeds.filter(func(s): return is_instance_valid(s))
	
	# Check if max seeds reached
	if spawned_seeds.size() >= max_seeds:
		print("❌ Max seeds reached! (", max_seeds, ")")
		return
	
	# Check if seed scene exists
	if not seed_scene:
		print("❌ No seed scene assigned!")
		return
	
	# SPAWN THE SEED!
	var new_seed = seed_scene.instantiate()
	get_parent().add_child(new_seed)
	new_seed.global_position = global_position + spawn_offset
	
	spawned_seeds.append(new_seed)
	
	print("🌱 Seed spawned! Total seeds: ", spawned_seeds.size(), "/", max_seeds)
	
	# Visual feedback - button press animation
	animate_button()

func animate_button():
	var button = $ButtonMesh
	var original_y = button.position.y
	
	var tween = create_tween()
	tween.tween_property(button, "position:y", original_y - 0.02, 0.1)
	tween.tween_property(button, "position:y", original_y, 0.1)
