extends Area2D

class_name Ladder

@export var climb_speed: float = 100.0
@export var ladder_width: float = 32.0

var players_on_ladder: Array[CharacterBody2D] = []

func _ready():
	# プレイヤーが入った時と出た時の処理
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
	if body.has_method("set_on_ladder"):
		body.set_on_ladder(true, self)
		if body not in players_on_ladder:
			players_on_ladder.append(body)

func _on_body_exited(body: Node2D):
	if body.has_method("set_on_ladder"):
		body.set_on_ladder(false, null)
		if body in players_on_ladder:
			players_on_ladder.erase(body)

func get_ladder_center_x() -> float:
	return global_position.x

func get_climb_speed() -> float:
	return climb_speed
