extends Node2D

@export var color: String
@export var type: String = "normal"


var matched = false

func set_special_type(new_type: String):
	type = new_type
	var tex_path = ""
	match new_type:
		"row":
			tex_path = "res://assets/pieces/%s Row.png" % color.capitalize()
		"column":
			tex_path = "res://assets/pieces/%s Column.png" % color.capitalize()
		"adjacent":
			tex_path = "res://assets/pieces/%s Adjacent.png" % color.capitalize()
		"rainbow":
			tex_path = "res://assets/pieces/Rainbow.png"
		_:
			tex_path = "res://assets/pieces/%s Piece.png" % color.capitalize()
	if ResourceLoader.exists(tex_path):
		$Sprite2D.texture = load(tex_path)

func move(target):
	var move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_ELASTIC)
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "position", target, 0.4)

func dim():
	$Sprite2D.modulate = Color(1, 1, 1, 0.5)
