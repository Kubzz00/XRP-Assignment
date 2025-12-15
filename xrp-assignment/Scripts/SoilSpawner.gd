extends Area3D
class_name SoilBedSpawner

# Reference to the plot scene to spawn
@export var plot_scene: PackedScene

# Track spawned plots
var spawned_plots: Array = []

# Cooldown to prevent multiple spawns
var spawn_cooldown: float = 0.5
var can_spawn: bool = true

func _ready():
	print("SoilBedSpawner ready!\n\n")
	
	# Load plot scene if not assigned
	if not plot_scene:
		plot_scene = load("res://Scenes/planting_plot.tscn")
	
	# Connect collision signals
	area_entered.connect(_on_hand_entered)

func _on_hand_entered(area: Area3D):
	print("Hand detected: ", area.name)
	
	# Check if it's a hand area
	if "Hand" in area.name and can_spawn:
		spawn_plot(area.global_position)

func spawn_plot(spawn_position: Vector3):
	if not plot_scene:
		print("No plot scene assigned!")
		return
	
	# Create new plot instance
	var new_plot = plot_scene.instantiate()
	
	# Add to scene (as child of parent, not self)
	get_parent().add_child(new_plot)
	
	# Position it where hand touched
	new_plot.global_position = spawn_position
	new_plot.global_position.y = get_parent().global_position.y # On Soil
	
	# Track it
	spawned_plots.append(new_plot)
	
	print("Plot spawned at: ", new_plot.global_position)
	print("Total plots: ", spawned_plots.size())
	
	# Start cooldown
	start_cooldown()

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
	
	'''
	extends Area3D
class_name SoilBedSpawner

# Reference to the plot scene to spawn
@export var plot_scene: PackedScene

# Track spawned plots
var spawned_plots: Array = []

# Cooldown to prevent multiple spawns
@export var spawn_cooldown: float = 0.5
var can_spawn: bool = false  # Start disabled

# Y offset for plot depth in soil
@export var spawn_y_offset: float = -0.15

# Startup delay
@export var startup_delay: float = 5.0

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
	print("✅ Spawning enabled!")

func _on_hand_entered(area: Area3D):
	if not can_spawn:
		return
	
	print("Hand detected: ", area.name)
	
	# Check if it's a hand area
	if "Hand" in area.name:
		spawn_plot(area.global_position)

func spawn_plot(spawn_position: Vector3):
	if not plot_scene:
		print("No plot scene assigned!")
		return
	
	# Create new plot instance
	var new_plot = plot_scene.instantiate()
	
	# Add to scene (as child of parent, not self)
	get_parent().add_child(new_plot)
	
	# Position it where hand touched
	new_plot.global_position = spawn_position
	new_plot.global_position.y = spawn_position.y + spawn_y_offset
	
	# Track it
	spawned_plots.append(new_plot)
	
	print("✅ Plot spawned at: ", new_plot.global_position)
	print("📊 Total plots: ", spawned_plots.size())
	
	# Start cooldown
	start_cooldown()

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
	print("🗑️ All plots cleared")

	'''
