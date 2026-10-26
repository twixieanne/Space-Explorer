
extends Node2D

const ASTEROID_SCENE: PackedScene = preload("res://asteroid.tscn")
const LEVEL_PATH: String = "res://level2.tscn"
const SAVE_PATH: String = "user://space_explorer.cfg"

@export var spawn_interval: float = 1.5

var spawn_timer: float = 0.0
var game_paused: bool = false

var score: int = 0
var high_score: int = 0
var lives: int = 3
var game_over: bool = false

var loading_level: bool = false
var loading_label: Label

@onready var score_label: Label = $HUD/ScoreLabel
@onready var lives_label: Label = $HUD/LivesLabel
@onready var high_score_label: Label = $HUD/HighScoreLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Position the HUD labels so they do not overlap.
	score_label.position = Vector2(20, 20)
	lives_label.position = Vector2(20, 50)
	high_score_label.position = Vector2(20, 80)

	load_game()
	update_hud()

	# Spawn three asteroids at startup.
	spawn_asteroid(Vector2(250, 80))
	spawn_asteroid(Vector2(575, 80))
	spawn_asteroid(Vector2(900, 80))

	print("Space Explorer started!")
	print("Score: ", score, " | Lives: ", lives)


func _process(delta: float) -> void:
	if loading_level:
		check_level_loading()

	if game_paused or loading_level or game_over:
		return

	spawn_timer += delta

	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0

		var screen_width: float = get_viewport_rect().size.x
		var random_x: float = randf_range(40.0, screen_width - 40.0)

		spawn_asteroid(Vector2(random_x, 50.0))


func spawn_asteroid(spawn_position: Vector2) -> void:
	if game_over:
		return

	var asteroid = ASTEROID_SCENE.instantiate()

	asteroid.player_hit.connect(_on_asteroid_player_hit)
	asteroid.escaped_screen.connect(_on_asteroid_escaped)

	asteroid.position = spawn_position
	add_child(asteroid)

	print("Asteroid spawned. Total nodes: ", get_tree().get_node_count())


func _on_asteroid_player_hit() -> void:
	if game_over:
		return

	lives -= 1
	update_hud()

	print("Asteroid hit the spaceship!")
	print("Lives remaining: ", lives)

	if lives <= 0:
		end_game()


func _on_asteroid_escaped() -> void:
	if game_over:
		return

	# Earn points by successfully dodging asteroids.
	score += 10
	update_high_score(score)
	update_hud()

	print("Asteroid dodged! +10 points")
	print("Current score: ", score)


func update_hud() -> void:
	score_label.text = "Score: " + str(score)
	lives_label.text = "Lives: " + str(lives)
	high_score_label.text = "High Score: " + str(high_score)


func end_game() -> void:
	game_over = true

	print("GAME OVER! Final score: ", score)

	var game_over_label := Label.new()
	game_over_label.name = "GameOverLabel"
	game_over_label.text = "GAME OVER\nFinal Score: " + str(score)
	game_over_label.position = get_viewport_rect().size / 2.0 - Vector2(175, 50)
	game_over_label.size = Vector2(350, 100)
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.add_theme_font_size_override("font_size", 32)
	game_over_label.add_theme_color_override("font_color", Color.RED)

	$HUD.add_child(game_over_label)


func _input(event: InputEvent) -> void:
	# Escape pauses or resumes the game.
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		game_paused = not game_paused
		get_tree().paused = game_paused

		if game_paused:
			print("Game paused.")
		else:
			print("Game resumed.")

	# Press L to load Level 2 in the background.
	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_L:
			start_level_loading()


func start_level_loading() -> void:
	if loading_level:
		return

	var error := ResourceLoader.load_threaded_request(LEVEL_PATH)

	if error != OK:
		print("Could not start loading. Error code: ", error)
		return

	loading_level = true

	loading_label = Label.new()
	loading_label.text = "Loading Level 2 in background..."
	loading_label.position = Vector2(20, 120)
	loading_label.z_index = 100
	add_child(loading_label)

	print("Started threaded loading of Level 2.")


func check_level_loading() -> void:
	var status = ResourceLoader.load_threaded_get_status(LEVEL_PATH)

	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return

	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var resource: Resource = ResourceLoader.load_threaded_get(LEVEL_PATH)
		var packed_scene := resource as PackedScene

		loading_level = false

		if packed_scene != null:
			print("Level 2 loaded. Switching scenes.")
			call_deferred("_switch_to_loaded_level", packed_scene)
		else:
			print("Loaded resource is not a PackedScene.")
			remove_loading_label()

	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		loading_level = false
		print("Threaded loading failed.")
		remove_loading_label()

	elif status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		loading_level = false
		print("Invalid resource path: ", LEVEL_PATH)
		remove_loading_label()


func remove_loading_label() -> void:
	if is_instance_valid(loading_label):
		loading_label.queue_free()

	loading_label = null


func _switch_to_loaded_level(packed_scene: PackedScene) -> void:
	var error := get_tree().change_scene_to_packed(packed_scene)

	if error != OK:
		print("Could not switch scenes. Error code: ", error)


func save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "high_score", high_score)

	var error := config.save(SAVE_PATH)

	if error == OK:
		print("High score saved: ", high_score)
	else:
		print("Failed to save high score. Error code: ", error)


func load_game() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)

	if error == OK:
		high_score = int(config.get_value("game", "high_score", 0))
		print("Loaded high score: ", high_score)
	else:
		high_score = 0
		print("No saved high score yet. Starting at 0.")


func update_high_score(new_score: int) -> void:
	score = new_score

	if score > high_score:
		high_score = score
		save_game()
