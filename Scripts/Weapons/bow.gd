extends Node2D

@export var projectile_scene: PackedScene
var damage: int = 10

func shoot(origin: Vector2, target: Vector2, player: Node):
	var projectile = projectile_scene.instantiate()
	# Apply player damage multiplier
	projectile.damage = int(damage * player.stats["damage_mult"])
	# Position + direction
	projectile.global_position = origin
	projectile.direction = (target - origin).normalized()
	projectile.faction = "player"
	projectile.collision_layer = 1 << 2    # Friendly Projectile (layer 3)
	projectile.collision_mask = 1 << 1   # Collides with Layer 2 (Boss/Enemies)
	get_tree().current_scene.add_child(projectile)
