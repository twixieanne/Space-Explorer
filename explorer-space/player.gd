
extends CharacterBody2D

@export var speed: float = 300.0

func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO

	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")

	velocity = direction.normalized() * speed
	move_and_slide()
