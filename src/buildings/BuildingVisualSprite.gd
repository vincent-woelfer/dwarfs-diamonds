@tool
class_name BuildingVisualSprite
extends Sprite2D

var progress: float

@export var final_texture: Texture2D:
	set(value):
		final_texture = value
		update_building_progress(progress)

@export var construction_textures: Array[Texture2D] = []:
	set(value):
		construction_textures = value
		update_building_progress(progress)


func _ready() -> void:
	(get_parent() as BuildingVisualRoot).building_progress_updated.connect(update_building_progress)


func update_building_progress(progress_: float) -> void:
	progress = progress_
	var new_texture: Texture2D = _get_building_texture(progress)
	if new_texture != self.texture:
		self.texture = new_texture
		

func _get_building_texture(construction_progress: float) -> Texture2D:
	construction_progress = clampf(construction_progress, 0.0, 1.0)
	var count: int = construction_textures.size()

	if construction_progress >= 1.0 or count == 0:
		return final_texture

	var index: int = mini(int(floori(construction_progress * count)), count - 1)
	return construction_textures[index]
