extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# This function toggles slow motion on and off
func toggle_slowmotion():
	if Engine.time_scale == 1:
		Engine.time_scale = 0.5  # Slow motion (20% of normal speed)
	else:
		Engine.time_scale = 1  # Normal speed


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("slow"):  # Assuming you want to use Enter or Space
		toggle_slowmotion()
