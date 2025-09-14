extends Area2D

@export var speed: float = 300
@export var faction: String = "player"  # or "enemy"
@export var damage: int = 10
var spectral := false
var direction: Vector2 = Vector2.ZERO

func get_damage() -> int:
	return int(damage)
	
func set_damage(m: int) -> void:
	damage = m

func _ready():
	# Automatically despawn after 5 seconds
	rotation = direction.angle() + deg_to_rad(90)
	if !spectral:
		collision_mask = collision_mask | 1 << 4 # add floors/walls to collision mask
	async_despawn(5.0)

func _process(delta: float) -> void:
	if direction != Vector2.ZERO:
		global_position += direction.normalized() * speed * delta

func _on_body_entered(body: Node) -> void:
	if faction == "player" and body.is_in_group("boss") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	elif faction == "enemy" and body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	elif body.is_in_group("floor"):
		queue_free()

func async_despawn(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	queue_free()
