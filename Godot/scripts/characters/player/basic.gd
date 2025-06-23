extends CharacterBody2D

# エクスポート変数（エディタで調整可能）
@export_group("移動設定")
@export var speed: float = 150.0
@export var run_speed: float = 450.0

@export_group("ジャンプ設定")
@export var jump_velocity: float = -300.0

# 内部変数
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# ノード参照
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# 入力アクション名（定数として定義）
const INPUT_JUMP = "ui_accept"
const INPUT_LEFT = "ui_left"
const INPUT_RIGHT = "ui_right"
const INPUT_RUN = "run"

# アニメーション名（定数として定義）
const ANIM_IDLE = "idle"
const ANIM_WALK = "walk"
const ANIM_RUN = "run"
const ANIM_JUMP = "jump"

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_handle_horizontal_movement()
	_update_animation()
	move_and_slide()

# 重力処理
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

# ジャンプ処理
func _handle_jump() -> void:
	if Input.is_action_just_pressed(INPUT_JUMP) and is_on_floor():
		velocity.y = jump_velocity

# 水平移動処理
func _handle_horizontal_movement() -> void:
	var direction := Input.get_axis(INPUT_LEFT, INPUT_RIGHT)
	var is_running := Input.is_action_pressed(INPUT_RUN)
	
	if direction != 0:
		# 速度設定
		var current_speed := run_speed if is_running else speed
		velocity.x = direction * current_speed
		
		# スプライト反転
		animated_sprite.flip_h = direction < 0
	else:
		velocity.x = 0

# アニメーション更新
func _update_animation() -> void:
	if not is_on_floor():
		_play_animation(ANIM_JUMP)
		return
	
	var direction := Input.get_axis(INPUT_LEFT, INPUT_RIGHT)
	var is_running := Input.is_action_pressed(INPUT_RUN)
	
	if direction != 0:
		var animation := ANIM_RUN if is_running else ANIM_WALK
		_play_animation(animation)
	else:
		_play_animation(ANIM_IDLE)

# アニメーション再生（重複再生を避ける）
func _play_animation(animation_name: String) -> void:
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
