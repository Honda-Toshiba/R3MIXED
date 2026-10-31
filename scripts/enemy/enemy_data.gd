class_name EnemyData
extends Resource

@export var id: StringName = &""
@export var name: String = ""
@export var max_health: int = 100

@export var head_pool: Array[WeaponPart]
@export var tail_pool: Array[WeaponPart]
@export var odds_head: Array[int]
@export var odds_tail: Array[int]
