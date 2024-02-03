extends Control

# references
@export_category("References")
@export var player: Player
@export var heart_icon: PackedScene
@export var heart_empty_icon: PackedScene
@onready var current_hearts: HBoxContainer = %CurrentHearts
@onready var max_hearts: HBoxContainer = %MaxHearts

func _ready() -> void:
	# update max hearts initially
	update_max_hearts()

func update_max_hearts() -> void:
	# reset heart sprites
	for heart in current_hearts.get_children():
		current_hearts.remove_child(heart)
		heart.queue_free()

	# create heart sprites
	var index = 1
	for hearts in ceil(player.max_health / 4.0):
		# create heart icon
		var heart = heart_icon.instantiate()

		# add heart icon to current hearts container
		current_hearts.add_child(heart)

		# rename heart icon
		heart.name = "Heart_" + str(index)

		# prepare for next iteration
		index += 1

	# reset max heart sprites
	for heart in max_hearts.get_children():
		max_hearts.remove_child(heart)
		heart.queue_free()

	# create max heart sprites
	index = 1
	for hearts in ceil(player.max_health / 4.0):
		# create empty heart icon
		var empty_heart = heart_empty_icon.instantiate()

		# add heart icon to current hearts container
		max_hearts.add_child(empty_heart)

		# rename heart icon
		empty_heart.name = "Empty_Heart_" + str(index)

		# prepare for next iteration
		index += 1

	# update current hearts initially
	update_current_hearts()

func update_current_hearts() -> void:
	for heart in current_hearts.get_children():
		# get heart index
		var index = heart.get_index()

		# set heart fill value
		if player.current_health > index * 4 + 3:
			(heart as TextureProgressBar).value = 4
		elif player.current_health > index * 4 + 2:
			(heart as TextureProgressBar).value = 3
		elif player.current_health > index * 4 + 1:
			(heart as TextureProgressBar).value = 2
		elif player.current_health > index * 4:
			(heart as TextureProgressBar).value = 1
		else:
			(heart as TextureProgressBar).value = 0
