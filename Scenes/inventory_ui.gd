extends Control

@export var slot_scene: PackedScene
@export var max_slots: int = 40
@onready var grid: GridContainer = $Panel/GridContainer
@onready var equipment: VBoxContainer = $Panel2/VBoxContainer

var slots: Array[Node] = []

func _ready():
	# Create all slots on startup
	# --- inventory menu ---
	for i in range(max_slots):
		var slot = slot_scene.instantiate()
		grid.add_child(slot)
		slots.append(slot)
	var grid_size = grid.get_combined_minimum_size()
	$Panel.size = grid_size
	
	# --- equipment menu ---
	for i in range(8):
		var slot = slot_scene.instantiate()
		slot.slot_type = "none"
		equipment.add_child(slot)
		slots.append(slot)
	grid_size = equipment.get_combined_minimum_size()
	$Panel2.size = grid_size
