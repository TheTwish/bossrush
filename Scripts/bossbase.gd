extends CharacterBody2D
class_name BossBase

@export var max_health: int = 100
@export var move_speed: float = 50
@export var projectile_scene: PackedScene
@export var attack_patterns: Array[Callable]   # Array of attack functions

var health: int
var phase: int = 1
var player: Node2D

@onready var attack_timer: Timer = $AttackTimer
@onready var bar: ProgressBar = get_tree().root.get_node("BossArena/UI/BossHealthBar")

func _ready() -> void:
	health = max_health
	bar.max_value = max_health
	bar.value = health
	player = get_tree().get_first_node_in_group("player")
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()

func _on_attack_timer_timeout() -> void:
	if attack_patterns.size() > 0:
		# Call one of the attacks (random or sequential)
		var attack = attack_patterns[randi() % attack_patterns.size()]
		attack.call()

func take_damage(amount: int) -> void:
	health -= amount
	bar.value = health
	# Flash red briefly
	modulate = Color(1, 0.3, 0.3)
	get_tree().create_timer(0.2).timeout.connect(func(): modulate = Color(1, 1, 1))
	if health <= 0:
		die()

func die() -> void:
	queue_free()


func _on_hitbox_body_entered(_body: Node2D) -> void:
	pass # Replace with function body.
