extends Camera2D

# プレイヤーノードの参照
@export var player: Node2D
# カメラの移動速度（0.0-1.0、1.0で即座に追従）
@export var follow_speed: float = 0.05
# カメラのオフセット位置
@export var camera_offset: Vector2 = Vector2.ZERO
# 先読み距離（プレイヤーの移動方向を予測）
@export var look_ahead_distance: float = 50.0
# 先読みの反応速度
@export var look_ahead_speed: float = 0.02
# Y軸の追従を無効化（ジャンプ時にカメラが上下しない）
@export var follow_y_axis: bool = false
# デッドゾーン（この範囲内ではカメラが動かない）
@export var dead_zone: Vector2 = Vector2(30.0, 0.0)

# 内部変数
var target_position: Vector2
var previous_player_position: Vector2
var player_velocity: Vector2
var smooth_velocity: Vector2
var base_y_position: float

func _ready():
	# プレイヤーが設定されていない場合、自動で検索
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	
	# プレイヤーが見つからない場合の警告
	if player == null:
		print("警告: プレイヤーノードが見つかりません")
		return
	
	# 初期位置設定
	global_position = player.global_position + camera_offset
	previous_player_position = player.global_position
	base_y_position = player.global_position.y + camera_offset.y

func _process(delta):
	if player == null:
		return
	
	# プレイヤーの速度計算（滑らかに）
	var current_velocity = (player.global_position - previous_player_position) / delta
	smooth_velocity = smooth_velocity.lerp(current_velocity, 0.1)
	previous_player_position = player.global_position
	
	# 先読み位置計算（水平方向のみ）
	var look_ahead = Vector2.ZERO
	if abs(smooth_velocity.x) > 5.0:  # 最小速度閾値
		look_ahead.x = smooth_velocity.normalized().x * look_ahead_distance
	
	# 目標位置設定
	var target_x = player.global_position.x + camera_offset.x + look_ahead.x
	var target_y = base_y_position
	
	# Y軸追従が有効な場合
	if follow_y_axis:
		target_y = player.global_position.y + camera_offset.y
	
	target_position = Vector2(target_x, target_y)
	
	# デッドゾーン計算
	var distance_to_target = target_position - global_position
	
	# X軸のデッドゾーン
	if abs(distance_to_target.x) < dead_zone.x:
		target_position.x = global_position.x
	
	# Y軸のデッドゾーン（Y軸追従が有効な場合のみ）
	if follow_y_axis and abs(distance_to_target.y) < dead_zone.y:
		target_position.y = global_position.y
	
	# スムーズな追従
	global_position = global_position.lerp(target_position, follow_speed)

# カメラの設定を動的に変更する関数
func set_follow_speed(speed: float):
	follow_speed = clamp(speed, 0.0, 1.0)

func set_camera_offset(new_offset: Vector2):
	camera_offset = new_offset

func set_look_ahead(distance: float, speed: float):
	look_ahead_distance = distance
	look_ahead_speed = speed

# 即座にプレイヤー位置に移動
func snap_to_player():
	if player != null:
		global_position.x = player.global_position.x + camera_offset.x
		if follow_y_axis:
			global_position.y = player.global_position.y + camera_offset.y
		else:
			global_position.y = base_y_position
