extends Control

const slot_scene: PackedScene = preload("res://Scenes/InventorySlot.tscn")
@export var max_slots: int = 40
@onready var grid: GridContainer = $Panel/GridContainer
@onready var equipment: VBoxContainer = $Panel2/VBoxContainer
@onready var player: CharacterBody2D = get_tree().root.get_node("BossArena/Player")

var slots: Array[Node] = [] # inventory slots only
var equipment_slots: Array[Node] = [] # equipment slots only

func _ready():
	# --- inventory slots ---
	for i in range(max_slots):
		var slot = slot_scene.instantiate()
		grid.add_child(slot)
		slots.append(slot)
	var grid_size = grid.get_combined_minimum_size()
	$Panel.size = grid_size
	
	# --- equipment slots ---
	_create_equipment_slot("weapon")
	_create_equipment_slot("helmet")
	_create_equipment_slot("chest")
	_create_equipment_slot("legs")
	_create_equipment_slot("accessory")
	_create_equipment_slot("accessory")
	_create_equipment_slot("accessory")
	_create_equipment_slot("accessory")
	grid_size = equipment.get_combined_minimum_size()
	$Panel2.size = grid_size
	
func _create_equipment_slot(type = "any"):
	var slot = slot_scene.instantiate()
	slot.slot_type = type
	equipment.add_child(slot)
	equipment_slots.append(slot)
	# Connect the signals to the player
	slot.item_equipped.connect(Callable(player, "_on_item_equipped"))
	slot.item_unequipped.connect(Callable(player, "_on_item_unequipped"))	

func update_inventory(inventory: Array[Item]):
	for i in range(slots.size()):
		if i < inventory.size():
			slots[i].set_item(inventory[i])
		else:
			slots[i].set_item(null)

func update_equipment(equipments: Dictionary):
	for slot in equipment_slots:
		var found_item = equipments.get(slot.slot_type, null)
		slot.set_item(found_item)
