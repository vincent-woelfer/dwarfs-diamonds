class_name LevelStatsManager
extends Node2D


var dev_stats_label: RichTextLabel

########################################################################################################################
# PUBLIC METHODS
########################################################################################################################

########################################################################################################################
# PRIVATE METHODS
########################################################################################################################
func _init() -> void:
	self.process_priority = Enum.ProcessPriority.DEFAULT


func _ready() -> void:
	dev_stats_label = get_tree().root.get_node("root/UICanvasLayer-ScreenSpace-3/DevStatsLabel")


func _process(delta: float) -> void:
	# Update label
	dev_stats_label.text = "Dwarfs: %d\nJobs: %d\nBuildings: %d" % [
		Global.level.dwarfs.size(),
		Global.level.job_manager._jobs.size(),
		Global.level.building_manager.buildings.size(),
	]
