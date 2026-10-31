class_name Enemy
extends CharacterBody3D

@export var data: EnemyData
var health: int

func _ready() -> void:
	health = data.max_health

func die() -> void:
	var weapon_drop = Weapon.create_drop(data.head_pool, data.tail_pool, data.odds)
	# instantiate weapon at enemy position
