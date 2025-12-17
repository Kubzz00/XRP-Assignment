extends Node3D

@export var tilt_threshold_degrees: float = 60.0
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
	
	# Assume spout points along -Z in local space. Adjust to +Z if needed.
	var spout_dir: Vector3 = -can_body.global_transform.basis.z
	var world_up: Vector3 = Vector3.UP
	
	# Angle between spout and world up:
	# 0°  = spout up, 90° = spout horizontal, 180° = spout straight down.
	var angle_rad = spout_dir.angle_to(world_up)
	var angle_deg = rad_to_deg(angle_rad)
	
	# Water when spout is tilted down enough (angle greater than threshold)
	var should_emit = angle_deg > tilt_threshold_degrees
	water_particles.emitting = should_emit
