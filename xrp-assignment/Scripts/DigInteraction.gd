extends Area3D
class_name DigInteraction

# Plot state
var is_dug : bool = false
var can_plant : bool = false
var has_seed: bool = false

# Hand detection
var hand_inside : bool = false

# Visual reference - we'll assign this in the editor
@export var visual_mesh : MeshInstance3D

# NEW: Particle scene reference
@export var particle_scene: PackedScene

# Reference to global state display
var state_display: Node3D = null

# Signals for other systems to listen to
signal plot_dug
signal ready_to_plant
signal seed_planted

func _ready():
	print("DigInteraction ready on: ", get_parent().name)
	
	# Try to find visual mesh if not assigned
	if not visual_mesh and get_parent().has_node("PlotVisual"):
		visual_mesh = get_parent().get_node("PlotVisual")
		print("Found PlotVisual automatically\n")
	
	# Get reference to StateUpdate
	state_display = get_tree().root.get_node_or_null("FarmExperienceMain/Environment/StateUpdate")
	if not state_display:
		print("⚠️ StateUpdate not found!")
	
	# Connect signals for collision detection
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	body_entered.connect(_on_body_entered)

# Called when another Area3D enters this one
func _on_area_entered(area: Area3D):
	# Check if it's a hand area
	if "Hand" in area.name:
		hand_inside = true
		# Try to dig immediately when hand enters
		try_dig()

# Called when a RigidBody3D enters (SEEDS!)
func _on_body_entered(body: Node3D):
	print("Body entered: ", body.name)
	
	# Check if it's a seed
	if "Seed" in body.name:
		print("🌱 Seed detected in plot!")
		try_plant_seed(body)

# Called when area exits
func _on_area_exited(area: Area3D):
	if "Hand" in area.name:
		hand_inside = false

# Attempt to dig the plot
func try_dig():
	if not is_dug:
		perform_dig()

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
	
	# Update state display
	if state_display:
		state_display.show_plot_dug()
	
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

# Attempt to plant seed in plot
func try_plant_seed(seed_body: Node3D):
	print("Attempting to plant seed...")
	
	# Check if plot is dug first
	if not is_dug:
		print("❌ Plot must be dug before planting!")
		if state_display:
			state_display.show_error("Dig plot first!")
		return
	
	# Check if plot already has a seed
	if has_seed:
		print("❌ Plot already has a seed planted!")
		if state_display:
			state_display.show_error("Plot has seed already!")
		return
	
	# PLANT THE SEED!
	has_seed = true
	print("✅ SEED PLANTED IN PLOT!")
	
	# Make seed disappear immediately
	if seed_body and is_instance_valid(seed_body):
		seed_body.queue_free()
		print("🗑️ Seed removed from world")
	
	# Change plot color to lighter brown (seed is now in plot!)
	if visual_mesh:
		var material = visual_mesh.get_active_material(0)
		if material:
			material.albedo_color = Color(0.7, 0.5, 0.3)  # Lighter brown
			print("✅ Plot color changed to lighter brown")
	
	# Update state display
	if state_display:
		state_display.show_seed_planted()
	
	print("✅ Status: Seed in Plot\n")
	
	# Emit signal
	seed_planted.emit()

# Check if plot is ready for planting
func can_be_planted() -> bool:
	return is_dug and can_plant

# Reset the plot (for testing)
func reset_plot():
	is_dug = false
	can_plant = false
	has_seed = false
	
	if visual_mesh:
		var material = visual_mesh.get_active_material(0)
		if material:
			material.albedo_color = Color(0.3, 0.15, 0.05) # Original brown
