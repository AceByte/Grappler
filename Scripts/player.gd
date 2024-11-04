extends CharacterBody2D

# Movement variables
var max_speed: float = 200
var acceleration: float = 1000
var deceleration: float = 800
var friction: float = 600
var jump_force: float = 500
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	# Horizontal movement with acceleration and deceleration
	if Input.is_action_pressed("ui_right"):
		velocity.x = min(velocity.x + acceleration * delta, max_speed)
	elif Input.is_action_pressed("ui_left"):
		velocity.x = max(velocity.x - acceleration * delta, -max_speed)
	else:
		# Apply friction when no input is given
		if abs(velocity.x) > 0:
			velocity.x = approach(velocity.x, 0, friction * delta)
	
	# Jumping logic
	if is_on_floor() and Input.is_action_just_pressed("ui_jump"):
		velocity.y = -jump_force  # Apply an instant upward force
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Move the player with updated velocity
	move_and_slide()
