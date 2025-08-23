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

func _ready():
	
	health = max_health
	bar.max_value = max_health
	bar.value = health
	player = get_tree().get_first_node_in_group("player")
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()

func _process(delta):
	if player and player.is_inside_tree():
		global_position = global_position.move_toward(player.global_position, move_speed * delta)

func _on_attack_timer_timeout():
	if attack_patterns.size() > 0:
		# Call one of the attacks (random or sequential)
		var attack = attack_patterns[randi() % attack_patterns.size()]
		attack.call()

func take_damage(amount: int):
	health -= amount
	bar.value = health
	if health <= max_health / 2 and phase == 1:
		phase = 2
	if health <= 0:
		die()

func die():
	queue_free()
