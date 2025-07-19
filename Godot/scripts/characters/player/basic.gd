extends CharacterBody2D

# エクスポート変数（エディタで調整可能）
@export_group("移動設定")
@export var speed: float = 100.0
@export var run_speed: float = 300.0
@export_group("ジャンプ設定")
@export var jump_velocity: float = -300.0
@export var jump_charge_time: float = 0.3 # ジャンプ溜め時間（秒）
@export var land_lag_time: float = 0.2    # 着地溜め時間（秒）
@export_group("はしご設定")
@export var ladder_climb_speed: float = 150.0
@export var ladder_snap_threshold: float = 16.0

# 内部変数
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# ノード参照
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# 入力アクション名（定数として定義）
const INPUT_JUMP = "ui_accept"
const INPUT_LEFT = "ui_left"
const INPUT_RIGHT = "ui_right"
const INPUT_UP = "ui_up"
const INPUT_DOWN = "ui_down"
const INPUT_RUN = "run"

# アニメーション名（定数として定義）
const ANIM_IDLE = "idle"
const ANIM_WALK = "walk"
const ANIM_RUN = "run"
const ANIM_JUMP = "jump"
const ANIM_JUMP_CHARGE = "jump_charge" # ジャンプ溜めアニメーション
const ANIM_LAND_LAG = "land_lag"      # 着地ラグアニメーション
const ANIM_LADDER_CLIMB = "ladder_climb" # はしご昇降アニメーション

# 溜め・ラグ用内部変数
var jump_charge_timer: float = 0.0
var is_jump_charging: bool = false
var jump_queued: bool = false
var land_lag_timer: float = 0.0
var was_on_floor: bool = false

# はしご関連変数
var is_on_ladder: bool = false
var current_ladder: Ladder = null
var ladder_climbing: bool = false

func _physics_process(delta: float) -> void:
	if is_on_ladder:
		_handle_ladder_movement(delta)
	else:
		_apply_gravity(delta)
		_handle_jump(delta)
		_handle_horizontal_movement()
	
	move_and_slide()
	_handle_pushing() 

	
	# ここで床判定を更新
	var just_landed = is_on_floor() and not was_on_floor
	was_on_floor = is_on_floor()
	
	if not is_on_ladder:
		_handle_landing(just_landed)
	
	_update_animation()

# はしご移動処理
func _handle_ladder_movement(delta: float) -> void:
	var input_dir = Input.get_vector(INPUT_LEFT, INPUT_RIGHT, INPUT_UP, INPUT_DOWN)
	
	# 上下の入力でクライミング開始/継続
	if abs(input_dir.y) > 0.1:
		ladder_climbing = true
		
		# はしごの中央に吸着
		var ladder_center_x = current_ladder.get_ladder_center_x()
		var distance_to_center = abs(global_position.x - ladder_center_x)
		
		if distance_to_center > ladder_snap_threshold:
			# はしごの中央に向かって移動
			var snap_direction = sign(ladder_center_x - global_position.x)
			velocity.x = snap_direction * speed * 0.5
		else:
			# はしごの中央付近なら横移動を停止
			velocity.x = 0
			global_position.x = ladder_center_x
		
		# 縦移動
		velocity.y = input_dir.y * ladder_climb_speed
		
		# はしご昇降時のスプライト向き（上昇・下降で変えない）
		if input_dir.y != 0:
			animated_sprite.flip_h = false
	
	# 横移動でのはしごから離脱
	elif abs(input_dir.x) > 0.1:
		ladder_climbing = false
		velocity.x = input_dir.x * speed
		velocity.y += gravity * delta
		# スプライト反転
		animated_sprite.flip_h = input_dir.x < 0
	
	# 入力がない場合
	else:
		if ladder_climbing:
			# はしごにつかまっている状態
			velocity.x = 0
			velocity.y = 0
		else:
			# はしごから離れようとしている
			velocity.x = 0
			velocity.y += gravity * delta
	
	# ジャンプでのはしごから離脱
	if Input.is_action_just_pressed(INPUT_JUMP) and is_on_floor():
		velocity.y = jump_velocity
		ladder_climbing = false
		is_on_ladder = false
		current_ladder = null

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
	# はしご上でのアニメーション
	if is_on_ladder and ladder_climbing:
		_play_animation(ANIM_LADDER_CLIMB)
		return
	
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

# はしご設定メソッド（Ladderクラスから呼び出される）
func set_on_ladder(on_ladder: bool, ladder: Ladder):
	is_on_ladder = on_ladder
	current_ladder = ladder
	
	if not on_ladder:
		ladder_climbing = false

# move_and_slide() の後に追加
func _handle_pushing():
	var input_direction = Input.get_axis(INPUT_LEFT, INPUT_RIGHT)
	
	if abs(input_direction) > 0.1:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_collider() is PushableBox:
				var box = collision.get_collider() as PushableBox
				box.velocity.x = input_direction * 80.0  # 押す力
