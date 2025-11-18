class_name BuildingComponent
extends Node2D

## Emitted when building completed
signal Signal_OnBuildingCompleted()

# per second
@export var building_speed: float = 1.0

# internal
var _curr_building_cell: Cell = null
# var _curr_building_building: 

# ########################################################################################################################
# # PUBLIC METHODS
# ########################################################################################################################
# func start_mining(cell: Cell) -> void:
# 	if cell in _currently_mining_cells or cell == null or not cell.is_solid:
# 		return

# 	if _currently_mining_cells.size() >= max_simultaneous_mining_cells:
# 		return

# 	_currently_mining_cells.append(cell)


# func stop_mining_cell(cell: Cell) -> void:
# 	if cell in _currently_mining_cells:
# 		_currently_mining_cells.erase(cell)

# func stop_mining_all_cells() -> void:
# 	_currently_mining_cells.clear()


# func is_currently_mining() -> bool:
# 	return not _currently_mining_cells.is_empty()


# ########################################################################################################################
# # PRIVATE METHODS
# ########################################################################################################################
# func _ready() -> void:
# 	# SIGNALS
# 	EventBus.Signal_GlobalCellDestroyed.connect(_on_global_cell_mining_completed)


# ## Called by Signal_CellMiningCompleted for EVERY mined cell in the game
# func _on_global_cell_mining_completed(mined_cell: Cell) -> void:
# 	# Check if this component was mining that cell
# 	if mined_cell in _currently_mining_cells:
# 		_currently_mining_cells.erase(mined_cell)
# 		Signal_OnMiningCompleted.emit(mined_cell)

		
# func _physics_process(delta: float) -> void:
# 	for mining_cell in _currently_mining_cells:
# 		# Was cell destroyed by other means? This should NOT happen since we catch this with the global signal, but just in case
# 		if not mining_cell.is_solid:
# 			assert(false)
# 			_currently_mining_cells.erase(mining_cell)
# 			continue

# 		# Actual Mining
# 		mining_cell.increase_mining_process(building_speed * delta)
