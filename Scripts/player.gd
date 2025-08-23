extends CharacterBody2D

@export var speed: float = 200
@export var projectile_scene: PackedScene
@export var shoot_cooldown: float = 0.2
@export var projectile_speed: float = 400
var health: int = 100

var can_shoot: bool = true

func _physics_process(_delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	velocity = input_vector.normalized() * speed
	move_and_slide()

	if Input.is_action_just_pressed("shoot") and can_shoot:
		shoot()

func shoot():
	can_shoot = false

	# Get the global mouse position
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()

	# Spawn projectile
	var p = projectile_scene.instantiate()
	p.faction = "player"
	p.collision_layer = 1 << 2  # Player Projectile Layer 3
	p.collision_mask = 1 << 1 # Collides with Layer 2 (Boss)
	p.spectral = true # testing, can now make projectiles spectral or not on spawn
	p.global_position = global_position
	p.direction = direction
	p.rotation = direction.angle()  # orient the sprite
	get_parent().add_child(p)

	# Cooldown
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func take_damage(amount: int):
	health -= amount
	print("Player HP: ", health)
	if health <= 0:
		die()

func die():
	print("Player died! Respawning...")
	# For now, just reset position
	global_position = Vector2(100, 100)
	health = 100
