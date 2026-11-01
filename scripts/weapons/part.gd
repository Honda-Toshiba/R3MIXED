class_name WeaponPart
extends Resource

@export var id: StringName = &""
@export var name: String = ""
@export var rarity: int
@export var model: PackedScene

# All the following stats represent ideal values, to be multiplied by quality
@export var damage: int

# Info
@export var info_buffs: Array[String]
@export var info_debuffs: Array[String]
