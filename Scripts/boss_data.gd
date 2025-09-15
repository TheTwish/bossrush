extends Resource
class_name BossData

@export var boss_name: String
@export var boss_scene: PackedScene
@export var unlocked: bool = false
@export var loot: Array[Item] = []   # items dropped
@export var next_bosses: Array[BossData] = []  # bosses to unlock after defeating this one
