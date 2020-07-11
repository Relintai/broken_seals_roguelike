extends "PlayerGDBase.gd"
class_name NetworkedPlayerGD

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

#export (float) var MOUSE_SENSITIVITY : float = 0.05
#export (String) var map_path : String

#const ray_length = 1000
#const ACCEL : float = 100.0
#const DEACCEL : float = 100.0
#const GRAVITY : float = -24.8
#const JUMP_SPEED : float = 3.8
#const MAX_SLOPE_ANGLE : float = 40.0
#const MOUSE_TARGET_MAX_OFFSET : int = 10
#
##var _on : bool = true
#
#var y_rot : float = 0.0
#
##var vel : Vector3 = Vector3()
##var dir : Vector3 = Vector3()
#
#var animation_tree : AnimationTree
#var anim_node_state_machine : AnimationNodeStateMachinePlayback = null
##var animation_run : bool = false
#
#func _ready() -> void:
#	animation_tree = get_character_skeleton().get_animation_tree()
#
#	if animation_tree != null:
#		anim_node_state_machine = animation_tree["parameters/playback"]
	

#func _physics_process(delta : float) -> void:
#	if not _on:
#		return
#
	#process_movement(delta)

#func process_movement(delta : float) -> void:
#	if input_dir.x > 0.1 or input_dir.y > 0.1 or input_dir.x < -0.1 or input_dir.y < -0.1:
#		var forward : Vector3 = Vector3(0, 0, 1).rotated(Vector3(0, 1, 0), deg2rad(y_rot)) 
#		var right : Vector3 = forward.cross(Vector3(0, 1, 0)) * -input_dir.x
#		forward *= input_dir.y #only potentially make it zero after getting the right vector
#
#		dir = forward
#		dir += right
#
#		if dir.length_squared() > 0.1:
#			dir = dir.normalized()
#	else:
#		dir = Vector3()
#
#	vel.y += delta * GRAVITY
#
#	var hvel : Vector3 = vel
#	hvel.y = 0
#
#	var target : Vector3 = dir
#	target *= get_speed().ccurrent
#
#	var accel
#	if dir.dot(hvel) > 0:
#		accel = ACCEL
#	else:
#		accel = DEACCEL
#
#	hvel = hvel.linear_interpolate(target, accel * delta) as Vector3
#	vel.x = hvel.x
#	vel.z = hvel.z
#	vel = move_and_slide(vel, Vector3(0,1,0), false, 4, deg2rad(MAX_SLOPE_ANGLE))


#remote func set_position(position : Vector3, rot : Vector3) -> void:
#	translation = position
#	rotation = rot
#
#remote func sset_position(pposition : Vector2, protation : float) -> void:
#
##	if get_network_master() != 1:
##		print(str(get_network_master()) + "npsset")
#
#	if multiplayer.network_peer and multiplayer.is_network_server():
#		cset_position(pposition, protation)
#		vrpc("cset_position", pposition, protation)
#
#remote func cset_position(pposition : Vector2, protation : float) -> void:
##	if get_network_master() != 1:
##		print(str(get_network_master()) + "npcset")
#
#	get_body().position = pposition
#	get_body().rotation = protation
#
#func _moved() -> void:
#
#	if sis_casting():
#		sfail_cast()
#
