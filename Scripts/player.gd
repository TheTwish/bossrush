extends CharacterBody2D

@onready var visuals: Node2D = $Visuals
@onready var weapon_holder: Node2D = $Visuals/WeaponHolder
@onready var bar: ProgressBar = get_tree().root.get_node("BossArena/UI/PlayerHealthBar")

# --- Movement and Visuals ---
@export var base_speed: float = 200
@export var base_jump_force: float = 600
@export var gravity: float = 1200
@export var max_fall_speed: float = 1500
@export var jump_cut_gravity_multiplier = 3.0
@export var coyote_time_duration: float = 0.15
@export var jump_buffer_duration: float = 0.15
@export var apex_threshold: float = 50.0
@export var apex_gravity_multiplier: float = 0.7
@export var fall_gravity_multiplier: float = 1.6

# --- Combat ---
@export var projectile_scene: PackedScene
@export var shoot_cooldown: float = 0.2
var can_shoot: bool = true
@onready var sword = weapon_holder.get_child(0)

# --- iFrames ---
@export var iframes_duration: float = 0.5
var iframes_timer: float = 0.0

# --- Health ---
var max_health: int = 100
var health: int = 100

# --- Movement helpers ---
var facing: int = 1
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_jumping: bool = false
var dropping_through: bool = false

# --- Stats system ---
var stats := {
	"speed": 1.0,           # movement speed multiplier
	"jump_force": 1.0,      # jump height multiplier
	"defense": 0,           # flat damage reduction
	"regen": 1.0,          # health per second
	"damage_mult": 1.0     # extra weapon damage %
}

# --- Regen Timer ---
var regen_timer: Timer

func _ready():
	# Collision masks
	set_collision_mask_value(5, true)
	set_collision_mask_value(6, true)

	# Set health
	health = max_health
	bar.max_value = max_health
	bar.value = health

	# Create dynamic regen timer
	regen_timer = Timer.new()
	regen_timer.wait_time = 1.0
	regen_timer.one_shot = false
	regen_timer.autostart = true
	add_child(regen_timer)
	regen_timer.connect("timeout", Callable(self, "_on_regen_tick"))
	regen_timer.start()

func _on_regen_tick() -> void:
	if health < max_health:
		health = min(health + stats["regen"], max_health)
		bar.value = health

func _physics_process(delta: float) -> void:
	# --- Facing based on mouse ---
	if !sword.swinging:
		var mouse_pos = get_global_mouse_position()
		facing = 1 if mouse_pos.x >= global_position.x else -1
		visuals.scale.x = facing

	# --- i-frames ---
	if iframes_timer > 0:
		iframes_timer -= delta

	# --- Horizontal movement ---
	var input_dir = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	velocity.x = input_dir * base_speed * stats["speed"]

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

	# --- Drop-through platforms ---
	if Input.is_action_pressed("down") and is_on_floor() and not dropping_through:
		dropping_through = true
		set_collision_mask_value(6, false)
		velocity.y = max(velocity.y, 50)
	elif dropping_through:
		if not Input.is_action_pressed("down") or not is_on_floor():
			set_collision_mask_value(6, true)
			dropping_through = false

	# --- Jumping ---
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = -base_jump_force * stats["jump_force"]
		is_jumping = true
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	# --- Gravity ---
	if not is_on_floor() or dropping_through:
		var applied_gravity = gravity
		if abs(velocity.y) < apex_threshold and velocity.y < 0:
			applied_gravity *= apex_gravity_multiplier
		elif velocity.y > 0:
			applied_gravity *= fall_gravity_multiplier

		velocity.y += applied_gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)

		if is_jumping and not Input.is_action_pressed("jump") and velocity.y < 0:
			velocity.y += gravity * (jump_cut_gravity_multiplier - 1) * delta

	if velocity.y > 0:
		is_jumping = false

	# --- Move player ---
	move_and_slide()

	# --- Shooting ---
	if Input.is_action_just_pressed("shoot") and can_shoot:
		shoot()

	# --- Melee ---
	if Input.is_action_just_pressed("melee"):
		if sword:
			sword.damage_mult = stats["damage_mult"] # modifier to sword damage from stats
			sword.swing()

func shoot():
	can_shoot = false
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()

	var p = projectile_scene.instantiate()
	p.faction = "player"
	p.collision_layer = 1 << 2
	p.collision_mask = 1 << 1
	p.spectral = true
	p.global_position = global_position
	p.direction = direction
	p.rotation = direction.angle()
	get_parent().add_child(p)

	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func take_damage(amount: int):
	if iframes_timer > 0:
		return
	var final_damage = max(amount - stats["defense"], 0)
	health -= final_damage
	bar.value = health
	print("Player HP: ", health)
	iframes_timer = iframes_duration
	if health <= 0:
		die()
	else:
		$Visuals/Sprite2D.modulate = Color(1, 0.3, 0.3)
		get_tree().create_timer(iframes_duration).timeout.connect(func(): $Visuals/Sprite2D.modulate = Color(1, 1, 1))

func die():
	print("Player died! Respawning...")
	global_position = Vector2(100, 100)
	health = max_health
	bar.value = health
