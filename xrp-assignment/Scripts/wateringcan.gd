extends Node3D

@export var tilt_threshold_degrees: float = 40.0
@export var water_particles_path: NodePath = NodePath("../WaterParticles")
@export var can_body_path: NodePath = NodePath("..")

var water_particles: GPUParticles3D
var can_body: RigidBody3D

func _ready():
	if has_node(water_particles_path):
		water_particles = get_node(water_particles_path) as GPUParticles3D
	if has_node(can_body_path):
		can_body = get_node(can_body_path) as RigidBody3D

func _physics_process(delta):
	if water_particles == null or can_body == null:
		return
	
	# Use the can's local DOWN direction (its -Y axis) to detect tilt
	var can_down: Vector3 = -can_body.global_transform.basis.y
	var world_down: Vector3 = Vector3.DOWN
	
	var angle_rad = can_down.angle_to(world_down)
	var angle_deg = rad_to_deg(angle_rad)
	
	var should_emit = angle_deg < tilt_threshold_degrees
	water_particles.emitting = should_emit
