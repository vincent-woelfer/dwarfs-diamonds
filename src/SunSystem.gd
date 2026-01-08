class_name SunSystem
extends Node2D

###################################
# Darkness
###################################
var darkness: CanvasModulate
var darkness_factor: float = 0.4

###################################
# Sunlight
###################################
var sunlight: DirectionalLight2D

var color_gradient: Gradient = preload("res://assets/gradients/sun_color.tres")
var energy_curve: Curve = preload("res://assets/gradients/sun_energy.tres")

# Time goes from 0 -> 1 for sunrise to sunset, then goes from 1 to 2 for night. Different speeds can be used however.
var time: float

var day_duration_sec: float = 120.0
var night_duration_sec: float = 70.0

func _ready() -> void:
	# Connect Signals
	EventBus.Signal_DevToogleLight.connect(_dev_toogle_light)

	# Sunlight
	sunlight = DirectionalLight2D.new()
	sunlight.shadow_enabled = true
	# sunlight.max_distance = 4000.0
	add_child(sunlight)

	# Darkness
	darkness = CanvasModulate.new()
	darkness.color = Color(darkness_factor, darkness_factor, darkness_factor, 1.0)
	add_child(darkness)

	# start early morning
	time = 0.25


func _process(delta: float) -> void:
	# Increase Time
	if time < 1.0:
		time += delta * (1.0 / day_duration_sec)
	else:
		time += delta * (1.0 / night_duration_sec)

	if time > 2.0:
		time = 0.0

	var is_daytime: bool = time < 1.0

	# Sun Color
	if is_daytime:
		sunlight.color = color_gradient.sample(time)
	else:
		sunlight.color = (color_gradient.sample(0.0) + color_gradient.sample(1.0)) / 2.0

	# Sun Angle:
	# -90 deg = horizontal from left
	# 0 deg = vertical from top
	# +90 deg = horizontal from right

	if is_daytime:
		var margin_deg: float = 0.0
		sunlight.rotation_degrees = remap(time, 0.0, 1.0, -90.0 + margin_deg, 90.0 - margin_deg)
	else:
		pass
		# sunlight.rotation_degrees = 0.0

	# Sun Energy
	if is_daytime:
		sunlight.energy = energy_curve.sample(time)
	else:
		sunlight.energy = (energy_curve.sample(0.0) + energy_curve.sample(1.0)) / 2.0


func _dev_toogle_light(is_light_on: bool) -> void:
	if is_light_on:
		# WITH LIGHTING / DARKNESS		
		darkness.visible = true
		sunlight.enabled = true
	else:
		# NO LIGHTING / DARKNESS
		darkness.visible = false
		sunlight.enabled = false
