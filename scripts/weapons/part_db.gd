extends Node

const HEAD_DIR := "res://data/heads/"
const TAIL_DIR := "res://data/tails/"

var _heads: Dictionary = {}
var _tails: Dictionary = {}

func _ready() -> void:
	_load_parts()

func _load_parts() -> void:
	var head_dir := DirAccess.open(HEAD_DIR)
	var tail_dir := DirAccess.open(TAIL_DIR)
	if (head_dir == null) or (tail_dir == null):
		push_error("Failed to open head/tail directory.")
		return
	
	# Load heads	
	for file in head_dir.get_files():
		file = file.trim_suffix(".remap")
		if not file.ends_with(".tres"):
			continue
		
		var head := load(HEAD_DIR + file) as WeaponPart
		if head == null:
			continue
		if _heads.has(head.id):
			push_warning("Duplicate head ID: " + head.id)
		_heads[head.id] = head
		
	# Load tails	
	for file in tail_dir.get_files():
		file = file.trim_suffix(".remap")
		if not file.ends_with(".tres"):
			continue
		
		var tail := load(TAIL_DIR + file) as WeaponPart
		if tail == null:
			continue
		if _tails.has(tail.id):
			push_warning("Duplicate tail ID: " + tail.id)
		_tails[tail.id] = tail 

func get_head(id: StringName) -> WeaponPart:
	return _heads.get(id)

func get_tail(id: StringName) -> WeaponPart:
	return _tails.get(id)
