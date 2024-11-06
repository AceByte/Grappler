extends Node2D

@export var platform_scene: PackedScene
@export var chunk_size := 1000
@export var platform_length_range := Vector2i(3, 10)
@export var platform_height_range := Vector2i(-3, 2)
@export var platform_spacing := 180

@export var platform_scenes := [
	preload("res://Small Platform.tscn"),
	preload("res://Big_Platform.tscn")
]



var active_chunks := {}

func _ready():
	# Generate the initial few chunks to provide a filled environment for the player to start
	generate_initial_chunks()

func _process(delta):
	# Get player's current x position
	var player_x: float = $CharacterBody2D.position.x
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

func generate_initial_chunks():
	# Generate the first few chunks so the player starts in a filled level
	for i in range(-1, 2):
		generate_chunk(i)

func generate_chunk(chunk_id):
	var start_x: int = chunk_id * chunk_size
	var current_x_position: int = start_x

	# Generate platforms for the chunk
	while current_x_position < start_x + chunk_size:
		var platform_length := randi_range(platform_length_range.x, platform_length_range.y)
		var platform_height := randi_range(platform_height_range.x, platform_height_range.y) * platform_spacing

		# Randomly select a platform scene
		var random_platform_scene: PackedScene = platform_scenes[randi_range(0, platform_scenes.size() - 1)]

		# Generate platform instance
		var platform_instance = random_platform_scene.instantiate()
		add_child(platform_instance)
		platform_instance.position = Vector2(current_x_position, platform_height)

		current_x_position += platform_spacing

	active_chunks[chunk_id] = true

func remove_chunk(chunk_id):
	# Remove all child nodes within the chunk range
	var start_x: float = chunk_id * chunk_size
	var end_x: float = start_x + chunk_size
	
	for child in get_children():
		if child.position.x >= start_x and child.position.x < end_x:
			child.queue_free()
