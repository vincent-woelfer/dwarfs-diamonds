class_name CellPairQueue
extends RefCounted

# --- Inline Pair class ---
class Pair:
	var grid_pos_from: Vector2i
	var grid_pos_to: Vector2i

	func _init(from: Vector2i, to: Vector2i) -> void:
		grid_pos_from = from
		grid_pos_to = to

	func equals(other: Pair) -> bool:
		return grid_pos_from == other.grid_pos_from and grid_pos_to == other.grid_pos_to

	func _to_string() -> String:
		return "Pair(%s → %s)" % [grid_pos_from, grid_pos_to]


# --- Main storage and logic ---
var _pairs: Array[Pair] = []


func append_bidirectional(grid_pos_a: Vector2i, grid_pos_b: Vector2i) -> void:
	if not _verify_pair_internal(grid_pos_a, grid_pos_b):
		return

	_append_unidirectional_internal(grid_pos_a, grid_pos_b)
	_append_unidirectional_internal(grid_pos_b, grid_pos_a)


func append_unidirectional(grid_pos_from: Vector2i, grid_pos_to: Vector2i) -> void:
	if not _verify_pair_internal(grid_pos_from, grid_pos_to):
		return

	_append_unidirectional_internal(grid_pos_from, grid_pos_to)


func _verify_pair_internal(a: Vector2i, b: Vector2i) -> bool:
	# Check whether coordinates are valid
	if not Util.is_grid_pos_valid(a) or not Util.is_grid_pos_valid(b):
		return false

	# Check whether they are neighbours -> should not fail
	if not Util.are_neighbours(a, b):
		assert(false, "Positions are not neighbours: %s, %s" % [a, b])
		return false

	return true

func _append_unidirectional_internal(grid_pos_from: Vector2i, grid_pos_to: Vector2i) -> void:
	# Dont check for duplicates, just add.
	# This is faster and duplicates are not a problem since updates are idempotent (setting a connection multiple times is not a problem)
	var new_pair := Pair.new(grid_pos_from, grid_pos_to)
	_pairs.append(new_pair)


func get_all() -> Array[Pair]:
	return _pairs


func size() -> int:
	return _pairs.size()


func is_empty() -> bool:
	return _pairs.is_empty()


func clear() -> void:
	_pairs.clear()


func _to_string() -> String:
	var s := []
	for p in _pairs:
		s.append(p.to_string())
	return "[%s]" % ", ".join(s)
