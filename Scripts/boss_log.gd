extends Control

@export var boss_list: Array[BossData] = []  # assign .tres BossData entries in inspector
@onready var container: VBoxContainer = $Panel/ScrollContainer/VBoxContainer

func _ready() -> void:
	update_log()

func update_log() -> void:
	# clear children safely
	for c in container.get_children():
		c.queue_free()

	for boss in boss_list:
		var btn := Button.new()
		btn.text = boss.boss_name if boss.unlocked else "???"
		btn.disabled = not boss.unlocked
		# bind boss as an argument to the handler
		btn.pressed.connect(func(): _on_boss_selected(boss))
		container.add_child(btn)

func _on_boss_selected(boss: BossData) -> void:
	if not boss or not boss.boss_scene:
		return
	var inst = boss.boss_scene.instantiate()
	# If your boss root has an exported var `boss_data`, set it so die() can reference it
	if inst.has_method("set"): # quick check - safe guard
		if "boss_data" in inst.get_property_list().map(func(x): return x.name):
			inst.set("boss_data", boss)
	# add to scene (change spawn parent as needed)
	get_tree().current_scene.add_child(inst)
	inst.global_position = Vector2(600, 300)
