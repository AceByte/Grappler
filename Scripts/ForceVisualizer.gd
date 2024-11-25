extends Node2D

# Force vectors to be set by the player script
var gravity_force: Vector2 = Vector2.ZERO
var actual_gravity: Vector2 = Vector2.ZERO
var velocity_force: Vector2 = Vector2.ZERO
var direction_force: Vector2 = Vector2.ZERO
var grapple_force: Vector2 = Vector2.ZERO
var stress_force: Vector2 = Vector2.ZERO  # New stress arrow for rope tension

# Labels for displaying the force values
var gravity_label: Label
var actual_gravity_label: Label  # New label for actual gravity
var velocity_label: Label
var direction_label: Label
var grapple_label: Label
var stress_label: Label

# Offset for label spacing
var label_offset = Vector2(0, 30)  # Vertical spacing between labels

# Current position for placing labels
var current_label_position: Vector2 = Vector2(10, 10)

func _ready():
	# Initialize the labels
	gravity_label = $GravityLabel
	actual_gravity_label = $ActualGravityLabel  # Initialize actual gravity label
	velocity_label = $VelocityLabel
	direction_label = $DirectionLabel
	grapple_label = $GrappleLabel
	stress_label = $StressLabel

	# Enable the redraw signal
	set_process(true)

func _process(delta):
	# Redraw every frame to update arrows
	queue_redraw()

	# Reset label position at the start of each frame
	current_label_position = Vector2(10, 10)

func _draw():
	# Draw gravity arrow in red
	if gravity_force != Vector2.ZERO:
		draw_arrow(Vector2.ZERO, gravity_force * 0.1, Color(1, 0, 0))  # Scale up for longer arrow
		# Position the label next to the gravity arrow
		$GravityLabel.position = gravity_force * 0.1 + current_label_position
		$GravityLabel.text = "g: %.2f N" % gravity_force.length()  # Added units (Newtons)
		current_label_position.y += label_offset.y  # Move the next label downward

	else:
		$GravityLabel.text = ""  # Clear the label if the arrow is not shown

	# Draw actual gravity arrow in dark red
	if actual_gravity != Vector2.ZERO:
		draw_arrow(Vector2.ZERO, actual_gravity * 0.3, Color(0, 1, 1))  # Scale up for longer arrow
		# Position the label next to the actual gravity arrow
		$ActualGravityLabel.position = actual_gravity * 0.3 + current_label_position
		$ActualGravityLabel.text = "v_y: %.2f m/s" % actual_gravity.length()  # Added units (meters per second)
		current_label_position.y += label_offset.y  # Move the next label downward

	else:
		$ActualGravityLabel.text = ""  # Clear the label if the arrow is not shown

	# Draw velocity arrow in green
	if velocity_force != Vector2.ZERO:
		draw_arrow(Vector2.ZERO, velocity_force * 0.3, Color(0, 1, 0))  # Scale up for longer arrow
		# Position the label next to the velocity arrow
		$VelocityLabel.position = velocity_force * 0.3 + current_label_position
		$VelocityLabel.text = "v: %.2f m/s" % velocity_force.length()  # Added units (meters per second)
		current_label_position.y += label_offset.y  # Move the next label downward

	else:
		$VelocityLabel.text = ""  # Clear the label if the arrow is not shown

	# Draw direction arrow in yellow
	if direction_force != Vector2.ZERO:
		draw_arrow(Vector2.ZERO, direction_force * 3, Color(1, 1, 0))  # Scale up for longer arrow
		# Position the label next to the direction arrow
		$DirectionLabel.position = direction_force * 5
		$DirectionLabel.position.y = direction_force.y + 40
		$DirectionLabel.text = "d: %.2f" % direction_force.length()

	else:
		$DirectionLabel.text = ""  # Clear the label if the arrow is not shown

	# Draw grapple force arrow in blue if grappling
	if grapple_force != Vector2.ZERO:
		draw_arrow(Vector2.ZERO, grapple_force * 0.1, Color(1, 0.5, 0))  # Scale up for longer arrow
		# Position the label next to the grapple force arrow
		$GrappleLabel.position = grapple_force * 0.2 + current_label_position
		$GrappleLabel.text = "g_f: %.2f N" % grapple_force.length()  # Added units (Newtons)

	else:
		$GrappleLabel.text = ""  # Clear the label if the arrow is not shown

	# Draw stress force arrow for rope tension
	if stress_force != Vector2.ZERO:
		draw_arrow(Vector2.ZERO, stress_force * 0.3, Color(1, 0.5, 0))  # Scale up for longer arrow
		# Position the label next to the stress force arrow
		$StressLabel.position = grapple_force * 0.3 + current_label_position
		$StressLabel.text = "s: %.2f N" % stress_force.length()  # Added units (Newtons)

	else:
		$StressLabel.text = ""  # Clear the label if the arrow is not shown

func draw_arrow(start: Vector2, vector: Vector2, color: Color):
	# Draws an arrow from start in the vector direction
	var end = start + vector
	draw_line(start, end, color, 3)
	var angle = vector.angle()
	var arrowhead_size = 15
	draw_line(end, end + Vector2(cos(angle + 2.5), sin(angle + 2.5)) * +arrowhead_size, color, 2)
	draw_line(end, end + Vector2(cos(angle - 2.5), sin(angle - 2.5)) * +arrowhead_size, color, 2)
