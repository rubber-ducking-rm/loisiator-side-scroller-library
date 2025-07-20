extends RigidBody2D
class_name BreakableBox

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var broken_pieces = $BrokenPieces

var is_broken = false

func _ready():
	broken_pieces.visible = false
	
	# 衝突検知を有効化
	contact_monitor = true
	max_contacts_reported = 10
	
	# プレイヤーとの衝突を検知
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if is_broken:
		return
	print(body)
	# プレイヤーかどうか確認
	if body.is_in_group("player"):
		break_box()

func break_box():
	is_broken = true
	
	sprite.visible = false
	collision.set_deferred("disabled", true)
	
	broken_pieces.visible = true
	
	for piece in broken_pieces.get_children():
		if piece is RigidBody2D:
			piece.freeze = false
			var random_force = Vector2(
				randf_range(-150, 150),
				randf_range(-200, -50)
			)
			piece.apply_impulse(random_force)
			
			# 1秒後に破片を削除
			create_tween().tween_callback(piece.queue_free).set_delay(1.0)
