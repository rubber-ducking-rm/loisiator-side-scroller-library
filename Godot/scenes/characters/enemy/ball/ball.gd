extends RigidBody2D

@export var speed: float = 300.0

func _ready():
	setup_simple_glow()
	$VisibilityNotifier2D.screen_exited.connect(_on_screen_exited)
	linear_velocity = Vector2(0, speed)

func setup_simple_glow():
	# 白い球のテクスチャを設定
	$Sprite2D.texture = create_white_ball()
	
	# 発光効果
	$Sprite2D.modulate = Color(2.0, 2.0, 2.0, 1.0)  # 白を強調
	
	# 脈打つような光の効果
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property($Sprite2D, "modulate", Color(3.0, 3.0, 3.0, 1.0), 0.5)
	tween.tween_property($Sprite2D, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.5)

func create_white_ball():
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var center = Vector2(32, 32)
	
	for y in range(64):
		for x in range(64):
			var distance = center.distance_to(Vector2(x, y))
			if distance <= 30:
				# 中心から端にかけてのグラデーション
				var intensity = 1.0 - (distance / 30.0)
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, intensity))
	
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	return texture

func _on_screen_exited():
	queue_free()
