extends CharacterBody2D

# エクスポート変数（エディタで調整可能）
@export_group("移動設定")
@export var speed: float = 100.0
@export var run_speed: float = 300.0

@export_group("ジャンプ設定")
@export var jump_velocity: float = -300.0
@export var jump_charge_time: float = 0.3 # ジャンプ溜め時間（秒）
@export var land_lag_time: float = 0.2    # 着地溜め時間（秒）

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
const ANIM_JUMP_CHARGE = "jump_charge" # ジャンプ溜めアニメーション
const ANIM_LAND_LAG = "land_lag"      # 着地ラグアニメーション

# 溜め・ラグ用内部変数
var jump_charge_timer: float = 0.0
var is_jump_charging: bool = false
var jump_queued: bool = false
var land_lag_timer: float = 0.0
var was_on_floor: bool = false

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump(delta)
	_handle_horizontal_movement()
	move_and_slide()
	# ここで床判定を更新
	var just_landed = is_on_floor() and not was_on_floor
	was_on_floor = is_on_floor()
	_handle_landing(just_landed)
	_update_animation()

# 着地時の処理
func _handle_landing(just_landed: bool) -> void:
	if just_landed:
		land_lag_timer = land_lag_time
		# 溜め中に着地した場合は溜め解除
		is_jump_charging = false
		jump_queued = false

# 重力処理
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

# ジャンプ処理（溜め・着地ラグ対応）
func _handle_jump(delta: float) -> void:
	# 着地ラグ中はジャンプ不可
	if land_lag_timer > 0.0:
		land_lag_timer -= delta
		return

	# ジャンプ溜め開始
	if not is_jump_charging and Input.is_action_just_pressed(INPUT_JUMP) and is_on_floor():
		is_jump_charging = true
		jump_charge_timer = jump_charge_time
		jump_queued = true

	# ジャンプ溜め中
	if is_jump_charging:
		jump_charge_timer -= delta
		if jump_charge_timer <= 0.0 and jump_queued and is_on_floor():
			velocity.y = jump_velocity
			is_jump_charging = false
			jump_queued = false
	elif not is_on_floor():
		# 空中に出たら溜め解除
		is_jump_charging = false
		jump_queued = false

# 水平移動処理
func _handle_horizontal_movement() -> void:
	# 着地ラグ中・ジャンプ溜め中は移動不可
	if land_lag_timer > 0.0 or is_jump_charging:
		velocity.x = 0
		return

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
	# 着地ラグ中は専用アニメーション
	if land_lag_timer > 0.0:
		_play_animation(ANIM_LAND_LAG)
		return

	# ジャンプ溜め中は専用アニメーション
	if is_jump_charging:
		_play_animation(ANIM_JUMP_CHARGE)
		return

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
