extends Node


@onready var oneshots: AudioStreamPlayer = $oneshots
@onready var loops: AudioStreamPlayer = $loops


func _on_player_slide_start() -> void:
	loops.play()
	print("play effect")



func _on_player_slide_end() -> void:
	loops.stop()


func _on_player_dash_start() -> void:
	oneshots.play()
