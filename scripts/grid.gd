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
var pending_special_pieces = []  # Array para piezas especiales pendientes

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
	if j > 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].color == color and all_pieces[i][j - 2].color == color:
				return true
	return false

func touch_input():
	if state != MOVE:
		return
		
	var mouse_pos = get_global_mouse_position()
	var grid_pos = pixel_to_grid(mouse_pos.x, mouse_pos.y)
	if Input.is_action_just_pressed("ui_touch") and in_grid(grid_pos.x, grid_pos.y):
		first_touch = grid_pos
		is_controlling = true
		print("Touch started at: ", grid_pos)
		
	# release button
	if Input.is_action_just_released("ui_touch") and in_grid(grid_pos.x, grid_pos.y) and is_controlling:
		is_controlling = false
		final_touch = grid_pos
		print("Touch ended at: ", grid_pos, " from: ", first_touch)
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
		# Marcar que se debe deducir un movimiento si este swap es válido
		deduct_move = true
		find_matches()

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	if piece_one != null and piece_two != null:
		# Intercambiar sin volver a llamar find_matches
		var temp_piece = all_pieces[last_place.x][last_place.y]
		all_pieces[last_place.x][last_place.y] = all_pieces[last_place.x + last_direction.x][last_place.y + last_direction.y]
		all_pieces[last_place.x + last_direction.x][last_place.y + last_direction.y] = temp_piece
		
		# Mover las piezas visualmente de vuelta
		piece_one.move(grid_to_pixel(last_place.x, last_place.y))
		piece_two.move(grid_to_pixel(last_place.x + last_direction.x, last_place.y + last_direction.y))
	
	state = MOVE
	move_checked = false
	deduct_move = false  # Reset deduct_move cuando el movimiento no es válido

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
	
	# Verificar game over por movimientos agotados
	if moves <= 0 and state != WAIT:
		game_over()

func find_matches():
	var matches_found = false
	var pieces_to_remove = []
	var special_pieces_to_create = []
	
	# Primero, encontrar todos los matches sin eliminar nada
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and not all_pieces[i][j].matched:
				var current_color = all_pieces[i][j].color
				
				# Verificar matches especiales primero (T-shape)
				if is_t_shape(i, j):
					special_pieces_to_create.append({
						"pos": Vector2(i + 1, j),
						"color": current_color,
						"type": "adjacent",
						"match_positions": get_t_shape_positions(i, j)
					})
					matches_found = true
					continue
				
				# Verificar matches horizontales de 5
				if i <= width - 5 and is_match(i, j, Vector2(1, 0), 5):
					special_pieces_to_create.append({
						"pos": Vector2(i + 2, j),
						"color": current_color,
						"type": "rainbow",
						"match_positions": get_line_positions(i, j, Vector2(1, 0), 5)
					})
					matches_found = true
					continue
				
				# Verificar matches verticales de 5
				if j <= height - 5 and is_match(i, j, Vector2(0, 1), 5):
					special_pieces_to_create.append({
						"pos": Vector2(i, j + 2),
						"color": current_color,
						"type": "rainbow",
						"match_positions": get_line_positions(i, j, Vector2(0, 1), 5)
					})
					matches_found = true
					continue
				
				# Verificar matches horizontales de 4
				if i <= width - 4 and is_match(i, j, Vector2(1, 0), 4):
					special_pieces_to_create.append({
						"pos": Vector2(i + 1, j),
						"color": current_color,
						"type": "row",
						"match_positions": get_line_positions(i, j, Vector2(1, 0), 4)
					})
					matches_found = true
					continue
				
				# Verificar matches verticales de 4
				if j <= height - 4 and is_match(i, j, Vector2(0, 1), 4):
					special_pieces_to_create.append({
						"pos": Vector2(i, j + 1),
						"color": current_color,
						"type": "column",
						"match_positions": get_line_positions(i, j, Vector2(0, 1), 4)
					})
					matches_found = true
					continue
				
				# Verificar matches horizontales de 3
				if i <= width - 3 and is_match(i, j, Vector2(1, 0), 3):
					pieces_to_remove.append_array(get_line_positions(i, j, Vector2(1, 0), 3))
					matches_found = true
				
				# Verificar matches verticales de 3  
				if j <= height - 3 and is_match(i, j, Vector2(0, 1), 3):
					pieces_to_remove.append_array(get_line_positions(i, j, Vector2(0, 1), 3))
					matches_found = true
	
	# PRIMERO marcar piezas normales para eliminación
	for pos in pieces_to_remove:
		if in_grid(pos.x, pos.y) and all_pieces[pos.x][pos.y] != null:
			all_pieces[pos.x][pos.y].matched = true
			all_pieces[pos.x][pos.y].dim()
	
	# DESPUÉS procesar piezas especiales
	for special in special_pieces_to_create:
		# Marcar las piezas del match para eliminación (excepto donde va la especial)
		for pos in special.match_positions:
			if pos != special.pos and in_grid(pos.x, pos.y) and all_pieces[pos.x][pos.y] != null:
				all_pieces[pos.x][pos.y].matched = true
				all_pieces[pos.x][pos.y].dim()
		
		# Agregar a pendientes en lugar de crear inmediatamente
		pending_special_pieces.append(special)

	if matches_found:
		get_parent().get_node("destroy_timer").start()
	else:
		# Si no hay matches después del swap, revertir
		if deduct_move:
			swap_back()


func get_line_positions(i, j, dir: Vector2, length: int) -> Array:
	var positions = []
	for k in range(length):
		var x = i + k * dir.x
		var y = j + k * dir.y
		positions.append(Vector2(x, y))
	return positions

func get_t_shape_positions(i, j) -> Array:
	var positions = []
	# Las 3 horizontales
	for k in range(3):
		positions.append(Vector2(i + k, j))
	# La pieza vertical que forma la T
	if in_grid(i + 1, j - 1) and all_pieces[i + 1][j - 1] != null and all_pieces[i + 1][j - 1].color == all_pieces[i][j].color:
		positions.append(Vector2(i + 1, j - 1))
	if in_grid(i + 1, j + 1) and all_pieces[i + 1][j + 1] != null and all_pieces[i + 1][j + 1].color == all_pieces[i][j].color:
		positions.append(Vector2(i + 1, j + 1))
	return positions

func crear_pieza_especial(pos: Vector2, color: String, tipo: String):
	print('Creando pieza especial: ', tipo, ' en posición: ', pos)
	
	# Crear la pieza especial
	var rand = randi_range(0, possible_pieces.size() - 1)
	var pieza_especial = possible_pieces[rand].instantiate()
	pieza_especial.color = color
	pieza_especial.set_special_type(tipo)
	
	# Asegurar que la pieza especial NO esté marcada
	pieza_especial.matched = false
	
	# Eliminar la pieza existente en esa posición si existe
	if all_pieces[pos.x][pos.y] != null:
		all_pieces[pos.x][pos.y].queue_free()
	
	# Colocar la pieza especial
	add_child(pieza_especial)
	pieza_especial.position = grid_to_pixel(pos.x, pos.y)
	all_pieces[pos.x][pos.y] = pieza_especial
	
	print('Pieza especial creada exitosamente en: ', pos, ' - Tipo: ', tipo, ' - Matched: ', pieza_especial.matched)

func marcar_match(i, j, dir, length):
	for k in range(length):
		var x = i + k * dir.x
		var y = j + k * dir.y
		if in_grid(x, y) and all_pieces[x][y] != null:
			all_pieces[x][y].matched = true
			all_pieces[x][y].dim()

func marcar_match_excepto(i, j, dir, length, except_x, except_y):
	for k in range(length):
		var x = i + k * dir.x
		var y = j + k * dir.y
		if in_grid(x, y) and all_pieces[x][y] != null and not (x == except_x and y == except_y):
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

func marcar_match_cuadrado_excepto(i, j, except_x, except_y):
	for dx in range(2):
		for dy in range(2):
			var x = i + dx
			var y = j + dy
			if in_grid(x, y) and all_pieces[x][y] != null and not (x == except_x and y == except_y):
				all_pieces[x][y].matched = true
				all_pieces[x][y].dim()
	
func destroy_matched():
	var was_matched = false
	var matched_count = 0
	print("=== DESTROY_MATCHED ===")
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				was_matched = true
				matched_count += 1
				print("Eliminando pieza en ", i, ",", j, " - Tipo: ", all_pieces[i][j].type, " - Color: ", all_pieces[i][j].color)
				# Si es una pieza especial, activar su efecto especial
				if all_pieces[i][j].type == "row":
					print("Activando efecto ROW")
					eliminar_especial(i, j, "row")
				elif all_pieces[i][j].type == "column":
					print("Activando efecto COLUMN")
					eliminar_especial(i, j, "column")
				elif all_pieces[i][j].type == "adjacent":
					print("Activando efecto ADJACENT")
					eliminar_especial(i, j, "adjacent")
				elif all_pieces[i][j].type == "rainbow":
					print("Activando efecto RAINBOW")
					eliminar_especial(i, j, "rainbow")
				else:
					# Pieza normal
					print("Eliminando pieza normal")
					all_pieces[i][j].queue_free()
					all_pieces[i][j] = null
	
	move_checked = true
	if was_matched:
		score += matched_count * 10
		emit_signal("score_changed", score)
		# Solo reducir movimientos si este es el primer match del intercambio
		if deduct_move:
			moves -= 1
			emit_signal("moves_changed", moves)
			deduct_move = false
		get_parent().get_node("collapse_timer").start()
		# Verificar game over después de actualizar moves
		if moves <= 0:
			game_over()
	else:
		# Si no hay matches después del swap, revertir inmediatamente
		swap_back()

func eliminar_especial(i, j, tipo):
	# Guardar el color antes de eliminar la pieza especial
	var color_especial = all_pieces[i][j].color
	
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
		# Eliminar todas las piezas del mismo color que la pieza rainbow
		for col in range(width):
			for row in range(height):
				if all_pieces[col][row] != null and all_pieces[col][row].color == color_especial:
					all_pieces[col][row].queue_free()
					all_pieces[col][row] = null
	
	# Eliminar la pieza especial en sí
	all_pieces[i][j] = null
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
					piece.queue_free()  # Liberar la pieza anterior
					piece = possible_pieces[rand].instantiate()
				
				# Resetear propiedades de la pieza
				piece.matched = false
				piece.type = "normal"
				piece.modulate = Color.WHITE
				
				add_child(piece)
				piece.position = grid_to_pixel(i, j - y_offset)
				piece.move(grid_to_pixel(i, j))
				# fill array with pieces
				all_pieces[i][j] = piece
				
	check_after_refill()

func crear_piezas_especiales_pendientes():
	print("Creando ", pending_special_pieces.size(), " piezas especiales pendientes")
	for special in pending_special_pieces:
		crear_pieza_especial(special.pos, special.color, special.type)
	pending_special_pieces.clear()

func check_after_refill():
	# Crear piezas especiales pendientes ANTES de buscar nuevos matches
	crear_piezas_especiales_pendientes()
	
	# Solo buscar matches automaticos si el juego sigue activo
	if state != WAIT:
		return
		
	var found_matches = false
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i, j, all_pieces[i][j].color):
				found_matches = true
				break
		if found_matches:
			break
	
	if found_matches:
		find_matches()
		# No reiniciar destroy_timer aquí, find_matches() ya lo maneja
	else:
		state = MOVE
		move_checked = false
		deduct_move = false  # Reset deduct_move cuando terminan las cadenas

func _on_destroy_timer_timeout():
	print("destroy_timer timeout - Estado actual: ", state)
	destroy_matched()

func _on_collapse_timer_timeout():
	print("collapse_timer timeout - Estado actual: ", state)
	collapse_columns()

func _on_refill_timer_timeout():
	print("refill_timer timeout - Estado actual: ", state)
	refill_columns()
	
func game_over():
	if state == WAIT:
		return  # Ya está en game over
		
	state = WAIT
	print("¡GAME OVER! Puntuación final: ", score)
	print("Movimientos restantes: ", moves)
	
	# Detener el temporizador de tiempo si existe
	var top_ui = get_parent().get_node("top_ui")
	if top_ui:
		top_ui.game_active = false
		if top_ui.time_timer:
			top_ui.time_timer.stop()
	
	# Detener todos los timers del juego
	get_parent().get_node("destroy_timer").stop()
	get_parent().get_node("collapse_timer").stop()
	get_parent().get_node("refill_timer").stop()
	
	# Aquí puedes agregar más lógica para mostrar una pantalla de game over
