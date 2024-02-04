class_name HUD
extends Control

# constants
const INVENTORY_ITEM_RADIUS := 1.3
const INVENTORY_ITEM_ROTATION_SPEED := 7.0

# references
@export_category("References")
@export var player: Player
@export var heart_icon: PackedScene
@export var heart_empty_icon: PackedScene
@onready var current_hearts: HBoxContainer = %CurrentHearts
@onready var max_hearts: HBoxContainer = %MaxHearts
@onready var inventory_view: Control = %Inventory
@onready var inventory_items: Node = %InventoryItems
@onready var inventory_items_origin: Node3D = %InventoryItemsOrigin
@onready var inventory_switch_cooldown: Timer = %InventorySwitchCooldown
@onready var inventory_item_amount: Label = %InventoryItemAmount
@onready var inventory_item_name: Label = %InventoryItemName
@onready var inventory_item_description: Label = %InventoryItemDescription

# internal
var inventory_item_distance: float
var inventory_item_selected: int = 0
var ignore_macos_scroll: bool = false
@onready var new_inventory_items_origin_rotation: float = inventory_items_origin.global_position.z

func _ready() -> void:
	# update max hearts initially
	update_max_hearts()

func _physics_process(delta: float) -> void:
	# update inventory item positions
	inventory_items_origin.global_rotation.z = lerp_angle(inventory_items_origin.global_rotation.z, new_inventory_items_origin_rotation, delta * INVENTORY_ITEM_ROTATION_SPEED)

func _input(event: InputEvent) -> void:
	# open/close inventory
	if event.is_action_released("inventory"):
		if inventory_view.visible: 
			# close inventory
			SoundManager.play("Inventory", "close")
			inventory_view.visible = false
		else:
			# open inventory
			SoundManager.play("Inventory", "open")
			inventory_view.visible = true

	# next/previous item in inventory on macOS magic mouse/trackpad
	elif event is InputEventPanGesture:
		if ignore_macos_scroll and ceil(event.delta.y) == 0:
			ignore_macos_scroll = false
		if ignore_macos_scroll:
			return
		if ceil(event.delta.y) > 0:
			ignore_macos_scroll = true
			switch_inventory_item(1)
		elif ceil(event.delta.y) < 0:
			ignore_macos_scroll = true
			switch_inventory_item(-1)

	# next/previous item in inventory on anything else
	elif event.is_action_released("ui_page_up") or event.is_action_released("ui_page_down"):
		# next
		var item_change := 1

		# previous
		if event.is_action_released("ui_page_down"):
			item_change = -1

		# switch inventory item
		switch_inventory_item(item_change)

func _on_player_inventory_updated():
	# get inventory
	var inventory = player.inventory

	# get current item amount
	var item_count = inventory_items_origin.get_child_count()

	# get new item count
	var new_item_count = inventory.size()

	# hide missing items in inventory HUD
	for item in inventory_items.get_children():
		# get item id
		var item_id = (item as Pickup).item_id

		if not inventory.has(item_id):
			# hide item
			(item as Pickup).visible = false

			# remove item position representation
			if inventory_items_origin.has_node(item_id):
				inventory_items_origin.get_node(item_id).queue_free()

	# clamp selected item index
	inventory_item_selected = clamp(inventory_item_selected, 0, new_item_count - 1)

	# no items left
	if new_item_count == 0:
		# set selected item to 0
		inventory_item_selected = 0

		# clear item labels
		clear_selected_item_info()

		# do not do anything else
		return

	# add missing items from player inventory to inventory HUD
	for item_id in inventory:
		if not inventory_items.get_node(item_id).visible:
			# make item visible
			var new_item: Pickup = inventory_items.get_node(item_id)
			new_item.visible = true

			# setup position representation
			var new_item_position_representation: RemoteTransform3D = RemoteTransform3D.new()
			new_item_position_representation.name = item_id
			new_item_position_representation.remote_path = new_item.get_path()
			new_item_position_representation.update_rotation = false
			new_item_position_representation.update_scale = false
			inventory_items_origin.add_child(new_item_position_representation)

	# spread items along circle evenly, if there are new items
	if item_count != new_item_count:
		# calculate distance between items
		inventory_item_distance = 360.0 / inventory.size()

		# set item position representation position
		var item_index = 0
		for item_position_representation in inventory_items_origin.get_children():
			# calculate position
			item_position_representation.position = Vector3(INVENTORY_ITEM_RADIUS * sin(deg_to_rad(inventory_item_distance * item_index)), INVENTORY_ITEM_RADIUS * cos(deg_to_rad(inventory_item_distance * item_index)) ,0)

			# next iteration
			item_index += 1

	# update item labels
	update_selected_item_info()

func switch_inventory_item(item_change: int) -> void:
		# cooldown
		if not inventory_switch_cooldown.is_stopped():
			return

		# inventory isnt currently open
		if inventory_view.visible == false:
			return

		# only one item
		if not player.inventory.size() > 1:
			return

		# start cooldown timer
		inventory_switch_cooldown.start()

		# apply new rotation
		new_inventory_items_origin_rotation += item_change * deg_to_rad(inventory_item_distance)

		# change current selected item
		inventory_item_selected = wrap(inventory_item_selected + item_change, 0, player.inventory.size())

		# play sound
		SoundManager.play("Inventory", "switch")

		# update item labels
		update_selected_item_info()

func update_selected_item_info() -> void:
	# get item ID
	var item_id = inventory_items.get_child(inventory_item_selected).name

	# amount
	inventory_item_amount.text = str(player.inventory[item_id])

	# name
	inventory_item_name.text = str(Cache.lang["en_us"]["item"][item_id]["name"])

	# description
	inventory_item_description.text = str(Cache.lang["en_us"]["item"][item_id]["description"])

func clear_selected_item_info() -> void:
	# amount
	inventory_item_amount.text = ""

	# name
	inventory_item_name.text = ""

	# description
	inventory_item_description.text = ""

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
