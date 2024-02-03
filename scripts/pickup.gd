class_name Pickup
extends Node3D

# references
@export_category("References")
@onready var model: Node3D = %Model
@onready var animation_player: AnimationPlayer = %AnimationPlayer

# properties
@export_category("Properties")
@export var item_id: String

# options
@export_category("Options")
@export var inventory_view: bool = false

func _ready() -> void:
	if inventory_view:
		model.position.y = 0

	else:
		animation_player.play("Spin")

func _on_collision(body: Node3D) -> void:
	if body is Player:
		# play pickup anim
		animation_player.play("Pickup")

		# play pickup sound
		SoundManager.play("Pickup", "pickup")

		# give player item
		body.on_pickup(item_id)

func _on_pickup_anim_end() -> void:
	# delete node after pickup
	queue_free()
