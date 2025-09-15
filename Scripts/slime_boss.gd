extends BossBase

# Movement
@export var hop_speed: float = 300        # horizontal hop speed
@export var hop_height: float = 600       # initial vertical velocity
@export var hop_interval: float = 1.5     # time between hops
@export var gravity: float = 800
@export var drop_through_layer: int = 6   # Layer for drop-through platforms

var hop_timer: float = 0.0
var is_hopping: bool = false
var hop_velocity: Vector2 = Vector2.ZERO
var dropping_through: bool = false

func _ready() -> void:
	super._ready()
	hop_timer = hop_interval
	# Ensure drop-through layer collisions are enabled initially
	set_collision_mask_value(drop_through_layer, true)

func _physics_process(delta: float) -> void:
	if not player:
		return

	# --- Hop cooldown ---
	hop_timer -= delta
	if hop_timer <= 0 and not is_hopping:
		_start_hop()

	# --- Platform collision logic ---
	var player_below = player.global_position.y > global_position.y+150

	if is_hopping:
		if hop_velocity.y < 0:
			# Boss is moving up → ignore platforms
			set_collision_mask_value(drop_through_layer, false)
		elif player_below and _needs_to_drop_through():
			# Boss falling and player is below → drop through
			set_collision_mask_value(drop_through_layer, false)
			dropping_through = true
		else:
			# Boss falling, player not below → collide normally
			set_collision_mask_value(drop_through_layer, true)
			dropping_through = false
	else:
		# Not hopping → collide normally
		set_collision_mask_value(drop_through_layer, true)
		dropping_through = false

	# --- Apply gravity ---
	if not is_on_floor() or dropping_through:
		hop_velocity.y += gravity * delta
		hop_velocity.y = min(hop_velocity.y, gravity * 2)  # clamp fall speed

	# --- Move the boss ---
	velocity = hop_velocity
	move_and_slide()

	# --- Reset hop when landing ---
	if is_on_floor() and is_hopping:
		is_hopping = false
		hop_timer = hop_interval
		hop_velocity = Vector2.ZERO
		dropping_through = false


func _start_hop() -> void:
	is_hopping = true
	hop_timer = hop_interval
	var dir = (player.global_position - global_position).normalized()
	var random_factor = randf_range(0.3, 1.0)  # ±15% variation
	hop_velocity.x = dir.x * hop_speed * random_factor  # horizontal speed
	hop_velocity.y = -hop_height        # vertical speed

func _needs_to_drop_through() -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.new()
	query.from = global_position
	query.to = global_position + Vector2(0, 20)
	query.exclude = [self]
	query.collision_mask = 1 << (drop_through_layer - 1)
	return space_state.intersect_ray(query) != null

func _is_platform_below() -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.new()
	query.from = global_position
	query.to = global_position + Vector2(0, 10)  # short ray
	query.exclude = [self]
	query.collision_mask = 1 << (drop_through_layer - 1)
	return space_state.intersect_ray(query) != null

func _drop_through_platform() -> void:
	dropping_through = true
	set_collision_mask_value(drop_through_layer, false)

func _restore_platform_collision() -> void:
	set_collision_mask_value(drop_through_layer, true)
	dropping_through = false

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(10)

func take_damage(amount: int) -> void:
	super.take_damage(amount)
	if health <= max_health / 2.0 and phase == 1:
		_enter_phase2()

func _enter_phase2() -> void:
	phase = 2
	hop_speed *= 1.5
	hop_height *= 1.2
	hop_interval *= 0.7
	print("King Slime Phase 2!")
