extends CharacterBody2D

@export var max_speed = 300.0
@export var jump_velocity = -400.0
@export var acceleration_rate := 1000.0
@export var deceleration_rate := 2000.0
@export var friction_coefficient := 0.2
@export var air_resistance_coefficient := 0.02
@export var max_grapple_length := 100000.0
@export var min_grapple_length := 50.0
@export var rope_adjust_speed := 100.0
@export var swing_force := 1000.0
@export var launch_speed := 5000
@export var rope_stretch_factor := 0.5

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var force_visualizer: Node2D
var grapple_point: Vector2 = Vector2.ZERO
var is_grappling := false
var grapple_rope: Line2D
var current_rope_length: float = 0.0
var is_swinging: bool = false
var launch_direction: Vector2 = Vector2.ZERO

@onready var trajectory_line = $TrajectoryLine  # Reference to the trajectory line node

func _ready():
	# Setup the grapple rope and force visualizer
	grapple_rope = Line2D.new()
	grapple_rope.width = 5
	grapple_rope.default_color = Color.WHITE
	add_child(grapple_rope)
	grapple_rope.set_as_top_level(true)
	
	# Get the force visualizer
	force_visualizer = $ForceVisualizer  # Ensure this is the correct node path

func _physics_process(delta: float) -> void:
	# Handle ceiling behavior
	if is_on_ceiling():
		velocity.y *= -1
	
	# Update the force visualizer with the current forces
	update_force_visualizer(delta)

	# Apply forces and handle movement
	if is_grappling:
		handle_grappling(delta)
	else:
		handle_normal_movement(delta)

	# Update the trajectory line when in the air
	if not is_on_floor():
		trajectory_line.show_trajectory()
	else:
		trajectory_line.clear_trajectory()  # Clear trajectory when on the ground

	# Process user input for grappling
	if Input.is_action_just_pressed("ui_accept"):
		toggle_grapple()

	# Move and slide the character
	move_and_slide()

	# Update the rope visual
	update_grapple_rope()

# Function to update the force visualizer based on current forces
func update_force_visualizer(delta: float):
	# Set the force vectors for the visualizer
	if not is_on_floor():
		force_visualizer.gravity_force = Vector2(0, gravity)  # Base gravity
		force_visualizer.actual_gravity = Vector2(0, velocity.y)
	else:
		force_visualizer.gravity_force = Vector2.ZERO
		force_visualizer.actual_gravity = Vector2.ZERO

	force_visualizer.velocity_force = velocity  # Current velocity vector

	# Calculate direction force based on input direction
	var direction_input = Input.get_axis("ui_left", "ui_right")
	force_visualizer.direction_force = Vector2(direction_input * acceleration_rate, 0) * delta  # Movement direction

	if is_grappling:
		var grapple_direction = (grapple_point - global_position).normalized()
		force_visualizer.grapple_force = grapple_direction * swing_force  # Grapple force direction
	else:
		force_visualizer.grapple_force = Vector2.ZERO
		force_visualizer.stress_force = Vector2.ZERO  # Reset stress force when not grappling

# Handle normal movement (walking, jumping, etc.)
func handle_normal_movement(delta: float):
	var direction := Input.get_axis("ui_left", "ui_right")
	
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
		gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
		var friction = friction_coefficient * gravity
		velocity.x = clamp(velocity.x, -max_speed, max_speed)
		if abs(velocity.x) > friction * delta:
			velocity.x -= friction * delta * sign(velocity.x)
		else:
			velocity.x = 0

	velocity *= 1.0 - (air_resistance_coefficient * delta)
	velocity.x = clamp(velocity.x, -max_speed, max_speed)

# Handle grappling mechanics (rope, swing force, etc.)
func handle_grappling(delta: float):
	var input_direction = Input.get_axis("ui_left", "ui_right")
	adjust_rope_length(delta)
	
	var to_grapple = grapple_point - global_position
	var distance = to_grapple.length()
	
	var rope_normal = to_grapple.normalized()
	var tangent = Vector2(-rope_normal.y, rope_normal.x)
	
	velocity.y += gravity * delta
	var stretch_amount = max(0, distance - current_rope_length)
	var total_rope_length = current_rope_length + stretch_amount * rope_stretch_factor
	
	# Set the stress force for the visualizer
	force_visualizer.stress_force = rope_normal * stretch_amount * rope_stretch_factor
	
	if is_swinging and position.y > grapple_point.y + ((total_rope_length / 4)*3):
		if input_direction != 0:
			velocity += tangent * input_direction * swing_force * delta

	if distance > total_rope_length:
		global_position = grapple_point - rope_normal * total_rope_length
		velocity = velocity.project(tangent)

	# Calculate launch direction as a vector pointing away from the grapple point
	launch_direction = (global_position - grapple_point).normalized()

	velocity *= 0.99
	is_swinging = true

# Grapple toggle (fire or release)
func toggle_grapple():
	if is_grappling:
		release_grapple()
	else:
		fire_grapple()

# Fire the grapple (aim at the mouse position)
func fire_grapple():
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	var max_distance = 100000
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + direction * max_distance)
	var result = space_state.intersect_ray(query)
	
	if result:
		grapple_point = result.position
		is_grappling = true
		current_rope_length = global_position.distance_to(grapple_point)
		current_rope_length = min(current_rope_length, max_grapple_length)

# Release the grapple (detach from the grapple point)
func release_grapple():
	is_grappling = false
	grapple_rope.clear_points()
	is_swinging = false

# Adjust the rope length based on input
func adjust_rope_length(delta: float):
	var rope_adjust = Input.get_axis("ui_down", "ui_up")
	current_rope_length -= rope_adjust * rope_adjust_speed * delta
	current_rope_length = clamp(current_rope_length, min_grapple_length, max_grapple_length)

# Update the grapple rope visual representation
func update_grapple_rope():
	if is_grappling:
		grapple_rope.clear_points()
		grapple_rope.add_point(global_position)
		grapple_rope.add_point(grapple_point)
	else:
		grapple_rope.clear_points()

# Cleanup when exiting the scene
func _exit_tree():
	if is_instance_valid(grapple_rope):
		grapple_rope.queue_free()
