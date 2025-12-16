extends Node3D

@onready var status_label: Label3D = $StatusLabel

func _ready():
	print("✅ StateUpdate display ready!")
	show_state("Ready to Farm")

# Main function to update the display
func show_state(message: String):
	if not status_label:
		return
	
	status_label.text = message
	print("StateUpdate: ", message)

# Specific state functions
func show_plot_spawned():
	show_state("Plot Created!")

func show_plot_dug():
	show_state("Soil Dug!")

func show_seed_planted():
	show_state("Seed Planted!")

func show_soil_watered():
	show_state("Soil Watered!")

func show_plant_growing():
	show_state("Plant Growing...")

func show_ready_to_harvest():
	show_state("Ready to Harvest!")

func show_error(error_msg: String):
	show_state(error_msg)
