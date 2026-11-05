class_name EnemyCard
extends Control

@export var enemy_name: RichTextLabel
@export var enemy_health: TextureProgressBar

@export var FADE_DURATION: float = 0.1

func show_card(enemy: Enemy) -> void:
	enemy_name.text = "[font=res://assets/fonts/font_cute.ttf][font_size=28][left]" + enemy.data.name
	enemy_health.value = ((enemy.health * 1.0) / enemy.data.max_health) * 100.0
	print(((enemy.health * 1.0) / enemy.data.max_health) * 100.0)
	print(enemy_health.value)
	
	# Fade in
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)
	return

func hide_card() -> void:
	# Fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	return
