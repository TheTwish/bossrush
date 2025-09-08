extends Control

@export var empty_texture: Texture2D    # background frame for empty slot
@onready var bg: TextureRect = $Background
@onready var icon: TextureRect = $Icon

@export var slot_type: String = "any"  # "any", "helmet", "body", "legs", "accessory", etc.
var item: Item = null

signal item_equipped(item: Item, slot: Control)
signal item_unequipped(item: Item, slot: Control)


func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	bg.texture = empty_texture
	icon.visible = false

func set_item(new_item: Item):
	# Only care about equip/unequip if this is an equipment slot
	var is_equipment_slot = slot_type != "any"

	# Unequip if something was here
	if item and is_equipment_slot:
		emit_signal("item_unequipped", item, self)

	item = new_item

	if item:
		icon.texture = item.icon
		icon.visible = true
		if is_equipment_slot:
			emit_signal("item_equipped", item, self)
	else:
		icon.visible = false
		icon.texture = null

	bg.texture = empty_texture

func _get_drag_data(_pos):
	if item:
		var drag_preview = TextureRect.new()
		drag_preview.texture = item.icon
		#drag_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Constrain the preview size manually
		var max_size = Vector2(64, 64)  # desired preview size
		var tex_size = item.icon.get_size()
		var scale_factor = min(max_size.x / tex_size.x, max_size.y / tex_size.y)
		drag_preview.scale = Vector2(scale_factor, scale_factor)
		
		# Pivot offset ensures the preview is centered on the cursor
		drag_preview.pivot_offset = drag_preview.texture.get_size() * 0.5 * scale_factor

		set_drag_preview(drag_preview)

		# Return both the item and the source slot
		return {"item": item, "source": self}

	return null

func _can_drop_data(_pos, data):
	return typeof(data) == TYPE_DICTIONARY and data.has("item") and can_accept(data["item"])

func _drop_data(_pos, data):
	var new_item = data["item"]
	var source_slot: Control = data["source"]

	# If this slot can't accept the new item, snap it back to the source
	if not can_accept(new_item):
		source_slot.set_item(new_item) # restore original
		return

	# Store the current item here (could be null)
	var temp = item

	# Move dragged item into this slot
	set_item(new_item)

	# Clear the source slot (the dragged item has officially moved)
	source_slot.set_item(null)

	# If there was something already here, try to return it to the source slot
	if temp:
		if source_slot.can_accept(temp):
			source_slot.set_item(temp) # valid swap
		else:
			# Snap back: return dragged item and cancel swap
			set_item(temp)
			source_slot.set_item(new_item)

func can_accept(newitem: Item) -> bool:
	if slot_type == "any":
		return true
	return newitem.type == slot_type
