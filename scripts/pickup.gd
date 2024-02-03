class_name Pickup
extends Node3D

# references
@export_category("References")
@onready var animation_player: AnimationPlayer = %AnimationPlayer

func _on_collision(body: Node3D) -> void:
	if body.is_in_group("Player"):
		# play pickup anim
		animation_player.play("Pickup")

		# play pickup sound
		SoundManager.play_on_node("Pickup", "pickup", self)

func _on_pickup_anim_end() -> void:
	# delete node after pickup
	queue_free()
