extends Node


@onready var oneshots: AudioStreamPlayer = $oneshots
@onready var loops: AudioStreamPlayer = $loops

@export var dash_sound: AudioStream
@export var landing_sound: AudioStream
@export var slide_sound: AudioStream
@export var air_wooshing: AudioStream


# AudioManager.gd
func play_one_shot(clip: AudioStream) -> void:
	oneshots.stream = clip
	oneshots.play()

func play_loop(clip: AudioStream) -> void:
	if loops.stream == clip and loops.playing:
		return  # This loop is already playing. Let it continue.

	loops.stream = clip
	loops.play()

func stop_loop() -> void:
	loops.stop()

func _on_player_slide_start() -> void:
	play_loop(slide_sound)
	print("its working ")

func _on_player_slide_end() -> void:
	stop_loop()

func _on_player_dash_start() -> void:
	play_one_shot(dash_sound)


func _on_player_in_the_air() -> void:
	play_loop(air_wooshing)

func _on_player_stop_in_the_air() -> void:
	stop_loop()
