extends Node2D

@export var platform_scene: PackedScene
@export var chunk_size := 1000
@export var platform_length_range := Vector2i(3, 10)
@export var platform_height_range := Vector2i(-2, 2)
@export var platform_spacing := 300

@export var platform_scenes := [
	preload("res://Small Platform.tscn"),
	preload("res://Big_Platform.tscn"),
	preload("res://Water Platform.tscn")
]

@onready var physics_formulas = $UI/Formler  # Assuming PhysicsFormulas is a child of this node
var is_slow_motion := false

var active_chunks := {}

func _ready():
	# Generate the initial few chunks to provide a filled environment for the player to start
	generate_initial_chunks()

	if not physics_formulas:
		push_warning("PhysicsFormulas node not found. Make sure it's a child of this node.")

func _process(delta):
	# Get player's current x position
	var player_node = get_node_or_null("Player")
	if player_node != null:
		var player_x: float = player_node.position.x
		var player_chunk := int(player_x / chunk_size)

		# Load new chunks if the player advances
		for chunk in range(player_chunk - 1, player_chunk + 2):
			if chunk not in active_chunks:
				generate_chunk(chunk)

		# Unload chunks that are far behind the player
		var chunks_to_remove := []
		for chunk in active_chunks.keys():
			if abs(chunk - player_chunk) > 2:
				remove_chunk(chunk)
				chunks_to_remove.append(chunk)

		for chunk in chunks_to_remove:
			active_chunks.erase(chunk)

	# Toggle slow motion
	if Input.is_action_just_pressed("slow"):
		toggle_slowmotion()

func toggle_slowmotion():
	is_slow_motion = not is_slow_motion
	if is_slow_motion:
		Engine.time_scale = 0.5  # Slow motion (50% of normal speed)
		physics_formulas.toggle_formulas(true)  # Show formulas in slow motion
	else:
		Engine.time_scale = 1  # Normal speed
		physics_formulas.toggle_formulas(false)  # Hide formulas in normal speed

func generate_initial_chunks():
	# Generate the first few chunks so the player starts in a filled level
	for i in range(-1, 2):
		generate_chunk(i)

func generate_chunk(chunk_id):
	var start_x: int = chunk_id * chunk_size
	var current_x_position: int = start_x
	var previous_platform_end: float = -INF  # Track the end of the previous platform

	# Define minimum horizontal and vertical distances
	var min_horizontal_gap: int = 100  # Minimum distance between platforms horizontally
	var max_horizontal_gap: int = 300  # Maximum horizontal gap for a varied but controlled appearance
	var min_vertical_gap: int = 70

	# Generate platforms for the chunk
	while current_x_position < start_x + chunk_size:
		# Calculate platform length and height
		var platform_length := randi_range(platform_length_range.x, platform_length_range.y) * 50
		var platform_height := randi_range(platform_height_range.x, platform_height_range.y) * platform_spacing

		# Ensure that current position is far enough from the previous platform's end
		if current_x_position < previous_platform_end + min_horizontal_gap:
			# Move the current position further to ensure no overlap
			current_x_position = previous_platform_end + min_horizontal_gap

		# Randomly select a platform scene
		var random_platform_scene: PackedScene = platform_scenes[randi_range(0, platform_scenes.size() - 1)]

		# Generate platform instance
		var platform_instance = random_platform_scene.instantiate()
		add_child(platform_instance)
		platform_instance.position = Vector2(current_x_position, platform_height)

		# Update the position for the next iteration
		previous_platform_end = current_x_position + platform_length
		current_x_position += platform_length + randi_range(min_horizontal_gap, max_horizontal_gap)

		# Add some variation to vertical positioning to avoid stacking platforms too close vertically
		var next_platform_height_offset = randi_range(-min_vertical_gap, min_vertical_gap)
		platform_height += next_platform_height_offset

		# Ensure platform height is within a reasonable range (adjust as needed)
		platform_height = clamp(platform_height, -200, 200)

	active_chunks[chunk_id] = true

func remove_chunk(chunk_id):
	# Remove all child nodes within the chunk range
	var start_x: float = chunk_id * chunk_size
	var end_x: float = start_x + chunk_size
	
	for child in get_children():
		if child is Node2D and child.position.x >= start_x and child.position.x < end_x:
			child.queue_free()
