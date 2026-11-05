extends Area3D

var player :CharacterBody3D 


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body
		player.velocity.y = 30
