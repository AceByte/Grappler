extends Node2D

@export var line_segments := 20
@export var time_step := 0.1

@onready var line: Line2D = $Line2D
@export var player: CharacterBody2D

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	if not line:
		line = Line2D.new()
		add_child(line)
	line.default_color = Color.RED
	line.width = 3.0
	
	# Ensure the trajectory line renders in world space
	set_as_top_level(true)

func show_trajectory():
	if not player:
		return

	line.clear_points()

	var pos = Vector2.ZERO
	var vel = player.velocity
	var space_state = get_world_2d().direct_space_state

	for i in range(line_segments):
		var global_pos = player.global_position + pos
		line.add_point(global_pos)

		if player.is_grappling:
			var to_grapple = player.grapple_point - global_pos
			var distance = to_grapple.length()
			var rope_normal = to_grapple.normalized()
			var tangent = Vector2(-rope_normal.y, rope_normal.x)
			
			vel.y += gravity * time_step
			var stretch_amount = max(0, distance - player.current_rope_length)
			var total_rope_length = player.current_rope_length + stretch_amount * player.rope_stretch_factor
			
			if distance > total_rope_length:
				pos = (player.grapple_point - player.global_position) - rope_normal * total_rope_length
				vel = vel.project(tangent)
			
			vel *= 0.99
		else:
			vel.y += gravity * time_step

		# Calculate the next position
		var next_pos = pos + vel * time_step

		# Check for collision
		var query = PhysicsRayQueryParameters2D.create(global_pos, player.global_position + next_pos)
		query.collide_with_bodies = true
		query.collision_mask = player.collision_mask  # Use the same collision mask as the player

		var result = space_state.intersect_ray(query)
		if result:
			# If there's a collision, add the collision point and stop the trajectory
			line.add_point(result.position)
			break

		pos = next_pos

func clear_trajectory():
	if line:
		line.clear_points()
