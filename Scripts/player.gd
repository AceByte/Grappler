extends CharacterBody2D

@export var max_speed = 300.0
@export var jump_velocity = -400.0
@export var acceleration_rate := 1000.0
@export var deceleration_rate := 2000.0
@export var friction_coefficient := 0.2
@export var air_resistance_coefficient := 0.02
@export var grapple_pull_force := 1000.0
@export var max_grapple_length := 500.0
@export var grapple_damping := 0.9

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var grapple_point: Vector2 = Vector2.ZERO
var is_grappling := false
var grapple_rope: Line2D

func _ready():
	grapple_rope = Line2D.new()
	grapple_rope.width = 2
	grapple_rope.default_color = Color.WHITE
	# Add the rope to the scene tree instead of as a child of this node
	get_tree().get_root().add_child(grapple_rope)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_velocity

	if is_on_floor():
		var direction := Input.get_axis("ui_left", "ui_right")
		
		if direction != 0:
			velocity.x += direction * acceleration_rate * delta
		else:
			velocity.x = move_toward(velocity.x, 0, deceleration_rate * delta)
			
		var friction = friction_coefficient * gravity
		if abs(velocity.x) > friction * delta:
			velocity.x -= friction * delta * sign(velocity.x)
		else:
			velocity.x = 0

	velocity *= 1.0 - (air_resistance_coefficient * delta)

	if Input.is_action_just_pressed("ui_accept"):
		fire_grapple()
	elif Input.is_action_just_released("ui_accept"):
		release_grapple()

	if is_grappling:
		apply_grapple_force(delta)

	velocity.x = clamp(velocity.x, -max_speed, max_speed)

	move_and_slide()
	update_grapple_rope()

func fire_grapple():
	var mouse_pos = get_global_mouse_position()
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, mouse_pos)
	var result = space_state.intersect_ray(query)
	
	if result:
		print("grapple")
		grapple_point = result.position
		is_grappling = true

func release_grapple():
	is_grappling = false
	grapple_rope.clear_points()

func apply_grapple_force(delta: float):
	var to_grapple = grapple_point - global_position
	var distance = to_grapple.length()
	
	if distance > max_grapple_length:
		release_grapple()
		return
	
	var grapple_direction = to_grapple.normalized()
	var force = grapple_direction * grapple_pull_force * delta
	
	velocity += force
	velocity *= grapple_damping

func update_grapple_rope():
	if is_grappling:
		grapple_rope.clear_points()
		grapple_rope.add_point(global_position)
		grapple_rope.add_point(grapple_point)
	else:
		grapple_rope.clear_points()

func _exit_tree():
	# Clean up the grapple_rope when the character is removed from the scene
	if is_instance_valid(grapple_rope):
		grapple_rope.queue_free()
