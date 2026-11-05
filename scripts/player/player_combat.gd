extends Node

@export var player: Player
@export var hitbox: Area3D

func attack() -> void:
	for enemy in hitbox.get_overlapping_bodies():
		damage_enemy(enemy, player.get_current_weapon().damage)

func damage_enemy(enemy: Enemy, value: int) -> void:
	enemy.take_damage(value)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		attack()
