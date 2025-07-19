extends CharacterBody2D
class_name PushableBox

@export var push_force: float = 50.0
@export var stop_friction: float = 500.0
@export var normal_friction: float = 100.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var player_on_top: bool = false
var top_detector: Area2D

func _ready():
	# 上乗り検知用のArea2Dを自動作成
	top_detector = Area2D.new()
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	# 箱のCollisionShape2Dから情報を取得
	var box_collision = $CollisionShape2D
	if box_collision and box_collision.shape is RectangleShape2D:
		var box_shape = box_collision.shape as RectangleShape2D
		shape.size = Vector2(box_shape.size.x - 4, 10)  # 少し小さく、薄く
		
		collision_shape.shape = shape
		collision_shape.position = Vector2(0, -box_shape.size.y/2 - 5)  # 箱の上部
		
		top_detector.add_child(collision_shape)
		add_child(top_detector)
		
		top_detector.body_entered.connect(_on_player_entered_top)
		top_detector.body_exited.connect(_on_player_exited_top)
		

func _on_player_entered_top(body):
	if body.name == "Player":
		player_on_top = true

func _on_player_exited_top(body):
	if body.name == "Player":
		player_on_top = false

func _physics_process(delta):
	var player_pushing = false
	
	if player_on_top:
		velocity.x = 0
	else:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_collider().name == "Player":
				var input_direction = Input.get_axis("ui_left", "ui_right")
				
				if abs(input_direction) > 0.1:
					velocity.x = input_direction * push_force
					player_pushing = true
				else:
					velocity.x = move_toward(velocity.x, 0, stop_friction * delta)
					player_pushing = true
		
		if not player_pushing:
			velocity.x = move_toward(velocity.x, 0, normal_friction * delta)
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	move_and_slide()
