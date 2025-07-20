extends RigidBody2D

@export var speed: float = 500.0
@export var lifetime: float = 5.0

@onready var life_timer: Timer = $LifeTimer
@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	# タイマー設定
	life_timer.wait_time = lifetime
	life_timer.one_shot = true
	life_timer.timeout.connect(_on_lifetime_expired)
	life_timer.start()
	
	# 重力の設定
	gravity_scale = 1.0

func launch(direction: Vector2):
	# 発射方向に力を加える
	apply_central_impulse(direction.normalized() * speed)

func _on_lifetime_expired():
	# 寿命が切れたら削除
	queue_free()

func _on_body_entered(body):
	# 何かに当たったら削除（必要に応じて）
	if body != self:
		queue_free()
