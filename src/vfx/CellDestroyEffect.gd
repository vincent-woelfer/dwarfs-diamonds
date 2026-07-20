@tool
extends Node2D

class_name CellDestroyEffect

static var scene: PackedScene = preload("res://scenes/vfx/CellDestroyEffect.tscn")

@export_tool_button("Restart Particles")
var button := start


static func spawn_at_cell(grid_pos: Vector2i) -> CellDestroyEffect:
	var instance := scene.instantiate() as CellDestroyEffect

	var pos: Vector2 = Util.grid_to_world_cell_center(grid_pos)
	Util.spawn(instance, pos, null)

	# Since its one-shot
	Util.delete_after(1.0, instance)

	instance.start()
	return instance


## Start one-shot particles for all children of this node.
func start() -> void:
	self.z_index = Enum.ZIndex.VFX
	var at_least_one_particle: bool = false

	for child in get_children():
		if child is GPUParticles2D:
			var particles: GPUParticles2D = child as GPUParticles2D
			particles.one_shot = true
			particles.emitting = true
			at_least_one_particle = true
		elif child is CPUParticles2D:
			var particles: CPUParticles2D = child as CPUParticles2D
			particles.one_shot = true
			particles.emitting = true
			at_least_one_particle = true

	if not at_least_one_particle:
		push_warning("No particles found in CellDestroyEffect children.")
