@tool
extends EditorPlugin

var setup_button

# フォルダ構造の定義
var folders = [
		"res://assets",
		"res://assets/sprites",
		"res://assets/sprites/characters",
		"res://assets/sprites/items",
		"res://assets/sprites/ui",
		"res://assets/sprites/effects",
		"res://assets/sprites/backgrounds",
		"res://assets/sprites/tilesets",
		"res://assets/audio",
		"res://assets/audio/music",
		"res://assets/audio/sfx",
		"res://assets/audio/voice",
		"res://assets/fonts",
		"res://assets/data",
		"res://scenes",
		"res://scenes/levels",
		"res://scenes/ui",
		"res://scenes/characters",
		"res://scenes/items",
		"res://scenes/components",
		"res://src",
		"res://src/autoload",
		"res://src/utils",
		"res://addons",
		"res://_debug"
]

# プロジェクト設定の定義
var project_settings = {
	"display/window/size/viewport_width": 1280,
	"display/window/size/viewport_height": 720,
	"display/window/stretch/mode": "canvas_items",
	"display/window/stretch/aspect": "keep",
	"physics/common/physics_ticks_per_second": 60
}

func _enter_tree():
	# ボタンの作成
	setup_button = Button.new()
	setup_button.text = "プロジェクト初期設定"
	setup_button.tooltip_text = "フォルダ構造、プロジェクト設定を設定します"
	setup_button.pressed.connect(_on_setup_button_pressed)
	
	# ボタンをツールバーに追加
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, setup_button)

func _exit_tree():
	# ボタンの削除
	if setup_button:
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, setup_button)
		setup_button.queue_free()

func _on_setup_button_pressed():
	# シンプルな確認ダイアログを表示
	var dialog = ConfirmationDialog.new()
	dialog.title = "プロジェクト初期設定"
	dialog.dialog_text = "以下の初期設定を行います：\n\n- フォルダ構造の作成\n- プロジェクト設定の調整\n\n続行しますか？"
	dialog.min_size = Vector2(400, 200)
	dialog.confirmed.connect(_on_setup_confirmed.bind(dialog))
	dialog.canceled.connect(dialog.queue_free)
	
	get_editor_interface().get_base_control().add_child(dialog)
	dialog.popup_centered()

func _on_setup_confirmed(dialog):
	# フォルダ構造の作成
	create_directory_structure()
	
	# プロジェクト設定の調整
	setup_project_settings()
	
	# ダイアログを閉じる
	dialog.queue_free()
	
	# 完了メッセージを表示
	show_completion_message()

# 基本フォルダ構造を作成
func create_directory_structure():
	for path in folders:
		if not DirAccess.dir_exists_absolute(path):
			print("Creating directory: " + path)
			var err = DirAccess.make_dir_recursive_absolute(path)
			if err != OK:
				push_error("Failed to create directory: " + path)

# プロジェクト設定を調整
func setup_project_settings():
	for key in project_settings:
		ProjectSettings.set_setting(key, project_settings[key])
	
	# 設定を保存
	var err = ProjectSettings.save()
	if err != OK:
		push_error("Failed to save project settings")
	else:
		print("Project settings updated successfully")
	
# 完了メッセージを表示
func show_completion_message():
	var dialog = AcceptDialog.new()
	dialog.title = "初期設定完了"
	dialog.dialog_text = "プロジェクトの初期設定が完了しました。"
	dialog.confirmed.connect(dialog.queue_free)
	get_editor_interface().get_base_control().add_child(dialog)
	dialog.popup_centered()
