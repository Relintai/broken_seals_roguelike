extends "PlayerGDBase.gd"
class_name PlayerGD

# Copyright Péter Magyar relintai@gmail.com
# MIT License, functionality from this class needs to be protable to the entity spell system

# Copyright (c) 2019 Péter Magyar

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

export(String) var world_path : String = ".."
export(NodePath) var model_path : NodePath = "Rotation_Helper/Model"

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

var camera : Camera2D

var animation_run : bool = false

var moving : bool = false
var casting_anim : bool = false

var last_mouse_over : Entity = null

var world : Node2D = null


func _ready() -> void:
	camera = $Camera as Camera2D
	
	world = get_node(world_path) as Node2D

func _physics_process(delta : float) -> void:
	if world.initial_generation:
		return
	
	process_input(delta)
	process_movement(delta)

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
	
	var state : int = getc_state()
	
	if state & EntityEnums.ENTITY_STATE_TYPE_FLAG_ROOT != 0 or state & EntityEnums.ENTITY_STATE_TYPE_FLAG_STUN != 0:
		input_dir = Vector2()
		return
	
	var input_length : float = input_dir.length_squared()
	
	dir = input_dir.normalized()
	
	if input_length > 0.1:
		#handle_graphic_facing(abs(dir.dot(Vector2(0, 1))) > 0.9)
		get_character_skeleton().update_facing(dir)
			
	get_character_skeleton().get_animation_tree().set("parameters/walking/blend_amount", input_dir.length())


func process_movement(delta : float) -> void:
	var state : int = getc_state()
	
	if state & EntityEnums.ENTITY_STATE_TYPE_FLAG_ROOT != 0 or state & EntityEnums.ENTITY_STATE_TYPE_FLAG_STUN != 0:
		moving = false
		return
		
	if (input_dir.length_squared() > 0.1):
		moving = true
		moved()
	else:
		moving = false
		

	var hvel = vel

	var target = dir
	target *= get_speed().ccurrent

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

	
func target(position : Vector2):
	var space_state = get_world_2d().direct_space_state
	var results = space_state.intersect_point(world.make_canvas_position_local(position), 32, [], get_collision_layer())
	#var results = space_state.intersect_point(position, 32, [], 2)

	if results:
		for result in results:
			if result.collider and result.collider is Entity:
				crequest_target_change((result.collider as Node).get_path())
				return
				
		crequest_target_change(NodePath())
	else:
		crequest_target_change(NodePath())
		
		
func cmouseover(event):
	var space_state = get_world_2d().direct_space_state
	var results = space_state.intersect_point(world.make_canvas_position_local(position), 32, [], get_collision_layer())
	#var results = space_state.intersect_point(position, 32, [], 2)

	if results:
		for result in results:
			if result.collider and result.collider is Entity:
				var mo : Entity = result.collider as Entity
			
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
	
func analog_force_change(vector: Vector2, touchpad) -> void:
	if touchpad.padname == "TouchPad":
		touchpad_dir = vector
		touchpad_dir.y *= -1
	elif touchpad.padname == "TargetPad":
		#try to target
		return

remote func sset_position(pposition : Vector2) -> void:
	if get_network_master() != 1:
		print(str(get_network_master()) + "psset")
	
	if multiplayer.network_peer and multiplayer.is_network_server():
		vrpc("cset_position", pposition)
		
		cset_position(pposition)
		
remote func cset_position(pposition : Vector2) -> void:
	if get_network_master() != 1:
		print(str(get_network_master()) + " pcset")
		
	position = pposition
		
func _moved() -> void:
	if sis_casting():
		sfail_cast()
		
func _setup():
	setup_actionbars()
		
func _con_target_changed(entity: Entity, old_target: Entity) -> void:
	if is_instance_valid(old_target):
		old_target.onc_untargeted()
		
	if is_instance_valid(ctarget):
		ctarget.onc_targeted()
		
		if canc_interact():
			crequest_interact()
		
#func _con_cast_started(info):
#	if anim_node_state_machine != null and not casting_anim:
#		anim_node_state_machine.travel("casting-loop")
#		casting_anim = true
#		animation_run = false
		
#func _con_cast_failed(info):
#	if anim_node_state_machine != null and casting_anim:
#		anim_node_state_machine.travel("idle-loop")
#		casting_anim = false
#
#		if animation_run:
#			anim_node_state_machine.travel("run-loop")

#func _con_cast_finished(info):
#	if anim_node_state_machine != null:
#		anim_node_state_machine.travel("cast-end")
#		casting_anim = false
#
#		if animation_run:
#			anim_node_state_machine.travel("run-loop")
			
#func _con_spell_cast_success(info):
#	if anim_node_state_machine != null:
#		anim_node_state_machine.travel("cast-end")
#		casting_anim = false
#
#		if animation_run:
#			anim_node_state_machine.travel("run-loop")

func _son_xp_gained(value : int) -> void:
	if not Entities.get_xp_data().can_level_up(gets_level()):
		return
	
	var xpr : int = Entities.get_xp_data().get_xp(gets_level());
	
	if xpr <= sxp:
		slevelup(1)
		sxp = 0


func _son_level_up(level: int) -> void:
	if sentity_data == null:
		return
		
	var ecd : EntityClassData = sentity_data.entity_class_data
	
	if ecd == null:
		return
	
	sfree_spell_points += ecd.spell_points_per_level * level
	sfree_talent_points += level
	
	for i in range(Stat.MAIN_STAT_ID_COUNT):
		var st : int = sentity_data.entity_class_data.get_stat_data().get_level_stat_data().get_stat_diff(i, slevel - level, slevel)

		var statid : int = i + Stat.MAIN_STAT_ID_START
		
		var stat : Stat = get_stat_int(statid)
		
		var sm : StatModifier = stat.get_modifier(0)
		sm.base_mod += st
		

#func _con_xp_gained(value):
#	print(value)

func _scraft(id):
	if not hass_craft_recipe_id(id):
		return
		
	var recipe : CraftRecipe = gets_craft_recipe_id(id)
	
	if recipe == null:
		return
	
	for i in range(recipe.required_tools_count):
		var mat : CraftRecipeHelper = recipe.get_required_tool(i)
		
		if mat == null:
			continue
			
		if not sbag.has_item(mat.item, mat.count):
			return
			
	
	for i in range(recipe.required_materials_count):
		var mat : CraftRecipeHelper = recipe.get_required_material(i)
		
		if mat == null:
			continue
			
		if not sbag.has_item(mat.item, mat.count):
			return
			
	#ok, player has everything
	
	for i in range(recipe.required_materials_count):
		var mat : CraftRecipeHelper = recipe.get_required_material(i)
		
		if mat == null:
			continue
			
		sbag.remove_items(mat.item, mat.count)
		
	var item : ItemInstance = recipe.item.item.create_item_instance()
		
	sbag.add_item(item)
	
func _from_dict(dict):
	._from_dict(dict)
	
	randomize()
	sseed = randi()
	
