extends Area3D
class_name digSystem

# Reference to the plot scene to spawn
@export var plot_scene: PackedScene

# Track spawned plots
var spawned_plots: Array = []

# Cooldown to prevent multiple spawns
@export var spawn_cooldown: float = 0.5
var can_spawn: bool = false  # Start disabled

# Y offset for plot depth in soil
@export var spawn_y_offset: float = 0.02

# Startup delay
@export var startup_delay: float = 5.0

# NEW: Max plots allowed
@export var max_plots: int = 2

# NEW: Minimum distance between plots (in meters)
@export var min_distance: float = 0.3

func _ready():
	print("SoilBedSpawner ready! Waiting ", startup_delay, " seconds...")
	
	# Load plot scene if not assigned
	if not plot_scene:
		plot_scene = load("res://Scenes/planting_plot.tscn")
	
	# Connect collision signals
	area_entered.connect(_on_hand_entered)
	
	# Wait before enabling spawning
	await get_tree().create_timer(startup_delay).timeout
	can_spawn = true
	print("✅ Spawning enabled! Max plots: ", max_plots, "\n")

func _on_hand_entered(area: Area3D):
	if not can_spawn:
		return
	
	print("Hand detected: ", area.name)
	
	# Check if it's a hand area
	if "Hand" in area.name:
		spawn_plot(area.global_position)

func spawn_plot(spawn_position: Vector3):
	if not plot_scene:
		print("❌ No plot scene assigned!")
		return
	
	# NEW: Check if max plots reached
	if spawned_plots.size() >= max_plots:
		print("❌ Max plots reached! (", max_plots, ") Can't spawn more!")
		return
	
	# NEW: Check distance from existing plots
	for existing_plot in spawned_plots:
		if is_instance_valid(existing_plot):
			var distance = existing_plot.global_position.distance_to(spawn_position)
			if distance < min_distance:
				print("Too close to existing plot! Distance: ", distance, "m (min: ", min_distance, "m)")
				return
	
	# Create new plot instance
	var new_plot = plot_scene.instantiate()
	get_parent().add_child(new_plot)
	new_plot.global_position = spawn_position
	new_plot.global_position.y = get_parent().global_position.y + spawn_y_offset
	
	spawned_plots.append(new_plot)
	
	# SPAWN PARTICLES HERE
	spawn_creation_particles(new_plot.global_position)
	
	print("Plot spawned at: ", new_plot.global_position)
	print("Total plots: ", spawned_plots.size(), "/", max_plots)
	start_cooldown()

func spawn_creation_particles(pos: Vector3):
	var particles = load("res://Scenes/dig_particles.tscn").instantiate()
	get_tree().root.get_child(get_tree().root.get_child_count() - 1).add_child(particles)
	particles.global_position = pos + Vector3(0, 0.1, 0)
	particles.emitting = true
	
	# Auto-delete after 2 seconds
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func start_cooldown():
	can_spawn = false
	await get_tree().create_timer(spawn_cooldown).timeout
	can_spawn = true

# Optional: Clear all plots (for testing)
func clear_all_plots():
	for plot in spawned_plots:
		if is_instance_valid(plot):
			plot.queue_free()
	spawned_plots.clear()
	print("All plots cleared")
