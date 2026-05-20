class_name LevelStatsManager
extends Node2D

var dev_stats_label: RichTextLabel

# STATS
var total_mined_cells: int = 0
var gemstones_collected: int = 0

########################################################################################################################
# PUBLIC METHODS
########################################################################################################################
func update_mined_cells(count: int) -> void:
	total_mined_cells += count

func update_gemstones_collected(count: int) -> void:
	gemstones_collected += count

	if count > 0:
		Audio.play_global("gemstone_dropoff")

########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
func _init() -> void:
	self.process_priority = Enum.ProcessPriority.DEFAULT


func _ready() -> void:
	if Engine.is_editor_hint(): return

	dev_stats_label = get_tree().root.get_node("root/UICanvasLayer-ScreenSpace-3/DevStatsLabel")


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	# Update label
	dev_stats_label.text = "Dwarfs: %d | Jobs: %d | Buildings: %d\n[color=red]Cells mined: %d[/color] | [color=pink]Gemstones: %d[/color]" % [
		Global.level.dwarfs.size(),
		Global.level.job_manager._jobs.size(),
		Global.level.building_manager.buildings.size(),
		total_mined_cells,
		gemstones_collected,
	]
