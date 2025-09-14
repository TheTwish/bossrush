extends CharacterBody2D

@onready var visuals: Node2D = $Visuals
@onready var weapon_holder: Node2D = $Visuals/WeaponHolder
@onready var bar: ProgressBar = get_tree().root.get_node("BossArena/UI/PlayerHealthBar")

# --- Inv system ---
var inventory: Array[Item] = []
var max_slots: int = 40
var equipment := {
	"weapon": null,
	"helmet": null,
	"body": null,
	"legs": null,
	"accessory1": null,
	"accessory2": null,
	"accessory3": null,
	"accessory4": null
}
@onready var inventory_ui = get_tree().root.get_node("BossArena/UI/InventoryUI")
var inventory_visible: bool = false
@onready var stats_label: Label = get_tree().root.get_node("BossArena/UI/InventoryUI/Stats")

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
var current_weapon_item: Item = null  # the Item resource for the equipped weapon
var current_weapon: Node = null       # the instantiated weapon scene (visual/logic)
var can_attack: bool = true

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
	
	for slot in inventory_ui.slots:
		slot.item_equipped.connect(_on_item_equipped)
		slot.item_unequipped.connect(_on_item_unequipped)

func _on_regen_tick() -> void:
	if health < max_health:
		health = min(health + stats["regen"], max_health)
		bar.value = health

func _physics_process(delta: float) -> void:
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
	
	if Input.is_action_just_pressed("inventory"):
		inventory.append(load("res://Items/Sword.tres"))
		inventory.append(load("res://Items/Helmet.tres"))
		inventory.append(load("res://Items/Bow.tres"))
		update_inventory_ui()
		inventory_ui.visible = not inventory_ui.visible
		inventory_visible = inventory_ui.visible
	
	# --- Return in inventory visible or cannot attack, continue if not ---
	if !can_attack or inventory_visible:
		return

	# --- Melee / Ranged attacks---
	if Input.is_action_just_pressed("attack") and current_weapon_item and current_weapon:
		match current_weapon_item.weapon_kind:
			"melee":
				if current_weapon.has_method("swing"):
					current_weapon.swing(self)
			"ranged":
				if current_weapon.has_method("shoot"):
					current_weapon.shoot(global_position, get_global_mouse_position(), self)


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

func update_inventory_ui():
	inventory_ui.update_inventory(inventory)
	inventory_ui.update_equipment(equipment)
	update_stats_display()

func _on_item_equipped(item: Item, slot: Control):
	equipment[slot.slot_type] = item
	print("Equipped:", item.name)

	# Apply stats
	for stat in item.stats.keys():
		if stats.has(stat):
			stats[stat] += item.stats[stat]

	# Special handling for weapon
	if slot.slot_type == "weapon":
		_set_current_weapon(item)

	update_stats_display()

func _on_item_unequipped(item: Item, slot: Control):
	equipment[slot.slot_type] = null

	for stat in item.stats.keys():
		if stats.has(stat):
			stats[stat] -= item.stats[stat]

	if slot.slot_type == "weapon":
		_set_current_weapon(null)

	update_stats_display()

func update_stats_display():
	var text = "Stats:\n"
	for stat in stats.keys():
		text += stat.capitalize() + ": " + str(stats[stat]) + "\n"
	stats_label.text = text

func _set_current_weapon(item: Item) -> void:
	# Remove old
	if current_weapon:
		current_weapon.queue_free()
		current_weapon = null
		current_weapon_item = null

	# Instantiate new weapon scene (visual/behaviour) and remember item
	if item and item.weapon_scene:
		current_weapon = item.weapon_scene.instantiate()
		weapon_holder.add_child(current_weapon)
		# reset transform so it sits in the holder predictably
		current_weapon.position = Vector2.ZERO
		current_weapon.rotation = 0.0
		current_weapon.scale = Vector2(1, 1)
		current_weapon_item = item
		print("Weapon equipped:", item.name)
