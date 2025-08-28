extends Node2D

@export var damage: int = 20
var damage_mult: float = 1.0
@export var swing_speed: float = 1    # how long the swing takes
@export var swing_angle: float = 180  # arc degrees
@export var sword_texture: Texture2D

@onready var pivot: Node2D = $Pivot
@onready var sprite: Sprite2D = $Pivot/Sprite2D
@onready var hitbox: Area2D = $Pivot/Sprite2D/Area2D


var swinging: bool = false

func _ready() -> void:
	if sword_texture:
		sprite.texture = sword_texture
	visible = false
	hitbox.monitoring = false
	# Start at top of swing (top-right if visuals facing right)
	pivot.rotation_degrees = -swing_angle / 2

func swing() -> void:
	if swinging:
		return
	swinging = true
	visible = true
	hitbox.monitoring = true

	var tween = get_tree().create_tween()
	# Rotate pivot from top to bottom (right side if facing right, left side if flipped)
	tween.tween_property(pivot, "rotation_degrees", -30+swing_angle, swing_speed).from(-30)
	tween.tween_callback(Callable(self, "_end_swing"))

func _end_swing() -> void:
	hitbox.monitoring = false
	visible = false
	pivot.rotation_degrees = -swing_angle / 2
	swinging = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("boss") and body.has_method("take_damage"):
		body.take_damage(int(damage * damage_mult))
		print("Deal Damage")
