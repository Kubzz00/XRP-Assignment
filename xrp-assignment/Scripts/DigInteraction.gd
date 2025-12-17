extends Area3D
class_name DigInteraction

# Plot states
var is_dug: bool = false
var can_plant: bool = false
var is_planted: bool = false
var is_watered: bool = false   # watered state

# Hand detection
var hand_inside: bool = false

# Visual reference
@export var visual_mesh: MeshInstance3D
@export var particle_scene: PackedScene

# Reference to state label
var state_label: Label3D

# Signals
signal plot_dug
signal ready_to_plant
signal seed_planted

# Colors for different states
var color_original = Color(0.3, 0.15, 0.05)
var color_dug      = Color(0.2, 0.12, 0.06)
var color_planted  = Color(0.25, 0.18, 0.1)

func _ready():
	print("DigInteraction ready on: ", get_parent().name)
	
	if not visual_mesh and get_parent().has_node("PlotVisual"):
		visual_mesh = get_parent().get_node("PlotVisual")
		print("Found PlotVisual automatically\n")
	
	# Find the StateUpdate label
	state_label = get_tree().root.find_child("StateUpdate", true, false)
	if state_label:
		print("✅ StateUpdate label found!")
	else:
		print("⚠️ StateUpdate label not found!")
	
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	set_plot_color(color_original)

func _on_area_entered(area: Area3D):
	print("🔍 Plot detected area: ", area.name)
	if area.get_parent():
		print("   Parent: ", area.get_parent().name)
	
	# Hand for digging
	if "Hand" in area.name and not is_dug:
		hand_inside = true
		print("Hand entered plot area!")
		try_dig()
	
	# Seed for planting
	elif "SeedDetector" in area.name and is_dug and not is_planted:
		print("🌱 Seed detected over plot!")
		plant_seed(area)
	
	# Watering can for watering (kept in case you wire it later)
	elif "Water" in area.name and is_planted and not is_watered:
		print("💧 Watering thing detected over plot!")
		on_watered(area)

func _on_area_exited(area: Area3D):
	if "Hand" in area.name:
		hand_inside = false
		print("Hand left plot area\n")

func try_dig():
	if not is_dug:
		perform_dig()
	else:
		print("Plot already dug!\n")

func perform_dig():
	is_dug = true
	can_plant = true
	is_planted = false
	is_watered = false
	
	print("✅ PLOT DUG! Ready for planting\n")
	
	update_state_label("Dug a plot!")
	set_plot_color(color_dug)
	
	spawn_dig_particles()
	play_dig_animation()
	
	plot_dug.emit()
	ready_to_plant.emit()

func plant_seed(seed_area: Area3D) -> void:
	if not can_plant:
		print("❌ Plot not ready for planting!")
		return
	
	is_planted = true
	can_plant = false
	is_watered = false   # reset when new seed planted
	
	print("✅ SEED PLANTED!\n")
	set_plot_color(color_planted)
	
	update_state_label("Seed planted in plot!")
	
	# Remove the seed from the scene
	var seed_node = seed_area.get_parent()
	if is_instance_valid(seed_node):
		seed_node.queue_free()
		print("🗑️ Seed removed from scene")
	
	seed_planted.emit()
	
	# Wait 1 second, then prompt watering
	await get_tree().create_timer(1.0).timeout
	update_state_label("Ready to water plot!")

# Watered state + message (optional, if/when you hook watering up again)
func on_watered(water_area: Area3D):
	is_watered = true
	print("✅ Plot has been watered!")
	
	update_state_label("Plot watered! Growth starting...")

func update_state_label(message: String):
	if state_label:
		state_label.text = message
		print("📝 Status: ", message)

func set_plot_color(new_color: Color):
	if visual_mesh:
		var material = visual_mesh.get_active_material(0)
		if material:
			material.albedo_color = new_color
			print("🎨 Plot color changed")
		else:
			print("⚠️ No material on visual_mesh")
	else:
		print("⚠️ visual_mesh not assigned")

func spawn_dig_particles():
	if not particle_scene:
		particle_scene = load("res://Scenes/dig_particles.tscn")
	
	if not particle_scene:
		return
	
	var particles = particle_scene.instantiate()
	var scene_root = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
	scene_root.add_child(particles)
	
	var plot = self
	particles.global_position = plot.global_position + Vector3(0, 0.1, 0)
	particles.emitting = true
	
	cleanup_particles(particles)

func cleanup_particles(particle_node):
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(particle_node):
		particle_node.queue_free()

func play_dig_animation():
	var plot = self
	var original_scale = plot.scale
	var tween = create_tween()
	tween.tween_property(plot, "scale", original_scale * 0.9, 0.1)
	tween.tween_property(plot, "scale", original_scale, 0.1)
	#pass
