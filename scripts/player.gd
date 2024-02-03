class_name Player
extends CharacterBody3D

# signals
signal inventory_updated

# references
@export_category("References")
@onready var camera_origin: Node3D = %CameraOrigin
@onready var character: Node3D = %Character
@onready var hitbox_horizontal: Area3D = %HitboxHorizontal
@onready var hitbox_vertical: Area3D = %HitboxVertical
@onready var animation: AnimationPlayer = %AnimationPlayer
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# properties
@export_category("Properties")
const CAMERA_SPEED := 2.0 # the speed the camera rotates per player input
const CAMERA_TARGET_SPEED := 15.0 # the speed the camera rotates to a target
const CHARACTER_ROTATION_SPEED := 5.0 # the speed the player character rotates
const MOVEMENT_SPEED := 6.0 # the speed the player character moves
const BOOST_RATE := 1.5 # the multiplier on movement speed when boosting (sprinting)
const DODGE_RATE := 1.5 # the multipler on movement speed when dodging (rolling)
const TARGET_MAX_DISTANCE := 15.0 # max positional distance an enemy can be to be targetted
@export var max_health: int = 12
@export var current_health: int = 12

# state
var committed := false # whether the player is currently commited to a movement option or not (attacking, dodging, etc.)
var targeted: Enemy # the currently targeted object
var dodge_direction: Vector3 # the direction of the current dodge roll
var inventory: Dictionary = {}

func _physics_process(delta) -> void:
	# camera
	handle_camera(delta)

	# gravity
	handle_gravity(delta)

	# determine direction using inputs and camera rotation
	var input_direction = Input.get_vector("ui_right", "ui_left", "ui_down", "ui_up").normalized()
	var new_direction = Vector3()
	new_direction += camera_origin.global_transform.basis.z * input_direction.y
	new_direction += camera_origin.global_transform.basis.x * input_direction.x

	# attacking
	handle_attack()

	# dash/dodge/roll
	handle_dodge(new_direction)

	# only run the following if not in a committed state
	if not committed:
		# horizontal velocity
		handle_movement(new_direction)

		# animation
		handle_animation(delta, new_direction)

	# apply velocity
	move_and_slide()

	# reset
	if global_position.y < -5:
		get_tree().reload_current_scene()

func handle_camera(delta: float) -> void:
	# target enemy (if there are any enemies)
	if Input.is_action_pressed("target") and get_tree().get_nodes_in_group("Enemy").size() >= 0:
		# get target
		if not targeted:
			# init closest enemy marker 
			var closest_enemy: Enemy
			var closest_enemy_distance: int

			# find closest enemy
			for enemy in get_tree().get_nodes_in_group("Enemy"):
				enemy = enemy as Enemy

				# get distance
				var distance = enemy.global_position.distance_to(self.global_position)

				# set first enemy or closer enemy
				if (distance <= TARGET_MAX_DISTANCE) and (not closest_enemy or distance < closest_enemy_distance):
					closest_enemy = enemy
					closest_enemy_distance = distance

			# set closest enemy 
			if closest_enemy:
				targeted = closest_enemy
				targeted.on_target_lock_start()

		# target found
		if targeted:
			# no longer within target distance
			if targeted.global_position.distance_to(self.global_position) > TARGET_MAX_DISTANCE:
				# remove target
				targeted.on_target_lock_end()
				targeted = null

			# still in target distance
			else:
				# rotate camera towards locked on enemy
				camera_origin.global_rotation.y = lerp_angle(camera_origin.global_rotation.y, atan2(targeted.global_position.x - self.position.x, targeted.global_position.z - self.position.z), delta * CAMERA_TARGET_SPEED)

				# dont allow rotation of the camera
				return

	# has target but not targeting
	elif targeted:
		# remove target
		targeted.on_target_lock_end()
		targeted = null

	# rotate camera left
	if Input.is_action_pressed("ui_page_left") and not Input.is_action_pressed("ui_page_right"):
		camera_origin.rotate_y(deg_to_rad(CAMERA_SPEED))

	# rotate camera right
	elif Input.is_action_pressed("ui_page_right") and not Input.is_action_pressed("ui_page_left"):
		camera_origin.rotate_y(deg_to_rad(-CAMERA_SPEED))

func handle_gravity(delta: float) -> void:
	# apply gravity to player when in the air
	if not is_on_floor():
		velocity.y -= gravity * delta

func handle_attack() -> void:
	# already committed to a state
	if committed:
		return

	# attack
	if Input.is_action_pressed("attack"):
		# stop velocity
		velocity.x = 0
		velocity.z = 0

		# attacking anim
		animation.stop()
		animation.play("player_anims/Attack Slash")

		# committed to attacking state
		committed = true

func handle_dodge(direction: Vector3) -> void:
	# already committed to a state
	if committed or not direction:
		return

	# dodge
	if Input.is_action_just_pressed("dodge"):
		# stop velocity
		velocity.x = 0
		velocity.z = 0

		# store dodge direction so that the dodge animation can use it to set velocity
		dodge_direction = direction

		# dodge anim
		animation.stop()
		if targeted:
			if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
				# side roll
				animation.play("player_anims/Roll")

				# rotate character to movement direction
				character.global_rotation.y = lerp_angle(character.global_rotation.y, atan2(direction.x, direction.z), 1)

			elif Input.is_action_pressed("ui_up"):
				# forward jump attack
				animation.play("player_anims/Attack Jump")

				# rotate character to movement direction
				character.global_rotation.y = lerp_angle(character.global_rotation.y, atan2(direction.x, direction.z), 1)

			elif Input.is_action_pressed("ui_down"):
				# sick backflip
				animation.play("player_anims/Backflip")

		else:
			# roll in any direction
			animation.play("player_anims/Roll")

			# rotate character to movement direction
			character.global_rotation.y = lerp_angle(character.global_rotation.y, atan2(direction.x, direction.z), 1)

		# committed to dodge state
		committed = true

func handle_movement(direction: Vector3) -> void:
	# calculate speed
	var speed = MOVEMENT_SPEED
	if Input.is_action_pressed("boost"):
		# ignore boost if strafing or walking backwards
		if not targeted or (targeted and (not Input.is_action_pressed("ui_left") and not Input.is_action_pressed("ui_right") and not Input.is_action_pressed("ui_down"))):
			# running
			speed *= BOOST_RATE

	# alter velocity with new direction
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

	# continue applying previous velocity
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

func handle_animation(delta: float, direction: Vector3) -> void:
	# face target
	if targeted:
		# lerp rotation of player character to enemy position
		character.global_rotation.y = lerp_angle(character.global_rotation.y, atan2(targeted.global_position.x - self.position.x, targeted.global_position.z - self.position.z), 0.5)

		# walking
		if (velocity.x != 0 or velocity.z != 0):
			# strafe left
			if Input.is_action_pressed("ui_left"):
				if animation.current_animation != "player_anims/Strafe Left":
					animation.play("player_anims/Strafe Left")

			# strage right
			elif Input.is_action_pressed("ui_right"):
				if animation.current_animation != "player_anims/Strafe Right":
					animation.play("player_anims/Strafe Right")

			# walk or run forwards
			elif Input.is_action_pressed("ui_up"):
				# run
				if Input.is_action_pressed("boost"):
					if animation.current_animation != "player_anims/Run":
						animation.play("player_anims/Run")

				#walk
				elif animation.current_animation != "player_anims/Walk":
					animation.play("player_anims/Walk")

			# walk backwards
			elif Input.is_action_pressed("ui_down"):
				if animation.current_animation != "player_anims/Walk Backwards":
					animation.play("player_anims/Walk Backwards")

		# idle
		else:
			# set animation
			if animation.current_animation != "player_anims/Idle":
				animation.play("player_anims/Idle")

	# face walk direction
	else: 
		# walking
		if (velocity.x != 0 or velocity.z != 0):
			# run animation
			if Input.is_action_pressed("boost"):
				if animation.current_animation != "player_anims/Run":
					animation.play("player_anims/Run")

			# walk animation
			elif animation.current_animation != "player_anims/Walk":
				animation.play("player_anims/Walk")

			# lerp rotation of player character to movement direction
			character.global_rotation.y = lerp_angle(character.global_rotation.y, atan2(direction.x, direction.z), delta * CHARACTER_ROTATION_SPEED)

		# idle
		else:
			# set animation
			if animation.current_animation != "player_anims/Idle":
				animation.play("player_anims/Idle")

# called when player picks up an item
func on_pickup(item_id: String, amount: int = 1) -> void:
	# add item to inventory
	if inventory.has(item_id):
		inventory[item_id] = inventory[item_id] + amount
	else:
		inventory[item_id] = amount

	# signal that player inventory has been changes
	inventory_updated.emit()

# called when an animation completes
func _on_animation_player_animation_finished(_anim_name: String) -> void:
	if committed:
		# no longer committed to state
		committed = false

# called when player is attacking during attack animation
func _on_start_hitbox(type: String) -> void:
	# get hitbox
	var hitbox = hitbox_horizontal
	if type == "vertical":
		hitbox = hitbox_vertical

	# enable hitbox
	hitbox.monitorable = true
	hitbox.monitoring = true

# called when player is done attacking during attack animation
func _on_end_hitbox(type: String) -> void:
	# get hitbox
	var hitbox = hitbox_horizontal
	if type == "vertical":
		hitbox = hitbox_vertical

	# disable hitbox
	hitbox.monitorable = false
	hitbox.monitoring = false

# called when dodge animation starts 
func _on_start_dodge() -> void:
	# velocity of dash
	velocity.x = dodge_direction.x * MOVEMENT_SPEED * DODGE_RATE
	velocity.z = dodge_direction.z * MOVEMENT_SPEED * DODGE_RATE

# called when animation needs to suddently stop the players velocity
func _on_stop_velocity() -> void:
	# stop velocity
	velocity.x = 0
	velocity.z = 0
