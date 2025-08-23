extends BossBase

func _ready():
	attack_timer.wait_time = 2.0
	# Define attack patterns for this boss
	attack_patterns = [basic_attack, radial_attack]
	super._ready() # important, calls BossBase setup

func basic_attack():
	if not player: return
	for i in range(5):
		var p = projectile_scene.instantiate()
		p.faction = "enemy"
		p.collision_layer = 1 << 3    # Enemy Projectile (layer 4)
		p.collision_mask = 1 << 0   # Collides with Layer 1 (player)
		p.global_position = global_position
		p.direction = (player.global_position - global_position).normalized()
		get_parent().add_child(p)
		await get_tree().create_timer(0.2).timeout  # 0.1 second between each bullet


func radial_attack():
	for angle in range(0, 360, 30):
		var p = projectile_scene.instantiate()
		p.faction = "enemy"
		p.collision_layer = 1 << 3    # Enemy Projectile (layer 4)
		p.collision_mask = 1 << 0   # Collides with Layer 1 (player)
		p.global_position = global_position
		p.direction = Vector2.RIGHT.rotated(deg_to_rad(angle))
		get_parent().add_child(p)

func _on_attack_timer_timeout():
	var attack : Callable
	if attack_patterns.size() > 0:
		if phase == 1:
			attack = attack_patterns[0]
		elif phase == 2:
			attack = attack_patterns[1]
		else:
			attack = attack_patterns[randi() % attack_patterns.size()]
		attack.call()
