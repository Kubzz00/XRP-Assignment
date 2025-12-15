extends Area3D
class_name DigInteraction

# Plot state
var is_dug : bool = false
var can_plant : bool = false

# Hand detection
var hand_inside : bool = false

# Visual reference - we'll assign this in the editor
@export var visual_mesh : MeshInstance3D

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
