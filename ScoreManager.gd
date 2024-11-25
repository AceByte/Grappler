extends Node

# Variables to track the score and high score
var score: int = 0
var highscore: int = 0
var farthest_distance: float = 0.0

# Reference to the score label
@export var score_label: Label

# Update the score based on the player's current position
func update_score(current_position: Vector2):
	var current_distance = current_position.length()
	
	# Update the score and high score if the player moves farther
	if current_distance > farthest_distance:
		farthest_distance = current_distance
		score = int(farthest_distance)
		
		if score > highscore:
			highscore = score
	
	# Update the score label
	update_label()

# Update the label text
func update_label():
	if score_label:
		score_label.text = "Score: %d\nHigh Score: %d" % [score, highscore]
