extends BossBase

@export var speed: float = 150
@export var dash_speed: float = 600
@export var circle_radius: float = 400
@export var dash_cooldown: float = 2.0
@export var dash_duration: float = 1 

var state: String = "circle"
var dash_timer: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO
var dash_time_left: float = 0.0

func _ready() -> void:
	super._ready()
	phase = 1
	dash_timer = dash_cooldown

func _physics_process(delta: float) -> void:
	match state:
		"circle":
			_circle_player(delta)
			dash_timer -= delta
			if dash_timer <= 0:
				_prepare_dash()
		"dash":
			_perform_dash(delta)


func _circle_player(_delta: float) -> void:
	if not player:
		return

	# Vector from player to boss
	var to_boss = global_position - player.global_position
	var dist = to_boss.length()

	var radial_correction = (circle_radius - dist)
	if abs(radial_correction) > 5:
		radial_correction *= 0.5
	else:
		radial_correction = 0
	var dir = to_boss.orthogonal().normalized()
	velocity = dir * speed + to_boss.normalized() * radial_correction
	move_and_slide()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(10)

func _prepare_dash() -> void:
	if not player:
		return
	dash_dir = (player.global_position - global_position).normalized()
	dash_timer = dash_cooldown
	dash_time_left = dash_duration
	state = "dash"

func _perform_dash(delta: float) -> void:
	velocity = dash_dir * dash_speed
	move_and_slide()

	dash_time_left -= delta
	if dash_time_left <= 0:
		state = "circle"
		
func take_damage(amount: int) -> void:
	# Call base class damage handling (health, bar update, death check)
	super.take_damage(amount)

	# Phase 2 transition
	if health <= max_health / 2.0 and phase == 1:
		_enter_phase2()

func _enter_phase2() -> void:
	print("Phase 2")
	phase = 2
	speed *= 1.3
	dash_cooldown *= 0.5
	dash_duration *= 1
