extends Node2D

# state machine
enum {WAIT, MOVE}
var state

# grid
@export var width: int
@export var height: int
@export var x_start: int
@export var y_start: int
@export var offset: int
@export var y_offset: int

# piece array
var possible_pieces = [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/light_green_piece.tscn"),
	preload("res://scenes/pink_piece.tscn"),
	preload("res://scenes/yellow_piece.tscn"),
	preload("res://scenes/orange_piece.tscn"),
]
# current pieces in scene
var all_pieces = []

# swap back
var piece_one = null
var piece_two = null
var last_place = Vector2.ZERO
var last_direction = Vector2.ZERO
var move_checked = false

# touch variables
var first_touch = Vector2.ZERO
var final_touch = Vector2.ZERO
var is_controlling = false

# scoring variables and signals
var score := 0
signal score_changed(value)
signal moves_changed(value)
var moves := 15
var special_types = {
	"row": null,
	"column": null,
	"adjacent": null,
	"rainbow": null
}
var piece_types = ["normal", "row", "column", "adjacent", "rainbow"]
var deduct_move := false

# Called when the node enters the scene tree for the first time.
func _ready():
	state = MOVE
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array
	
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start - offset * row
	return Vector2(new_x, new_y)
	
func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)
	
func in_grid(column, row):
	return column >= 0 and column < width and row >= 0 and row < height
	
func spawn_pieces():
	for i in width:
		for j in height:
			# random number
			var rand = randi_range(0, possible_pieces.size() - 1)
			# instance 
			var piece = possible_pieces[rand].instantiate()
			# repeat until no matches
			var max_loops = 100
			var loops = 0
			while (match_at(i, j, piece.color) and loops < max_loops):
				rand = randi_range(0, possible_pieces.size() - 1)
				loops += 1
				piece = possible_pieces[rand].instantiate()
			add_child(piece)
			piece.position = grid_to_pixel(i, j)
			# fill array with pieces
			all_pieces[i][j] = piece

func match_at(i, j, color):
	# check left
	if i > 1:
		if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null:
			if all_pieces[i - 1][j].color == color and all_pieces[i - 2][j].color == color:
				return true
	# check down
	if j> 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].color == color and all_pieces[i][j - 2].color == color:
				return true

func touch_input():
	var mouse_pos = get_global_mouse_position()
	var grid_pos = pixel_to_grid(mouse_pos.x, mouse_pos.y)
	if Input.is_action_just_pressed("ui_touch") and in_grid(grid_pos.x, grid_pos.y):
		first_touch = grid_pos
		is_controlling = true
		
	# release button
	if Input.is_action_just_released("ui_touch") and in_grid(grid_pos.x, grid_pos.y) and is_controlling:
		is_controlling = false
		final_touch = grid_pos
		touch_difference(first_touch, final_touch)

func swap_pieces(column, row, direction: Vector2):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	if first_piece == null or other_piece == null:
		return
	# swap
	state = WAIT
	store_info(first_piece, other_piece, Vector2(column, row), direction)
	all_pieces[column][row] = other_piece
	all_pieces[column + direction.x][row + direction.y] = first_piece
	#first_piece.position = grid_to_pixel(column + direction.x, row + direction.y)
	#other_piece.position = grid_to_pixel(column, row)
	first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
	other_piece.move(grid_to_pixel(column, row))
	if not move_checked:
		find_matches()

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = MOVE
	move_checked = false

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	# should move x or y?
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))
	if abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))

func _process(delta):
	if state == MOVE:
		touch_input()

func find_matches():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				continue
			var color = all_pieces[i][j].color
			# 5 en línea (multicolor)
			if is_match(i, j, Vector2(1, 0), 5):
				marcar_match(i, j, Vector2(1, 0), 5)
				all_pieces[i+2][j].set_special_type("rainbow")
			elif is_match(i, j, Vector2(0, 1), 5):
				marcar_match(i, j, Vector2(0, 1), 5)
				all_pieces[i][j+2].set_special_type("rainbow")
			# 4 en línea (raya)
			elif is_match(i, j, Vector2(1, 0), 4):
				marcar_match(i, j, Vector2(1, 0), 4)
				all_pieces[i+1][j].set_special_type("row")
			elif is_match(i, j, Vector2(0, 1), 4):
				marcar_match(i, j, Vector2(0, 1), 4)
				all_pieces[i][j+1].set_special_type("column")
			# 4 en cuadrado (bomba)
			elif match_cuadrado(i, j):
				marcar_match_cuadrado(i, j)
				all_pieces[i][j].set_special_type("adjacent")
			# 3 en línea
			elif is_match(i, j, Vector2(1, 0), 3):
				marcar_match(i, j, Vector2(1, 0), 3)
			elif is_match(i, j, Vector2(0, 1), 3):
				marcar_match(i, j, Vector2(0, 1), 3)
	get_parent().get_node("destroy_timer").start()

func marcar_match(i, j, dir, length):
	for k in range(length):
		var x = i + k * dir.x
		var y = j + k * dir.y
		if in_grid(x, y) and all_pieces[x][y] != null:
			all_pieces[x][y].matched = true
			all_pieces[x][y].dim()

func match_cuadrado(i, j):
	# Detecta 2x2 cuadrado
	if in_grid(i+1, j) and in_grid(i, j+1) and in_grid(i+1, j+1):
		var c = all_pieces[i][j].color
		return (
			all_pieces[i+1][j] != null and all_pieces[i][j+1] != null and all_pieces[i+1][j+1] != null and
			all_pieces[i+1][j].color == c and all_pieces[i][j+1].color == c and all_pieces[i+1][j+1].color == c
		)
	return false

func marcar_match_cuadrado(i, j):
	for dx in range(2):
		for dy in range(2):
			var x = i + dx
			var y = j + dy
			if in_grid(x, y) and all_pieces[x][y] != null:
				all_pieces[x][y].matched = true
				all_pieces[x][y].dim()
	
func destroy_matched():
	var was_matched = false
	var matched_count = 0
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				was_matched = true
				matched_count += 1
				if all_pieces[i][j].type != "normal":
					eliminar_especial(i, j, all_pieces[i][j].type)
				else:
					all_pieces[i][j].queue_free()
					all_pieces[i][j] = null
	move_checked = true
	if was_matched:
		score += matched_count * 10
		emit_signal("score_changed", score)
		moves -= 1 if deduct_move else 0
		if deduct_move:
			emit_signal("moves_changed", moves)
			deduct_move = false
		get_parent().get_node("collapse_timer").start()
		if moves <= 0:
			game_over()
	else:
		swap_back()

func eliminar_especial(i, j, tipo):
	if tipo == "row":
		for col in range(width):
			if all_pieces[col][j] != null:
				all_pieces[col][j].queue_free()
				all_pieces[col][j] = null
	elif tipo == "column":
		for row in range(height):
			if all_pieces[i][row] != null:
				all_pieces[i][row].queue_free()
				all_pieces[i][row] = null
	elif tipo == "adjacent":
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var x = i + dx
				var y = j + dy
				if in_grid(x, y) and all_pieces[x][y] != null:
					all_pieces[x][y].queue_free()
					all_pieces[x][y] = null
	elif tipo == "rainbow":
		var color = all_pieces[i][j].color
		for col in range(width):
			for row in range(height):
				if all_pieces[col][row] != null and all_pieces[col][row].color == color:
					all_pieces[col][row].queue_free()
					all_pieces[col][row] = null
func is_match(i, j, dir: Vector2, length: int) -> bool:
	if all_pieces[i][j] == null:
		return false
	var color = all_pieces[i][j].color
	for k in range(1, length):
		var x = i + k * dir.x
		var y = j + k * dir.y
		if not in_grid(x, y):
			return false
		if all_pieces[x][y] == null or all_pieces[x][y].color != color:
			return false
	return true

func is_t_shape(i, j) -> bool:
	return (
		is_match(i, j, Vector2(1, 0), 3) and (
			(j > 0 and all_pieces[i + 1][j - 1] != null and all_pieces[i + 1][j - 1].color == all_pieces[i][j].color) or
			(j < height - 1 and all_pieces[i + 1][j + 1] != null and all_pieces[i + 1][j + 1].color == all_pieces[i][j].color)
		)
	)

func is_l_shape(i, j) -> bool:
	return (
		is_match(i, j, Vector2(1, 0), 3) and (
			(j > 0 and all_pieces[i + 2][j - 1] != null and all_pieces[i + 2][j - 1].color == all_pieces[i][j].color) or
			(j < height - 1 and all_pieces[i + 2][j + 1] != null and all_pieces[i + 2][j + 1].color == all_pieces[i][j].color)
		)
	)
func show_game_over_screen():
	print("GAME OVER")
	get_tree().paused = true

func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				print(i, j)
				# look above
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node("refill_timer").start()

func refill_columns():
	
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				# random number
				var rand = randi_range(0, possible_pieces.size() - 1)
				# instance 
				var piece = possible_pieces[rand].instantiate()
				# repeat until no matches
				var max_loops = 100
				var loops = 0
				while (match_at(i, j, piece.color) and loops < max_loops):
					rand = randi_range(0, possible_pieces.size() - 1)
					loops += 1
					piece = possible_pieces[rand].instantiate()
				add_child(piece)
				piece.position = grid_to_pixel(i, j - y_offset)
				piece.move(grid_to_pixel(i, j))
				# fill array with pieces
				all_pieces[i][j] = piece
				
	check_after_refill()

func check_after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i, j, all_pieces[i][j].color):
				find_matches()
				get_parent().get_node("destroy_timer").start()
				return
	state = MOVE
	
	move_checked = false

func _on_destroy_timer_timeout():
	print("destroy")
	destroy_matched()

func _on_collapse_timer_timeout():
	print("collapse")
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()
	
func game_over():
	state = WAIT
	print("game over")
