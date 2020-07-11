# Copyright Péter Magyar relintai@gmail.com
# MIT License, functionality from this class needs to be protable to the entity spell system

# Copyright (c) 2019-2020 Péter Magyar

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

extends KinematicBody2D

export(float) var MOUSE_SENSITIVITY : float = 0.05
export(String) var world_path : String = "../.."
export(NodePath) var model_path : NodePath = "Rotation_Helper/Model"
export(NodePath) var character_skeleton_path : NodePath = "Character"

const BASE_SPEED = 60.0

const ray_length = 1000
const ACCEL : float = 100.0
const DEACCEL : float = 100.0

const MOUSE_TARGET_MAX_OFFSET : int = 10

var _on : bool = true

var y_rot : float = 0.0

var vel : Vector2 = Vector2()
var dir : Vector2 = Vector2()

var input_dir : Vector2 = Vector2()
var mouse_dir : Vector2 = Vector2()
var mouse_move_dir : Vector2 = Vector2()
var mouse_left_down : bool = false
var mouse_right_down : bool = false
var touchpad_dir : Vector2 = Vector2()
var mouse_down_delta : Vector2 = Vector2()

var key_left : bool = false
var key_right : bool = false
var key_up : bool = false
var key_down : bool = false

var cursor_grabbed : bool = false
var last_cursor_pos : Vector2 = Vector2()
var mouse_down_pos : Vector2 = Vector2()
var total_down_mouse_delta : Vector2 = Vector2()
var target_movement_direction : Vector2 = Vector2()

var camera : Camera2D

var animation_run : bool = false

var moving : bool = false
var casting_anim : bool = false

var last_mouse_over : Entity = null

var world : Node2D = null

var _controlled : bool = false

var sleep : bool = false
var sleep_recheck_timer : float = 0
var dead : bool = false
var death_timer : float = 0

var entity : Entity
var character_skeleton : CharacterSkeleton2D 

var visibility_update_timer : float = 0

func _enter_tree() -> void:
	world = get_node(world_path) as Node2D
	camera = get_node_or_null("Camera") as Camera2D
	
	character_skeleton = get_node(character_skeleton_path)
	entity = get_node("..")
	entity.set_character_skeleton(character_skeleton)
#	entity.connect("notification_ccast", self, "on_notification_ccast")
	entity.connect("diesd", self, "on_diesd")
	entity.connect("isc_controlled_changed", self, "on_c_controlled_changed")
	owner = entity

	on_c_controlled_changed(entity.c_is_controlled)
	
	transform = entity.get_transform_2d(true)

	set_physics_process(true)

func _process(delta : float) -> void:
	if entity.ai_state == EntityEnums.AI_STATE_OFF:
		return
		
	visibility_update_timer += delta
	
	if visibility_update_timer < 1:
		return
		
	visibility_update_timer = 0
	
#	var camera : Camera = get_tree().get_root().get_camera() as Camera
#
#	if camera == null:
#		return
#
#	var cam_pos : Vector3 = camera.global_transform.xform(Vector3())
#	var dstv : Vector3 = cam_pos - translation
#	dstv.y = 0
#	var dst : float = dstv.length_squared()
#
#	if dst > max_visible_distance_squared:
#		if visible:
#			hide()
#		return
#	else:
##		var lod_level : int = int(dst / max_visible_distance_squared * 3.0)
#
#		if dst < 400: #20^2
#			character_skeleton.set_lod_level(0)
#		elif dst > 400 and dst < 900: #20^2, 30^2
#			character_skeleton.set_lod_level(1)
#		else:
#			character_skeleton.set_lod_level(2)
#
#		if not visible:
#			show()


func _physics_process(delta : float) -> void:
	if not _on:
		return
		
	if world.initial_generation:
		return
		
	if entity.sentity_data == null:
		return
		
	if dead:
		return
		
	if entity.c_is_controlled:
		process_input(delta)
		process_movement_player(delta)
	else:
		if sleep:
			sleep_recheck_timer += delta
			
			if sleep_recheck_timer < 0.5:
				return
				
			sleep_recheck_timer = 0
		
#		if world != null:
#			if not world.is_position_walkable(transform.origin):
#				return

		process_movement_mob(delta)

func process_input(delta: float) -> void:
	var key_dir : Vector2 = Vector2()
	
	if key_up:
		key_dir.y -= 1
	if key_down:
		key_dir.y += 1
	if key_left:
		key_dir.x -= 1
	if key_right:
		key_dir.x += 1
		
	input_dir = key_dir + mouse_dir + touchpad_dir + mouse_move_dir
	
	var state : int = entity.getc_state()
	
	if state & EntityEnums.ENTITY_STATE_TYPE_FLAG_ROOT != 0 or state & EntityEnums.ENTITY_STATE_TYPE_FLAG_STUN != 0:
		input_dir = Vector2()
		return
	
	var input_length : float = input_dir.length_squared()
	
	if input_length > 0.1:
		#handle_graphic_facing(abs(dir.dot(Vector2(0, 1))) > 0.9)
		character_skeleton.update_facing(dir)
			
	character_skeleton.get_animation_tree().set("parameters/walking/blend_amount", input_dir.length())


func process_movement(delta : float) -> void:
	var state : int = entity.getc_state()
	
	if state & EntityEnums.ENTITY_STATE_TYPE_FLAG_ROOT != 0 or state & EntityEnums.ENTITY_STATE_TYPE_FLAG_STUN != 0:
		moving = false
		return
		
	if (input_dir.length_squared() > 0.1):
		moving = true
#		entity.moved()
	else:
		moving = false
		
	var hvel = vel

	var target = dir
	target *= entity.get_speed().ccurrent

	var accel
	if dir.dot(hvel) > 0:
		accel = ACCEL
	else:
		accel = DEACCEL

	hvel = hvel.linear_interpolate(target, accel*delta)
	vel = hvel
	vel = move_and_slide(vel)

	if multiplayer.has_network_peer():
		if not multiplayer.is_network_server():
			rpc_id(1, "sset_position", position)
		else:
			sset_position(position)


func process_movement_player(delta : float) -> void:
	var state : int = entity.getc_state()
	
	if state & EntityEnums.ENTITY_STATE_TYPE_FLAG_ROOT != 0 or state & EntityEnums.ENTITY_STATE_TYPE_FLAG_STUN != 0:
		moving = false
		return
		
	if (input_dir.length_squared() > 0.1):
		moving = true
#		moved()
	else:
		moving = false

	var hvel = vel

	var target = input_dir.normalized()
	
#	target *= 100
	target *= entity.getc_speed().current_value  / 100.0 * BASE_SPEED
	var accel
	if dir.dot(hvel) > 0:
		accel = ACCEL
	else:
		accel = DEACCEL

	hvel = hvel.linear_interpolate(target, accel*delta)
	vel = hvel
	vel = move_and_slide(vel)

	if multiplayer.has_network_peer():
		if not multiplayer.is_network_server():
			rpc_id(1, "sset_position", position)
		else:
			sset_position(position)
	

func process_movement_mob(delta : float) -> void:
	var state : int = entity.getc_state()
	
	if state & EntityEnums.ENTITY_STATE_TYPE_FLAG_ROOT != 0 or state & EntityEnums.ENTITY_STATE_TYPE_FLAG_STUN != 0:
		moving = false
		return
		
	if (target_movement_direction.length_squared() > 0.1):
		moving = true
#		moved()
	else:
		moving = false
		
	if not moving and sleep:
		return

	if moving and sleep:
		sleep = false

	var hvel = vel

	var target = dir.normalized()
	target *= entity.getc_speed().current_value  / 100.0 * BASE_SPEED

	var accel
	if dir.dot(hvel) > 0:
		accel = ACCEL
	else:
		accel = DEACCEL

	hvel = hvel.linear_interpolate(target, accel*delta)
	vel = hvel
	vel = move_and_slide(vel)

	sset_position(position)
			
	if vel.length_squared() < 0.12:
		sleep = true


func _input(event: InputEvent) -> void:
	if not cursor_grabbed:
		set_process_input(false)
		return
	
	if event is InputEventMouseMotion and event.device != -1:
		var s : float = ProjectSettings.get("display/mouse_cursor/sensitivity")
		
		var relx : float = event.relative.x * s
		var rely : float = event.relative.y * s
		
		mouse_down_delta.x += relx
		mouse_down_delta.y += rely
			
		total_down_mouse_delta.x += relx
		total_down_mouse_delta.y += rely
		
		get_tree().set_input_as_handled()
		
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ievkey : InputEventKey = event as InputEventKey
		
		if ievkey.scancode == KEY_W:
			key_up = ievkey.pressed
		if ievkey.scancode == KEY_S:
			key_down = ievkey.pressed
		if ievkey.scancode == KEY_A:
			key_left = ievkey.pressed
		if ievkey.scancode == KEY_D:
			key_right = ievkey.pressed
			
	if event is InputEventMouseMotion and not (mouse_right_down or mouse_left_down) and event.device != -1:
		cmouseover(event)

	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.device != -1:
			mouse_left_down = event.pressed
			
			if mouse_left_down:
				mouse_dir = (event.position - get_viewport_rect().size / 2).normalized()
			else:
				mouse_dir = Vector2()

#		if event.is_pressed() and event.device != -1:
#			if event.button_index == BUTTON_WHEEL_UP:
#				camera_pivot.camera_distance_set_delta(-0.2)
#			if event.button_index == BUTTON_WHEEL_DOWN:
#				camera_pivot.camera_distance_set_delta(0.2)
		
#		if not event.pressed and event.button_index == BUTTON_LEFT and event.device != -1:
#			if mouse_down_delta.length() < MOUSE_TARGET_MAX_OFFSET:
#				target(event.position)
		
		if event.pressed and event.button_index == BUTTON_RIGHT and event.device != -1:
			target(event.position)
				
			
	if event is InputEventScreenTouch and event.pressed:
		target(event.position)
			
	if event is InputEventMouseMotion and mouse_left_down and event.device != -1:
		mouse_dir = (event.position - get_viewport_rect().size / 2).normalized()
			
	#update_cursor_mode()

			
func update_cursor_mode():
	if mouse_left_down or mouse_right_down:
		if not cursor_grabbed:
			set_process_input(true)
			total_down_mouse_delta = Vector2()
			
			cursor_grabbed = true
			last_cursor_pos = get_viewport().get_mouse_position()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		if cursor_grabbed:
			set_process_input(false)
			cursor_grabbed = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_viewport().warp_mouse(last_cursor_pos)
			
			if total_down_mouse_delta.length_squared() < 8:
				target(last_cursor_pos)
			
			
func target(position : Vector2):
	var space_state = get_world_2d().direct_space_state
	var results = space_state.intersect_point(world.make_canvas_position_local(position), 32, [], get_collision_layer())
	#var results = space_state.intersect_point(position, 32, [], 2)

	if results:
		for result in results:
			if result.collider and result.collider.owner is Entity:
				entity.target_crequest_change((result.collider.owner as Node).get_path())
				return
				
		entity.target_crequest_change(NodePath())
	else:
		entity.target_crequest_change(NodePath())

func cmouseover(event):
	var space_state = get_world_2d().direct_space_state
	var results = space_state.intersect_point(world.make_canvas_position_local(position), 32, [], get_collision_layer())
	#var results = space_state.intersect_point(position, 32, [], 2)

	if results:
		for result in results:
			if result.collider and result.collider.owner is Entity:
				var mo : Entity = result.collider.owner as Entity
			
				if last_mouse_over != null and last_mouse_over != mo:
					if is_instance_valid(last_mouse_over):
						last_mouse_over.onc_mouse_exit()
					
					last_mouse_over = null
			
				if last_mouse_over == null:
					mo.onc_mouse_enter()
					last_mouse_over = mo
			
				return
			
	if last_mouse_over != null:
		last_mouse_over.onc_mouse_exit()
		last_mouse_over = null
	
	
func analog_force_change(vector, touchpad):
	if touchpad.padname == "TouchPad":
		touchpad_dir = vector
		touchpad_dir.y *= -1
	elif touchpad.padname == "TargetPad":
		#try to target
		return
		
#
#func on_notification_ccast(what : int, info : SpellCastInfo) -> void:
#	if what == SpellEnums.NOTIFICATION_CAST_STARTED:
#		if anim_node_state_machine != null and not casting_anim:
#			anim_node_state_machine.travel("casting-loop")
#			casting_anim = true
#			animation_run = false
#	elif what == SpellEnums.NOTIFICATION_CAST_FAILED:
#		if anim_node_state_machine != null and casting_anim:
#			anim_node_state_machine.travel("idle-loop")
#			casting_anim = false
#
#			if animation_run:
#				anim_node_state_machine.travel("run-loop")
#	elif what == SpellEnums.NOTIFICATION_CAST_FINISHED:
#		if anim_node_state_machine != null:
#			anim_node_state_machine.travel("cast-end")
#			casting_anim = false
#
#			if animation_run:
#				anim_node_state_machine.travel("run-loop")
#	elif what == SpellEnums.NOTIFICATION_CAST_SUCCESS:
#		if anim_node_state_machine != null:
#			anim_node_state_machine.travel("cast-end")
#			casting_anim = false
#
#			if animation_run:
#				anim_node_state_machine.travel("run-loop")
	
	
func on_c_controlled_changed(val):
	#create camera and pivot if true
	_controlled = val
	
	if val:
		camera = Camera2D.new()
		add_child(camera)
		camera.current = true

		var uiscn : PackedScene = ResourceLoader.load("res://ui/player_ui/player_ui.tscn")
		var ui = uiscn.instance()
		add_child(ui)
		
		set_process_input(true)
		set_process_unhandled_input(true)
	else:
		if camera:
			camera.queue_free()
			camera = null
			
		set_process_input(false)
		set_process_unhandled_input(false)
		var nameplatescn : PackedScene = ResourceLoader.load("res://ui/nameplates/NamePlate.tscn")
		var nameplate = nameplatescn.instance()
		get_parent().add_child(nameplate)
		
		
 
remote func sset_position(pposition : Vector2) -> void:
	if multiplayer.network_peer and multiplayer.is_network_server():
		entity.vrpc("cset_position", position)
		
		if _controlled:
			cset_position(position)
		
remote func cset_position(pposition : Vector2) -> void:
	pposition = pposition
		
		
