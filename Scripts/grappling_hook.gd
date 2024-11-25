extends Node2D

@export var max_grapple_length := 100000.0
@export var min_grapple_length := 50.0
@export var rope_adjust_speed := 100.0
@export var swing_force := 1000.0
@export var rope_stretch_factor := 0.5

var grapple_point: Vector2 = Vector2.ZERO
var is_grappling: bool = false
var current_rope_length: float = 0.0
var is_swinging: bool = false
var launch_direction: Vector2 = Vector2.ZERO
@onready var rope: Line2D = $Rope

func fire_grapple(player_position: Vector2, aim_direction: Vector2, max_distance: float):
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(player_position, player_position + aim_direction * max_distance)
	var result = space_state.intersect_ray(query)

	if result:
		grapple_point = result.position
		is_grappling = true
		current_rope_length = player_position.distance_to(grapple_point)
		current_rope_length = min(current_rope_length, max_grapple_length)

func release_grapple():
	is_grappling = false
	rope.clear_points()
	is_swinging = false

func adjust_rope_length(delta: float):
	if is_grappling:
		var rope_adjust = Input.get_axis("ui_down", "ui_up")
		current_rope_length -= rope_adjust * rope_adjust_speed * delta
		current_rope_length = clamp(current_rope_length, min_grapple_length, max_grapple_length)

func update_rope_visual(player_position: Vector2):
	if is_grappling:
		rope.clear_points()
		rope.add_point(player_position)
		rope.add_point(grapple_point)
	else:
		rope.clear_points()

func get_grapple_forces(player_position: Vector2, velocity: Vector2, gravity: float, delta: float) -> Dictionary:
	if not is_grappling:
		return {"velocity": velocity, "is_swinging": is_swinging}

	var to_grapple = grapple_point - player_position
	var distance = to_grapple.length()
	var rope_normal = to_grapple.normalized()
	var tangent = Vector2(-rope_normal.y, rope_normal.x)

	velocity.y += gravity * delta
	var stretch_amount = max(0, distance - current_rope_length)
	var total_rope_length = current_rope_length + stretch_amount * rope_stretch_factor

	if is_swinging and player_position.y > grapple_point.y + ((total_rope_length / 3) * 2):
		var input_direction = Input.get_axis("ui_left", "ui_right")
		velocity += tangent * input_direction * swing_force * delta

	if distance > total_rope_length:
		player_position = grapple_point - rope_normal * total_rope_length
		velocity = velocity.project(tangent)

	velocity *= 0.99
	is_swinging = true
	launch_direction = (player_position - grapple_point).normalized()

	return {"velocity": velocity, "player_position": player_position, "is_swinging": is_swinging}
