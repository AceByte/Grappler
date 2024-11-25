extends Node2D

@onready var physics_formulas = $UI/Formler  # Assuming PhysicsFormulas is a child of this node
var is_slow_motion := false

func _ready() -> void:
	if not physics_formulas:
		push_warning("PhysicsFormulas node not found. Make sure it's a child of this node.")

# This function toggles slow motion on and off
func toggle_slowmotion():
	is_slow_motion = not is_slow_motion
	if is_slow_motion:
		Engine.time_scale = 0.5  # Slow motion (50% of normal speed)
		physics_formulas.toggle_formulas(true)  # Show formulas in slow motion
	else:
		Engine.time_scale = 1  # Normal speed
		physics_formulas.toggle_formulas(false)  # Hide formulas in normal speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("slow"):  # Assuming you want to use Enter or Space
		toggle_slowmotion()
