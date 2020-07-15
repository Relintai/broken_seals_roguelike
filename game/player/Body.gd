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

extends Node2D

export(String) var world_path : String = "../.."
export(NodePath) var character_skeleton_path : NodePath = "Character"

const BASE_SPEED = 60.0

const MOUSE_TARGET_MAX_OFFSET : int = 10

var input_direction : Vector2

var target_position : Vector2
var path : PoolVector2Array
var current_movement_target : Vector2

var camera : Camera2D

var last_mouse_over : Entity = null

var world : Navigation2D = null

var _controlled : bool = false

var sleep : bool = false
var sleep_recheck_timer : float = 0
var dead : bool = false
var death_timer : float = 0

var entity : Entity
var character_skeleton : CharacterSkeleton2D 

var visibility_update_timer : float = randi()

var tile_size : int = 32

func _enter_tree() -> void:
	world = get_node(world_path) as Node
	tile_size = get_node("/root/Main").get_tile_size()
	
	camera = get_node_or_null("Camera") as Camera2D

	set_process_input(false)
	set_process_unhandled_input(false)
	
	character_skeleton = get_node(character_skeleton_path)
	entity = get_node("..")
	entity.set_character_skeleton(character_skeleton)
#	entity.connect("notification_ccast", self, "on_notification_ccast")
	entity.connect("diesd", self, "on_diesd")
	entity.connect("isc_controlled_changed", self, "on_c_controlled_changed")
	owner = entity

	on_c_controlled_changed(entity.c_is_controlled)
	
	transform = entity.get_transform_2d(true)

#	set_physics_process(true)


func _process(delta : float) -> void:
	if entity.ai_state == EntityEnums.AI_STATE_OFF:
		return
		
	visibility_update_timer += delta
	
	if visibility_update_timer < 1:
		return
		
	visibility_update_timer = 0

	var vpos : Vector2 = -get_tree().root.canvas_transform.get_origin() + (get_tree().root.get_visible_rect().size / 2) - position
	var l : float = vpos.length_squared()
	var rs : float = get_tree().root.size.x * get_tree().root.size.x
	rs *= 0.3

	if l < rs:
		if not visible:
			show()
#			set_physics_process(true)
	else:
		if visible:
			hide()
#			set_physics_process(false)


#func _physics_process(delta : float) -> void:
#	if entity.sentity_data == null:
#		return
#
#	if dead:
#		return
#
#	if entity.c_is_controlled:
#		process_movement(delta)
#	else:
#		if sleep:
#			sleep_recheck_timer += delta
#
#			if sleep_recheck_timer < 0.5:
#				return
#
#			sleep_recheck_timer = 0
#
##		if world != null:
##			if not world.is_position_walkable(transform.origin):
##				return
#
#		process_movement(delta)


func process_movement(delta : float) -> void:
	var state : int = entity.getc_state()
	
	if state & EntityEnums.ENTITY_STATE_TYPE_FLAG_ROOT != 0 or state & EntityEnums.ENTITY_STATE_TYPE_FLAG_STUN != 0:
		return
#
#	if (input_dir.length_squared() > 0.1):
#		moving = true
##		entity.moved()
#	else:
#		moving = false
#
#	var hvel = vel
#
#	var target = dir
#	target *= entity.get_speed().ccurrent
#
#	var accel
#	if dir.dot(hvel) > 0:
#		accel = ACCEL
#	else:
#		accel = DEACCEL
#
#	hvel = hvel.linear_interpolate(target, accel*delta)
#	vel = hvel
#	vel = move_and_slide(vel)

#	if input_length > 0.1:
#		#handle_graphic_facing(abs(dir.dot(Vector2(0, 1))) > 0.9)
#		character_skeleton.update_facing(input_dir)
#
#	character_skeleton.get_animation_tree().set("parameters/walking/blend_amount", input_dir.length())
#
#	if multiplayer.has_network_peer():
#		if not multiplayer.is_network_server():
#			rpc_id(1, "sset_position", position)
#		else:
#			sset_position(position)
	
func _unhandled_input(event: InputEvent) -> void:
	#Not sure why yet, but _unhandled_input gets called even after set_process_unhandled_input(false)
	if !entity.c_is_controlled:
		return 
		
	if event.is_action_pressed("left"):
		try_move(-1, 0)
		return
	elif event.is_action_pressed("right"):
		try_move(1, 0)
		return
	elif event.is_action_pressed("up"):
		try_move(0, -1)
		return
	elif event.is_action_pressed("down"):
		try_move(0, 1)
		return
			
	if event is InputEventMouseMotion and event.device != -1:
		cmouseover(event)

	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_DOWN and event.device != -1:
			if camera == null:
				return
			
			if camera.zoom.x >= 1:
				return
			else:
				camera.zoom += Vector2(event.factor, event.factor) * 0.01
		elif event.button_index == BUTTON_WHEEL_UP and event.device != -1:
			if camera == null:
				return
				
			if camera.zoom.x <= 0.2:
				return
			else:
				camera.zoom -= Vector2(event.factor, event.factor) * 0.01
		elif event.button_index == BUTTON_LEFT and event.device != -1:
			if event.pressed:
				target(event.position)

#		if not event.pressed and event.button_index == BUTTON_LEFT and event.device != -1:
#			if mouse_down_delta.length() < MOUSE_TARGET_MAX_OFFSET:
#				target(event.position)
		
		if event.pressed and event.button_index == BUTTON_RIGHT and event.device != -1:
			target(event.position)
				
			
	if event is InputEventScreenTouch and event.pressed:
		target(event.position)
			
			

func try_move(dx, dy):
	var tp : Vector2 = get_tile_position()
	tp.x += dx
	tp.y += dy
	
	if !world.is_position_walkable(tp.x, tp.y):
		return
	
	#todo
	#world.can_interact
	
	set_tile_position(tp)
	
func get_tile_position() -> Vector2:
	var v : Vector2 = Vector2(int(transform.origin.x / tile_size), int(transform.origin.y / tile_size))
	
	return v
	
func set_tile_position(pos : Vector2) -> void:
	transform.origin = pos * tile_size + Vector2(tile_size / 2, tile_size / 2)

func target(position : Vector2) -> bool:
#	var space_state = get_world_2d().direct_space_state
#	var results = space_state.intersect_point(world.make_canvas_position_local(position), 32, [], get_collision_layer())
#	#var results = space_state.intersect_point(position, 32, [], 2)
#
#	if results:
#		for result in results:
#			if result.collider and result.collider.owner is Entity:
#				entity.target_crequest_change((result.collider.owner as Node).get_path())
#				return true
#
#		entity.target_crequest_change(NodePath())
#	else:
#		entity.target_crequest_change(NodePath())
#
	return false

func cmouseover(event):
#	var space_state = get_world_2d().direct_space_state
#	var results = space_state.intersect_point(world.make_canvas_position_local(position), 32, [], get_collision_layer())
#	#var results = space_state.intersect_point(position, 32, [], 2)
#
#	if results:
#		for result in results:
#			if result.collider and result.collider.owner is Entity:
#				var mo : Entity = result.collider.owner as Entity
#
#				if last_mouse_over != null and last_mouse_over != mo:
#					if is_instance_valid(last_mouse_over):
#						last_mouse_over.notification_cmouse_exit()
#
#					last_mouse_over = null
#
#				if last_mouse_over == null:
#					mo.notification_cmouse_enter()
#					last_mouse_over = mo
#
#				return
#
#	if last_mouse_over != null:
#		last_mouse_over.notification_cmouse_exit()
#		last_mouse_over = null
	pass
	
	
func on_c_controlled_changed(val):
	#create camera and pivot if true
	_controlled = val
	
	if val:
		camera = Camera2D.new()
#		camera.zoom = Vector2(0.6, 0.6)
		camera.zoom = get_node("/root/Main").get_world_scale()
		add_child(camera)
		camera.current = true

		var uiscn : PackedScene = ResourceLoader.load("res://ui/player_ui/player_ui.tscn")
		var ui = uiscn.instance()
		add_child(ui)
		
#		set_process_input(true)
		set_process_unhandled_input(true)
	else:
		if camera:
			camera.queue_free()
			camera = null
		
#		set_process_input(false)
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
		
