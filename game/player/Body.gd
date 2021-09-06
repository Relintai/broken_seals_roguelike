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

var world : Node2D = null

var _controlled : bool = false

var sleep : bool = false
var sleep_recheck_timer : float = 0
var dead : bool = false
var death_timer : float = 0

var entity : Entity
var character_skeleton : CharacterSkeleton2D 

var visibility_update_timer : float = randi()

var tile_size : int = 32

var _nameplate : Node

var init : bool = false

var touches : Array = Array()
var touch_zoom : bool = false

func _enter_tree() -> void:
	world = get_node(world_path) as Node2D
	tile_size = get_node("/root/Main").get_tile_size()
	
	if init:
		return
	
	camera = get_node_or_null("Camera") as Camera2D

	set_process_input(false)
	set_process_unhandled_input(false)
	
	character_skeleton = get_node(character_skeleton_path)
	entity = get_node("..")
	entity.set_character_skeleton(character_skeleton)
#	entity.connect("notification_ccast", self, "on_notification_ccast")
	entity.connect("diesd", self, "on_diesd")
	entity.connect("onc_entity_controller_changed", self, "on_c_controlled_changed")
	owner = entity

	on_c_controlled_changed()
	
	transform = entity.get_transform_2d(true)
	
	init = true

func set_visibility(val : bool) -> void:
	if val:
		show()

		if _nameplate:
			_nameplate.show()
	elif !val:
		hide()
		
		if _nameplate:
			_nameplate.hide()

func _unhandled_input(event: InputEvent) -> void:
	#Not sure why yet, but _unhandled_input gets called even after set_process_unhandled_input(false)
	if !entity.getc_is_controlled():
		return 
		
	if event.is_action_pressed("left"):
		try_move(-1, 0)
		get_tree().set_input_as_handled()
		return
	elif event.is_action_pressed("right"):
		try_move(1, 0)
		get_tree().set_input_as_handled()
		return
	elif event.is_action_pressed("up"):
		try_move(0, -1)
		get_tree().set_input_as_handled()
		return
	elif event.is_action_pressed("down"):
		try_move(0, 1)
		get_tree().set_input_as_handled()
		return
	elif event.is_action_pressed("wait"):
		world.player_moved() 
		get_tree().set_input_as_handled()
		return
			
	if event is InputEventMouseMotion and event.device != -1:
		cmouseover(event.position)
		get_tree().set_input_as_handled()

	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_DOWN and event.device != -1:
			if camera == null:
				return
			
			if camera.zoom.x >= 2:
				return
			else:
				camera.zoom += Vector2(event.factor, event.factor) * 0.01
		elif event.button_index == BUTTON_WHEEL_UP and event.device != -1:
			if camera == null:
				return
				
			if camera.zoom.x <= 0.1:
				return
			else:
				camera.zoom -= Vector2(event.factor, event.factor) * 0.01
		elif event.button_index == BUTTON_LEFT and event.device != -1:
			if event.pressed:
				var pos : Vector2 = world.make_canvas_position_local(event.position)
				
				pos -= transform.origin
				
				if pos.length() < tile_size / 2:
					#wait
					world.player_moved() 
					return
					
				var mx : int = 0
				var my : int = 0
					
				if abs(pos.x) > tile_size / 2:
					if pos.x >= 0:
						mx = 1
					else:
						mx = -1
							
				if abs(pos.y) > tile_size / 2:
					if pos.y >= 0:
						my = 1
					else:
						my = -1
							
				try_move(mx, my)

#		if not event.pressed and event.button_index == BUTTON_LEFT and event.device != -1:
#			if mouse_down_delta.length() < MOUSE_TARGET_MAX_OFFSET:
#				target(event.position)
		
		if event.pressed and event.button_index == BUTTON_RIGHT and event.device != -1:
			target(event.position)
					
		get_tree().set_input_as_handled()
				
			
	if event is InputEventScreenTouch:
		if event.pressed:
			var touch : Array = [
				event.index,
				event.position,
			]
			
			touches.append(touch)
			
			if touches.size() > 1:
				touch_zoom = true
		else:
			if !touch_zoom && !target(event.position, true):
				var pos : Vector2 = world.make_canvas_position_local(event.position)
				
				pos -= transform.origin
				
				if pos.length() < tile_size / 2:
					#wait
					world.player_moved() 
				else:
					var mx : int = 0
					var my : int = 0
						
					if abs(pos.x) > tile_size / 2:
						if pos.x >= 0:
							mx = 1
						else:
							mx = -1
								
					if abs(pos.y) > tile_size / 2:
						if pos.y >= 0:
							my = 1
						else:
							my = -1
								
					try_move(mx, my)
				
			for i in range(touches.size()):
				if touches[i][0] == event.index:
					touches.remove(i)
					break
					
			if touch_zoom and touches.size() == 0:
				touch_zoom = false
				

		get_tree().set_input_as_handled()
		
	if event is InputEventScreenDrag && touches.size() == 2:
		if camera == null:
			return
			
		var found : bool = false
		for t in touches:
			if event.index == t[0]:
				found = true
				break
				
		if !found:
			return
			
		var otp : Vector2
		var ttp : Vector2
		
		if touches[0][0] == event.index:
			otp = touches[1][1]
			ttp = touches[0][1]
		else:
			otp = touches[0][1]
			ttp = touches[1][1]
			
		var olen : float =  (otp - ttp).length()
		var currlen : float = (otp - event.position).length()
			
		
		if olen > currlen:
			if camera.zoom.x >= 2:
				return
			else:
				var l : float = event.relative.length()
				camera.zoom += Vector2(l, l) * 0.01 * 72 / OS.get_screen_dpi()
		else:
			if camera.zoom.x <= 0.1:
				return
			else:
				var l : float = event.relative.length()
				camera.zoom -= Vector2(l, l) * 0.01 * 72 / OS.get_screen_dpi()
		

		get_tree().set_input_as_handled()
			
			

func try_move(dx, dy):
	var state : int = entity.getc_state()
	
	if state & EntityEnums.ENTITY_STATE_TYPE_FLAG_ROOT != 0 or state & EntityEnums.ENTITY_STATE_TYPE_FLAG_STUN != 0:
		return
		
	var tp : Vector2 = get_tile_position()
	tp.x += dx
	tp.y += dy
	
	if !world.is_position_walkable(tp.x, tp.y):
		return
	
	#todo
	#world.can_interact
	
	set_tile_position(tp)
	
	if entity.getc_is_controlled():
		world.player_moved() 
	
func move_towards_target():
	var state : int = entity.getc_state()
	
	if state & EntityEnums.ENTITY_STATE_TYPE_FLAG_ROOT != 0 or state & EntityEnums.ENTITY_STATE_TYPE_FLAG_STUN != 0:
		return
		
	var t : Entity = entity.getc_target()
	
	if !t:
		return
		
	var bp : Vector2 = t.get_body().get_tile_position()
	
	var my_point = world.nav_graph.get_closest_point(get_tile_position())
	var target_point = world.nav_graph.get_closest_point(bp)
	var path = world.nav_graph.get_point_path(my_point, target_point)
	
	if path:
		assert(path.size() > 1)
		
		var move_tile = Vector2(path[1].x, path[1].y)
		
		if move_tile == bp:
			return
		
		for e in world.enemies:
			if e.get_body().get_tile_position() == move_tile:
				return
				
		set_tile_position(move_tile)
	
func get_tile_position() -> Vector2:
	return Vector2(int(transform.origin.x / tile_size), int(transform.origin.y / tile_size))
	
func set_tile_position(pos : Vector2) -> void:
	transform.origin = pos * tile_size + Vector2(tile_size / 2, tile_size / 2)

func target(position : Vector2, keep_target : bool = false) -> bool:
	position = world.make_canvas_position_local(position)

	var pos : Vector2 = world.pixel_to_tile(position.x, position.y)
	var enemy : Entity = world.get_enemy_at_tile(pos.x, pos.y)
	
	if enemy:
		if !enemy.get_body().visible:
			return false
		
		if entity.getc_target() != enemy:
			entity.target_crequest_change(enemy.get_path())
			return true
	else:
		if !keep_target:
			entity.target_crequest_change(NodePath())
		
	return false

func cmouseover(position : Vector2):
	position = world.make_canvas_position_local(position)
	
	var pos : Vector2 = world.pixel_to_tile(position.x, position.y)
	var enemy : Entity = world.get_enemy_at_tile(pos.x, pos.y)

	if enemy:
		if !enemy.get_body().visible:
			return false
			
		if last_mouse_over != null and last_mouse_over != entity:
			if is_instance_valid(last_mouse_over):
				last_mouse_over.notification_cmouse_exit()
				
			last_mouse_over = null
			
		if last_mouse_over == null:
			entity.notification_cmouse_enter()
			last_mouse_over = entity
			
		return

	if last_mouse_over != null:
		last_mouse_over.notification_cmouse_exit()
		last_mouse_over = null
	
	
func on_c_controlled_changed():
	#create camera and pivot if true
	_controlled = entity.getc_is_controlled()
	
	if _controlled:
		if _nameplate:
			_nameplate.queue_free()
			
		camera = Camera2D.new()
		camera.zoom = get_node("/root/Main").get_world_scale()
		add_child(camera)
		camera.current = true

		#var uiscn : PackedScene = ResourceLoader.load("res://ui/player_ui/player_ui.tscn")
		#var ui = uiscn.instance()
		var ui = DataManager.request_instance(DataManager.PLAYER_UI_INSTANCE)
		add_child(ui)
		
#		set_process_input(true)
		set_process_unhandled_input(true)
		
		set_visibility(true)
	else:
		if camera:
			camera.queue_free()
			camera = null
		
#		set_process_input(false)
		set_process_unhandled_input(false)
		var nameplatescn : PackedScene = ResourceLoader.load("res://ui/nameplates/NamePlate.tscn")
		_nameplate = nameplatescn.instance()
		get_parent().add_child(_nameplate)
		
		set_visibility(false)
		
 
remote func sset_position(pposition : Vector2) -> void:
	if multiplayer.network_peer and multiplayer.is_network_server():
		entity.vrpc("cset_position", position)
		
		if _controlled:
			cset_position(position)
		
remote func cset_position(pposition : Vector2) -> void:
	pposition = pposition
		
func on_diesd(entity):
	pass
