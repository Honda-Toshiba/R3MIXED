extends Area3D

@export var launch_speed: float = 10.0

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("launch_upward"):
		body.launch_upward(launch_speed)
