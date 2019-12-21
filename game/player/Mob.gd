extends Entity

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

#export (String) var map_path : String
export(float) var max_visible_distance : float = 120 setget set_max_visible_distance
var max_visible_distance_squared : float = max_visible_distance * max_visible_distance

const ray_length = 1000
const ACCEL : float = 100.0
const DEACCEL : float = 100.0

var _on : bool = true

var y_rot : float = 0.0

var vel : Vector2 = Vector2()
var dir : Vector2 = Vector2()
var target_movement_direction : Vector2 = Vector2()

var animation_run : bool = false

var moving : bool = false
var sleep : bool = false

var dead : bool = false
var death_timer : float = 0

var path : = PoolVector2Array()
var follow_path = false

var frame : int = 0

func _ready() -> void:
	ai_state = EntityEnums.AI_STATE_PATROL
	
	frame = randi() % 10

	set_process(true)
	set_physics_process(true)
	
	
func _process(delta : float) -> void:
	if dead:
		death_timer += delta
		
		if death_timer > 60:
			queue_free()
		
		return
		
	frame += 1
	
	if frame < 10:
		return
		
	frame = 0
	
#	print(get_tree().root.get_visible_rect())
	var vpos : Vector2 = -get_tree().root.canvas_transform.get_origin() - position
	var l : float = vpos.length_squared()
	var rs : float = get_tree().root.size.x * get_tree().root.size.x

	if l < rs:
		if not visible:
			show()
			set_physics_process(true)
	else:
		if visible:
			hide()
			set_physics_process(false)
	

func _physics_process(delta : float) -> void:
	if not _on:
		return
	
	if sentity_data == null:
		return
		
	if dead:
		return

	process_movement(delta)

func move_along_path(distance : float)  -> void:
	var start_point : = position
	
	for i in range(path.size()):
		var distance_to_next : = start_point.distance_to(path[0])
		
		if distance <= distance_to_next and distance >= 0.0:
			position = start_point.linear_interpolate(path[0], distance / distance_to_next)
			break
		elif distance <= 0.0:
			position = path[0]
			follow_path = false
			break
			
		#if line2d and use_line_path:
		#	line2d.points = path
			
		distance -= distance_to_next
		start_point = path[0]
		path.remove(0)
		
		if path.size() == 0:
			follow_path = false
		
	
func set_path(value : PoolVector2Array) -> void:
	path = value
	
	#if line2d and use_line_path:
	#	line2d.points = value
		
		
	if value.size() == 0:
		return
		
	follow_path = true


func process_movement(delta : float) -> void:
#	if starget != null:
#		look_at(starget.translation, Vector3(0, 1, 0))
#
	var state : int = getc_state()
	
	if state & EntityEnums.ENTITY_STATE_TYPE_FLAG_ROOT != 0 or state & EntityEnums.ENTITY_STATE_TYPE_FLAG_STUN != 0:
		moving = false
		return
		
	if target_movement_direction.length_squared() > 0.1:
		target_movement_direction = target_movement_direction.normalized()
		
		get_character_skeleton().update_facing(dir)
		
		moving = true
	else:
		moving = false
		
	get_character_skeleton().get_animation_tree().set("parameters/walking/blend_amount", target_movement_direction.length())

	var hvel : Vector2 = vel
	hvel.y = 0

	var target : Vector2 = dir
	target *= get_speed().ccurrent

	var accel
	if dir.dot(hvel) > 0:
		accel = ACCEL
	else:
		accel = DEACCEL

	hvel = hvel.linear_interpolate(target, accel*delta)
	
	if hvel.length_squared() < 0.1:
		return
	
	vel = hvel
	vel = move_and_slide(vel)
	
	sset_position(position, rotation)


func sstart_attack(entity : Entity) -> void:
	ai_state = EntityEnums.AI_STATE_ATTACK
	
	starget = entity
	
func _onc_mouse_enter() -> void:
	if centity_interaction_type == EntityEnums.ENITIY_INTERACTION_TYPE_LOOT:
		Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_MOVE)
		
func _onc_mouse_exit() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
func _son_death():
	if dead:
		return
	
	if starget == null:
		queue_free()
		return
		
	#warning-ignore:unused_variable
	for i in range(sget_aura_count()):
		sremove_aura(sget_aura(0))
	
	dead = true
	
	var ldiff : float = slevel - starget.slevel + 10.0
	
	if ldiff < 0:
		ldiff = 0
		
	if ldiff > 15:
		ldiff = 15
		
	ldiff /= 10.0
	
	starget.adds_xp(int(5.0 * slevel * ldiff))
		
	starget = null
	
	sentity_interaction_type = EntityEnums.ENITIY_INTERACTION_TYPE_LOOT
	ai_state = EntityEnums.AI_STATE_OFF
	
#	set_process(false)
	set_physics_process(false)
	
remote func rset_position(position : Vector2, rotation : float) -> void:
	if get_tree().is_network_server():
		rpc("rset_position", position, rotation)

func _son_damage_dealt(data):
	if ai_state != EntityEnums.AI_STATE_ATTACK and data.dealer != self:
		sstart_attack(data.dealer)

func _con_damage_dealt(info : SpellDamageInfo) -> void:
#	if info.dealer == 
	WorldNumbers.damage(position, 90, info.damage, info.crit)

func _con_heal_dealt(info : SpellHealInfo) -> void:
	WorldNumbers.heal(position, 90, info.heal, info.crit)

func _moved() -> void:
	if sis_casting():
		sfail_cast()
		
func set_max_visible_distance(var value : float) -> void:
	max_visible_distance_squared = value * value
	
	max_visible_distance = value

func _setup():
	sentity_name = sentity_data.text_name
	
func _son_xp_gained(value : int) -> void:
	if not Entities.get_xp_data().can_level_up(gets_level()):
		return
	
	var xpr : int = Entities.get_xp_data().get_xp(gets_level());
	
	if xpr <= sxp:
		slevelup(1)
		sxp = 0

func _son_level_up(value: int) -> void:
	if sentity_data == null:
		return
		
	var ecd : EntityClassData = sentity_data.entity_class_data
	
	if ecd == null:
		return
	
	sfree_spell_points += ecd.spell_points_per_level * value
	sfree_talent_points += value

	for i in range(Stat.MAIN_STAT_ID_COUNT):
		var st : int = sentity_data.entity_class_data.get_stat_data().get_level_stat_data().get_stat_diff(i, slevel - value, slevel)

		var statid : int = i + Stat.MAIN_STAT_ID_START
		
		var stat : Stat = get_stat_int(statid)
		
		var sm : StatModifier = stat.get_modifier(0)
		sm.base_mod += st
		
	
	var arr : Array = Array()
	
	for i in range(ecd.get_num_spells()):
		arr.append(ecd.get_spell(i))
		
	randomize()
	arr.shuffle()
	
	for v in range(value):
		for i in range(arr.size()):
			var spell : Spell = arr[i]
			
			if not hass_spell(spell):
				var spnum :int = gets_spell_count()
				
				crequest_spell_learn(spell.id)
				
				if spnum != gets_spell_count():
					break
				
			if sfree_spell_points == 0:
				break
			
			
		if sfree_spell_points == 0:
			break
	

func sset_position(pposition : Vector2, protation : float) -> void:
	if multiplayer.network_peer and multiplayer.is_network_server():
#		cset_position(position, rotation)
		vrpc("cset_position", pposition, protation)
		
remote func cset_position(pposition : Vector2, protation : float) -> void:
	position = pposition
	rotation = protation

