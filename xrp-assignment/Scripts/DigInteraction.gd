'''extends Area3D
class_name DigInteraction

# Plot state
var is_dug : bool = false
var can_plant : bool = false

# Hand detection
var hand_inside : bool = false

# Visual reference - we'll assign this in the editor
@export var visual_mesh : MeshInstance3D

# NEW: Particle scene reference
@export var particle_scene: PackedScene

# Signals for other systems to listen to
signal plot_dug
signal ready_to_plant

func _ready():
	print("DigInteraction ready on: ", get_parent().name)
	
	# Try to find visual mesh if not assigned
	if not visual_mesh and get_parent().has_node("PlotVisual"):
		visual_mesh = get_parent().get_node("PlotVisual")
		print("Found PlotVisual automatically\n")
	
	# Connect signals for collision detection
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

# Called when another Area3D enters this one
func _on_area_entered(area: Area3D):
	print("Area entered: ", area.name)
	
	# Check if it's a hand area
	if "Hand" in area.name:
		hand_inside = true
		print("Hand entered plot area!")
		
		# Try to dig immediately when hand enters
		try_dig()

# Called when area exits
func _on_area_exited(area: Area3D):
	if "Hand" in area.name:
		hand_inside = false
		print("Hand left plot area\n\n")

# Attempt to dig the plot
func try_dig():
	if not is_dug:
		perform_dig()
	else:
		print("Plot already dug!\n\n")

# Actually perform the digging
func perform_dig():
	is_dug = true
	can_plant = true
	
	print("PLOT DUG! Ready for planting\n\n")
	
	# Change visual appearance
	change_plot_appearance()
	
	# NEW: Add particle effect
	spawn_dig_particles()
	
	# NEW: Add animation
	play_dig_animation()
	
	# Emit signals
	plot_dug.emit()
	ready_to_plant.emit()

# Make the plot look "dug up"
func change_plot_appearance():
	if visual_mesh:
		# Get the material
		var material = visual_mesh.get_active_material(0)
		
		if material:
			# Make it darker brown (dug soil)
			material.albedo_color = Color(0.2, 0.12, 0.06)
			print("Plot appearance changed to dug state\n")
		else:
			print("Warning: No material found on visual mesh\n")
	else:
		print("Warning: visual_mesh not assigned\n")

# Spawn dirt particles when digging (SAFE VERSION)
func spawn_dig_particles():
	# Load particle scene if not assigned
	var particles_to_spawn = particle_scene
	if not particles_to_spawn:
		particles_to_spawn = load("res://Scenes/dig_particles.tscn")
	
	if not particles_to_spawn:
		print("❌ No particle scene found!")
		return
	
	# Create instance
	var particles = particles_to_spawn.instantiate()
	
	# Add particles to the scene root or a safe parent, NOT to the plot!
	# Get the main scene root
	var scene_root = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
	scene_root.add_child(particles)
	
	# Position at plot surface using global position
	var plot = get_parent()
	particles.global_position = plot.global_position + Vector3(0, 0.1, 0)
	
	# Start emitting
	particles.emitting = true
	
	print("✓ Dirt particles spawned (safe method)")
	
	# Clean up particles safely - store reference separately
	cleanup_particles(particles)

# Separate function to safely clean up ONLY particles
func cleanup_particles(particle_node: GPUParticles3D):
	await get_tree().create_timer(2.0).timeout
	
	# Triple-check we're deleting the right thing
	if is_instance_valid(particle_node):
		if particle_node.name == "DigParticles":
			particle_node.queue_free()
			print("✓ Particles cleaned up safely")
		else:
			print("⚠️ Attempted to delete wrong node!")

# NEW: Animate plot sinking when dug
func play_dig_animation():
	var plot = get_parent()
	var original_pos = plot.position
	var target_pos = original_pos + Vector3(0, -0.03, 0)  # Sink 3cm down
	
	# Create bounce animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(plot, "position", target_pos, 0.4)
	
	print("✓ Dig animation played\n")

# Check if plot is ready for planting
func can_be_planted() -> bool:
	return is_dug and can_plant

# Reset the plot (for testing)
func reset_plot():
	is_dug = false
	can_plant = false
	
	if visual_mesh:
		var material = visual_mesh.get_active_material(0)
		if material:
			material.albedo_color = Color(0.3, 0.15, 0.05) # Original brown
'''
extends Area3D
class_name DigInteraction

# Plot states
var is_dug: bool = false
var can_plant: bool = false
var is_planted: bool = false

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
var color_original = Color(0.3, 0.15, 0.05)  # default soil
var color_dug      = Color(0.2, 0.12, 0.06)  # when dug
var color_planted  = Color(0.25, 0.18, 0.1)  # when seed planted

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
	
	# Ensure starting color
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
	
	print("✅ PLOT DUG! Ready for planting\n")
	
	update_state_label("Dug a plot!")
	set_plot_color(color_dug)  # NEW
	
	spawn_dig_particles()
	play_dig_animation()
	
	plot_dug.emit()
	ready_to_plant.emit()

func plant_seed(seed_area: Area3D):
	if not can_plant:
		print("❌ Plot not ready for planting!")
		return
	
	is_planted = true
	can_plant = false
	
	print("✅ SEED PLANTED!\n")
	set_plot_color(color_planted)  # NEW
	
	update_state_label("Seed planted in plot!")
	
	# Remove the seed from the scene
	var seed_node = seed_area.get_parent()
	if is_instance_valid(seed_node):
		seed_node.queue_free()
		print("🗑️ Seed removed from scene")
	
	seed_planted.emit()

func update_state_label(message: String):
	if state_label:
		state_label.text = message
		print("📝 Status: ", message)

# Change soil color safely
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
