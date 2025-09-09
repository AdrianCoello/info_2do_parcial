extends TextureRect

@onready var score_label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label = $MarginContainer/HBoxContainer/counter_label
@onready var time_label = $MarginContainer/HBoxContainer/time_label

var current_score = 0
var current_moves = 0
var game_time = 180  # 3 minutos
var time_timer: Timer

func _ready():
	var grid = get_parent().get_node("grid")
	if grid:
		grid.connect("score_changed", Callable(self, "_on_score_changed"))
		grid.connect("moves_changed", Callable(self, "_on_moves_changed"))
		# Inicializar valores
		_on_score_changed(grid.score)
		_on_moves_changed(grid.moves)
	
	# Configurar timer para el tiempo
	time_timer = Timer.new()
	time_timer.wait_time = 1.0
	time_timer.timeout.connect(_on_time_timer_timeout)
	add_child(time_timer)
	time_timer.start()
	_update_time_display()

func _on_score_changed(value):
	current_score = value
	score_label.text = str(current_score)

func _on_moves_changed(value):
	current_moves = value
	counter_label.text = str(current_moves)

func _on_time_timer_timeout():
	game_time -= 1
	_update_time_display()
	
	if game_time <= 0:
		time_timer.stop()
		var grid = get_parent().get_node("grid")
		if grid:
			grid.game_over()

func _update_time_display():
	var minutes = game_time / 60
	var seconds = game_time % 60
	time_label.text = "%d:%02d" % [minutes, seconds]
