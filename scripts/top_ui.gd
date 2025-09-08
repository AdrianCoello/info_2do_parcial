extends TextureRect

@onready var score_label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label = $MarginContainer/HBoxContainer/counter_label

var current_score = 0
var current_moves = 0

func _ready():
	var grid = get_parent().get_node("grid")
	if grid:
		grid.connect("score_changed", Callable(self, "_on_score_changed"))
		grid.connect("moves_changed", Callable(self, "_on_moves_changed"))
		# Inicializar valores
		_on_score_changed(grid.score)
		_on_moves_changed(grid.moves)

func _on_score_changed(value):
	current_score = value
	score_label.text = str(current_score)

func _on_moves_changed(value):
	current_moves = value
	counter_label.text = str(current_moves)
