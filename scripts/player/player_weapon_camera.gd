extends Node3D

@export var player_camera: Node3D

func _process(delta: float) -> void:
	global_transform = player_camera.global_transform
