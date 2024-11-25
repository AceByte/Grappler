extends Control

@onready var labels = [
	$Label,
	$Label2,
	$Label3,
]

var formulas = [
	["Trajectory", "x = x₀ + v₀ₓt + ½aₓt²\ny = y₀ + v₀ᵧt + ½aᵧt²"],
	["Kinetic Energy", "KE = ½mv²"],
	["Potential Energy", "PE = m*g*h"],
]

func _ready():
	create_formula_labels()
	hide_formulas()

func create_formula_labels():
	for i in range(min(formulas.size(), labels.size())):
		labels[i].text = formulas[i][0] + "\n" + formulas[i][1]

func toggle_formulas(show: bool):
	if show:
		show_formulas()
	else:
		hide_formulas()

func show_formulas():
	for label in labels:
		label.visible = true

func hide_formulas():
	for label in labels:
		label.visible = false
