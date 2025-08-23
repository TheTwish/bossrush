extends Node2D

@export var max_health: int = 100
var health: int
var phase: int = 1
var player: Node2D
@onready var attack_timer = $AttackTimer
@onready var bar = get_tree().root.get_node("BossArena/UI/BossHealthBar")
func _ready():
	health = max_health
	attack_timer.start()
	bar.max_value = max_health  # make sure bar is scaled correctly
	bar.value = health
	player = get_tree().get_first_node_in_group("player")

func _process(delta):
	# Example: chase player a little
	if player and player.is_inside_tree():
		global_position = global_position.move_toward(player.global_position, 50 * delta)

func _on_attack_timer_timeout():
	if phase == 1:
		basic_attack()
	elif phase == 2:
		crazy_attack()

func basic_attack():
	# Fire some projectiles toward the player
	for i in range(5):
		var p = preload("res://Scenes/EnemyProjectile.tscn").instantiate()
		p.global_position = global_position
		p.direction = (player.global_position - global_position).normalized().rotated(randf_range(-0.2, 0.2))
		print("Firing projectile at: ", player.global_position)
		get_parent().add_child(p)

func crazy_attack():
	# Radial bullet hell
	for angle in range(0, 360, 20):
		var p = preload("res://Scenes/EnemyProjectile.tscn").instantiate()
		p.global_position = global_position
		p.direction = Vector2.RIGHT.rotated(deg_to_rad(angle))
		get_parent().add_child(p)

func take_damage(amount: int):
	health -= amount
	bar.value = health
	if health <= max_health / 2 and phase == 1:
		phase = 2 # Switch to phase 2
	if health <= 0:
		die()

func die():
	queue_free()
