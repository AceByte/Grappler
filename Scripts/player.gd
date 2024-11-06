extends CharacterBody2D

@export var max_speed = 300.0
@export var jump_velocity = -400.0
@export var acceleration_rate := 1000.0
@export var deceleration_rate := 2000.0
@export var friction_coefficient := 0.2
@export var air_resistance_coefficient := 0.02
@export var max_grapple_length := 500.0
@export var min_grapple_length := 50.0
@export var rope_adjust_speed := 100.0
@export var swing_force := 1000.0
@export var launch_speed := 500
@export var rope_stretch_factor := 0.5  # Amount the rope can stretch beyond max length

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var grapple_point: Vector2 = Vector2.ZERO
var is_grappling := false
var grapple_rope: Line2D
var current_rope_length: float = 0.0

# Added variable to check if the player is swinging
var is_swinging: bool = false

func _ready():
	grapple_rope = Line2D.new()
	grapple_rope.width = 5
	grapple_rope.default_color = Color.WHITE
	add_child(grapple_rope)
	grapple_rope.set_as_top_level(true)

func _physics_process(delta: float) -> void:
	if is_on_ceiling():
		velocity.y*=-1
	
	if is_grappling:
		handle_grappling(delta)
	else:
		handle_normal_movement(delta)

	if Input.is_action_just_pressed("ui_accept"):
		toggle_grapple()

	move_and_slide()
	update_grapple_rope()

func handle_normal_movement(delta: float):
	var direction := Input.get_axis("ui_left", "ui_right")
	
	# Allow direction change only if on the ground
	if is_on_floor():
		if direction != 0:
			velocity.x += direction * acceleration_rate * delta
		else:
			velocity.x = move_toward(velocity.x, 0, deceleration_rate * delta)
	
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_velocity

	if is_on_floor():
		var friction = friction_coefficient * gravity
		if abs(velocity.x) > friction * delta:
			velocity.x -= friction * delta * sign(velocity.x)
		else:
			velocity.x = 0

	velocity *= 1.0 - (air_resistance_coefficient * delta)
	velocity.x = clamp(velocity.x, -max_speed, max_speed)

func handle_grappling(delta: float):
	adjust_rope_length(delta)
	
	var to_grapple = grapple_point - global_position
	var distance = to_grapple.length()
	
	# Normalized vectors
	var rope_normal = to_grapple.normalized()
	var tangent = Vector2(-rope_normal.y, rope_normal.x)
	
	# Apply gravity
	velocity.y += gravity * delta
	
	# Player input for swinging, only apply if swinging
	if is_swinging and position.y>grapple_point.y:
		var input_direction = Input.get_axis("ui_left", "ui_right")
		if input_direction != 0:
			#Apply swinging force along the tangent direction
			velocity += tangent * input_direction * swing_force * delta

	# Rope constraint with stretch simulation
	var stretch_amount = max(0, distance - current_rope_length)
	var total_rope_length = current_rope_length + stretch_amount * rope_stretch_factor

	if distance > total_rope_length:
		global_position = grapple_point - rope_normal * total_rope_length
		# Keep only the tangential component of velocity
		velocity = velocity.project(tangent)

	# Apply some damping to simulate air resistance
	#velocity *= 0.99

	# Set is_swinging to true while the player is grappling
	is_swinging = true

	## If the player releases the swing button or is not grappling, reset swinging
	#if Input.is_action_just_released("ui_left") && Input.is_action_just_released("ui_right"):
		#is_swinging = false
		#swing_force = 0

func toggle_grapple():
	if is_grappling:
		release_grapple()
	else:
		fire_grapple()

func fire_grapple():
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	var max_distance = 1000  # Maximum raycast distance
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + direction * max_distance)
	var result = space_state.intersect_ray(query)
	
	if result:
		grapple_point = result.position
		is_grappling = true
		current_rope_length = global_position.distance_to(grapple_point)
		current_rope_length = min(current_rope_length, max_grapple_length)

func release_grapple():
	var input_direction = Input.get_axis("ui_left", "ui_right")
	is_grappling = false
	velocity.x += launch_speed * input_direction
	grapple_rope.clear_points()
	is_swinging = false  # Reset swinging status when grapple is released

func adjust_rope_length(delta: float):
	var rope_adjust = Input.get_axis("ui_down", "ui_up")
	current_rope_length -= rope_adjust * rope_adjust_speed * delta
	current_rope_length = clamp(current_rope_length, min_grapple_length, max_grapple_length)

func update_grapple_rope():
	if is_grappling:
		grapple_rope.clear_points()
		grapple_rope.add_point(global_position)
		grapple_rope.add_point(grapple_point)
	else:
		grapple_rope.clear_points()

func _exit_tree():
	if is_instance_valid(grapple_rope):
		grapple_rope.queue_free()
