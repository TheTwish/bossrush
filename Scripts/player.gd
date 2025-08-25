extends CharacterBody2D

# Movement
@export var speed: float = 200
@export var jump_force: float = 600
@export var gravity: float = 1200
@export var max_fall_speed: float = 1500
@export var jump_cut_gravity_multiplier = 3.0  # gravity multiplier when jump is released early
@export var coyote_time_duration: float = 0.15  # grace period after walking off a ledge
var coyote_timer: float = 0.0
@export var jump_buffer_duration: float = 0.15    # grace period before landing
var jump_buffer_timer: float = 0.0
var is_jumping = false
var dropping_through = false
@export var apex_threshold: float = 50.0
@export var apex_gravity_multiplier: float = 0.7
@export var fall_gravity_multiplier: float = 1.6

# Shooting
@export var projectile_scene: PackedScene
@export var shoot_cooldown: float = 0.2
@export var projectile_speed: float = 400

@onready var bar: ProgressBar = get_tree().root.get_node("BossArena/UI/PlayerHealthBar")

# Health
var max_health: int = 100
var health: int = 100
var can_shoot: bool = true

func _ready():
	# Ensure collision masks are set correctly at spawn
	set_collision_mask_value(5, true)  # solid floors/walls
	set_collision_mask_value(6, true)  # drop-through platforms
	health = max_health
	bar.max_value = max_health
	bar.value = health

func _physics_process(delta: float) -> void:
	# --- Horizontal movement ---
	var input_dir = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	velocity.x = input_dir * speed

	# --- Coyote time ---
	if is_on_floor():
		coyote_timer = coyote_time_duration
	else:
		coyote_timer -= delta

	# --- Jump buffer ---
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_duration
	else:
		jump_buffer_timer -= delta

	# Drop-through platform logic
	if Input.is_action_pressed("down") and is_on_floor() and not dropping_through:
		dropping_through = true
		set_collision_mask_value(6, false)   # ignore drop-through platforms
		velocity.y = max(velocity.y, 50)    # downward nudge

	elif dropping_through:
		# Restore collisions once key released or player leaves platform
		if not Input.is_action_pressed("down") or not is_on_floor():
			set_collision_mask_value(6, true)
			dropping_through = false
	

	# --- Jumping ---
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = -jump_force
		is_jumping = true
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	# --- Apply gravity ---
	if not is_on_floor() or dropping_through:
		var applied_gravity = gravity

		# Lighter gravity near apex
		if abs(velocity.y) < apex_threshold and velocity.y < 0:
			applied_gravity *= apex_gravity_multiplier
		# Heavier gravity when falling
		elif velocity.y > 0:
			applied_gravity *= fall_gravity_multiplier

		velocity.y += applied_gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)

		# Short hop if jump released early
		if is_jumping and not Input.is_action_pressed("jump") and velocity.y < 0:
			velocity.y += gravity * (jump_cut_gravity_multiplier - 1) * delta

	# Stop jump flag when falling
	if velocity.y > 0:
		is_jumping = false

	# --- Move player ---
	move_and_slide()

	# --- Shooting ---
	if Input.is_action_just_pressed("shoot") and can_shoot:
		shoot()

func shoot():
	can_shoot = false

	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()

	var p = projectile_scene.instantiate()
	p.faction = "player"
	p.collision_layer = 1 << 2   # Player Projectile Layer 3
	p.collision_mask = 1 << 1    # Collides with Layer 2 (Boss)
	p.spectral = true
	p.global_position = global_position
	p.direction = direction
	p.rotation = direction.angle()
	get_parent().add_child(p)

	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func take_damage(amount: int):
	health -= amount
	bar.value = health
	print("Player HP: ", health)
	if health <= 0:
		die()

func die():
	print("Player died! Respawning...")
	global_position = Vector2(100, 100)
	health = 100
