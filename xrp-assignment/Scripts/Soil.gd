extends MeshInstance3D

var is_dug: bool = false
var has_seed: bool = false

# Reference to detector
@onready var detector = get_parent().get_node("Detector")

# Reference to state display
var state_display: Node3D = null

func _ready():
	# Get state display
	state_display = get_tree().root.get_node_or_null("FarmExperienceMain/Environment/StateUpdate")
	
	# Connect detector signals
	if detector:
		detector.area_entered.connect(_on_area_entered)
		detector.body_entered.connect(_on_body_entered)
		print("✅ Soilbed ready for farming!")
	else:
		print("❌ Detector not found!")

# When hand or seed area enters
func _on_area_entered(area: Area3D):
	print("Area entered soilbed: ", area.name)
	
	# Check if it's a hand
	if "Hand" in area.name and not is_dug:
		dig_soil()

# When seed body enters
func _on_body_entered(body: Node3D):
	print("Body entered soilbed: ", body.name)
	
	# Check if it's a seed
	if "Seed" in body.name:
		plant_seed(body)

# Dig the whole soilbed
func dig_soil():
	if is_dug:
		return
	
	is_dug = true
	print("🟤 SOILBED DUG! Whole table is ready for planting!")
	
	# Change whole soilbed to brown
	var material = get_active_material(0)
	if material:
		material.albedo_color = Color(0.3, 0.2, 0.1)  # Brown soil color
		print("✅ Soilbed changed to brown!")
	
	# Update state display
	if state_display:
		state_display.show_plot_dug()

# Plant seed in soilbed
func plant_seed(seed_body: Node3D):
	if not is_dug:
		print("❌ Dig the soil first!")
		if state_display:
			state_display.show_error("Dig soil first!")
		return
	
	if has_seed:
		print("❌ Soil already has a seed!")
		if state_display:
			state_display.show_error("Already has seed!")
		return
	
	# Plant the seed!
	has_seed = true
	print("🌱✅ SEED IN PLOT!")
	print("✅ Status: Seed planted in soilbed")
	
	# Remove seed
	seed_body.queue_free()
	
	# Update state display
	if state_display:
		state_display.show_seed_planted()
	
	# Optional: Change color again (lighter brown = has seed)
	var material = get_active_material(0)
	if material:
		material.albedo_color = Color(0.5, 0.35, 0.2)  # Lighter brown with seed
