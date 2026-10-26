
extends Area2D

signal player_hit
signal escaped_screen

@export var fall_speed: float = 100.0

# Random asteroid sizes: small, medium, and large.
var size_options: Array[float] = [0.65, 1.0, 1.35]


func _ready() -> void:
	# Randomly choose the asteroid's size.
	var chosen_scale: float = size_options.pick_random()
	scale = Vector2(chosen_scale, chosen_scale)

	# Connect the collision signal through code.
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	# Move the asteroid downwards.
	position.y += fall_speed * delta

	# Remove it after it leaves the screen.
	var screen_height: float = get_viewport_rect().size.y

	if position.y > screen_height + 80.0:
		escaped_screen.emit()
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_hit.emit()
		queue_free()
