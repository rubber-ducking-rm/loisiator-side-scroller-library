extends Node2D

@export var cannon_ball_scene: PackedScene = preload("res://scenes/objects/CannonBall.tscn")
@export var fire_rate: float = 1.0  # 秒間隔
@export var fire_force: float = 500.0
@export var fire_angle: float = -45.0  # 発射角度（度）
@export var auto_fire: bool = true

@onready var cannon_body: Sprite2D = $CannonBody
@onready var cannon_barrel: Sprite2D = $CannonBody/CannonBarrel
@onready var fire_point: Marker2D = $CannonBody/CannonBarrel/FirePoint
@onready var fire_timer: Timer = $FireTimer

var target_position: Vector2

func _ready():
	# タイマー設定
	fire_timer.wait_time = fire_rate
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	
	if auto_fire:
		fire_timer.start()
	
	# 砲身の角度を設定
	cannon_barrel.rotation_degrees = fire_angle

func _on_fire_timer_timeout():
	fire_cannon_ball()

func fire_cannon_ball():
	if cannon_ball_scene == null:
		return
	
	# 砲弾を生成
	var cannon_ball = cannon_ball_scene.instantiate()
	get_tree().current_scene.add_child(cannon_ball)
	
	# 発射位置に配置
	cannon_ball.global_position = fire_point.global_position
	
	# 発射方向を計算
	var fire_direction = Vector2.from_angle(deg_to_rad(fire_angle))
	
	# 砲弾を発射
	cannon_ball.launch(fire_direction * fire_force)

func set_fire_angle(angle: float):
	fire_angle = angle
	cannon_barrel.rotation_degrees = angle

func set_target(target_pos: Vector2):
	target_position = target_pos
	# ターゲットに向けて角度を調整
	var direction = (target_pos - global_position).normalized()
	var angle = rad_to_deg(direction.angle())
	set_fire_angle(angle)

func start_firing():
	fire_timer.start()

func stop_firing():
	fire_timer.stop()
