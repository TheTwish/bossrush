extends Resource
class_name Item

@export var name: String
@export var icon: Texture2D
@export var type: String # "weapon", "helmet", "body", "legs", "accessory", "consumable"
@export var stats: Dictionary[String, float] = {} # e.g. {"defense": 5, "damage_mult": 1.2}

# Weapon-specific
@export_enum("melee", "ranged", "none") var weapon_kind: String = "none" # defaults to none
@export var weapon_scene: PackedScene   #e.g Sword.tscn or Bow.tscn
