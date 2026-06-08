class_name SunSystem
extends Node2D

###################################
# Darkness
###################################
var darkness: CanvasModulate

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

# Modifiers for day/night duration, changed by dev_toggle_sun_fast_forward
var day_duration_factor: float = 1.0
var night_duration_factor: float = 1.0

# Margin to avoid sun being exactly horizontal at sunrise/sunset
var margin_deg: float = 5.0

# Sky scroll offset
var sky_scroll_speed: Vector2 = Vector2(0.04, 0.0)
var sky_scroll_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Sunlight
	sunlight = DirectionalLight2D.new()
	sunlight.shadow_enabled = true
	# sunlight.max_distance = 4000.0
	add_child(sunlight)

	# Darkness
	# darkness = CanvasModulate.new()
	# darkness.color = Colors.LEVEL_DARKNESS_COLOR
	# add_child(darkness)

	# start early morning
	time = 0.25

	# Dev Signals
	EventBus.Signal_DevToggleLight.connect(_dev_toggle_light)
	EventBus.Signal_DevToggleSunFastForward.connect(_dev_toggle_sun_fast_forward)
	_dev_toggle_light()
	_dev_toggle_sun_fast_forward()


func _process(delta: float) -> void:
	# Increase Time. 0 -> 1 = Daytime, 1 -> 2 = Nighttime
	if time < 1.0:
		time += delta / (day_duration_sec * day_duration_factor)
	else:
		time += delta / (night_duration_sec * night_duration_factor)

	if time > 2.0:
		time = 0.0

	var is_daytime: bool = time <= 1.0
	var night_time: float = time - 1.0 # 0 -> 1

	# Sun Color
	if is_daytime:
		sunlight.color = color_gradient.sample(time)
	else:
		# At night, gradually shift between sunset and sunrise color. This should cause no jumps.
		var sunset_color: Color = color_gradient.sample(1.0)
		var sunrise_color: Color = color_gradient.sample(0.0)
		sunlight.color = lerp(sunset_color, sunrise_color, night_time)

	# Sun Angle:
	# -90 deg = horizontal from left
	# 0 deg = vertical from top
	# +90 deg = horizontal from right

	if is_daytime:
		sunlight.rotation_degrees = remap(time, 0.0, 1.0, -90.0 + margin_deg, 90.0 - margin_deg)
	else:
		# At night set to from above again. This is a jump!
		sunlight.rotation_degrees = 0.0

	# Sun Energy
	if is_daytime:
		sunlight.energy = energy_curve.sample(time)
	else:
		# At night, gradually shift between sunset and sunrise energy. This should cause no jumps.
		var sunset_energy: float = energy_curve.sample(1.0)
		var sunrise_energy: float = energy_curve.sample(0.0)
		sunlight.energy = lerp(sunset_energy, sunrise_energy, night_time)

	# Sky scroll offset
	# Always use day_duration_factor for sky scrolling to keep it consistent
	sky_scroll_offset += sky_scroll_speed * delta
	RenderingServer.global_shader_parameter_set("sky_scroll_offset", sky_scroll_offset)

	# Currently unused
	# RenderingServer.global_shader_parameter_set("sky_sunlight_energy", sunlight_energy_for_sky)

	# Set sky color
	var sky_color: Color = sunlight.color
	sky_color.a = 1.0 # Ensure alpha is 1 for sky color

	# Ensure night is not pitch black by applying a minimum brightness to the sky color
	var min_brightness: float = 0.25
	sky_color.r = max(sky_color.r, min_brightness)
	sky_color.g = max(sky_color.g, min_brightness)
	sky_color.b = max(sky_color.b, min_brightness)

	RenderingServer.global_shader_parameter_set("sky_color", sky_color)


func _dev_toggle_light() -> void:
	if EventBus.dev_light_on:
		# WITH LIGHTING / DARKNESS		
		# darkness.visible = true
		sunlight.enabled = true
	else:
		# NO LIGHTING / DARKNESS
		# darkness.visible = false
		sunlight.enabled = false


func _dev_toggle_sun_fast_forward() -> void:
	if EventBus.dev_sun_fast_forward:
		day_duration_factor = 0.05
		night_duration_factor = 0.05
	else:
		day_duration_factor = 1.0
		night_duration_factor = 1.0
