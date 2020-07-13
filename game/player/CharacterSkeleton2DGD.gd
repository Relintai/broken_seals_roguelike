extends CharacterSkeleton2D
class_name CharacterSkeleton2DGD

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

export (NodePath) var front_node_path : NodePath = ""
export (NodePath) var front_animation_player_path : NodePath = ""
export (NodePath) var front_animation_tree_path : NodePath = ""

export (NodePath) var side_node_path : NodePath = ""
export (NodePath) var side_animation_player_path : NodePath = ""
export (NodePath) var side_animation_tree_path : NodePath = ""

export(CharacterAtlas) var character_atlas : CharacterAtlas setget set_character_atlas

var _atlas : CharacterAtlas2D

enum CharacterFacing {
	FACING_FRONT = 0,
	FACING_BACK = 1,
	FACING_RIGHT = 2,
	FACING_LEFT = 3,
}

var _facing : int = 0

var _front_node : CharacterBones = null
var _front_animation_player : AnimationPlayer = null
var _front_animation_tree : AnimationTree = null

var _side_node : CharacterBones = null
var _side_animation_player : AnimationPlayer = null
var _side_animation_tree : AnimationTree = null

var _active_node : CharacterBones = null
var _active_animation_player : AnimationPlayer = null
var _active_animation_tree : AnimationTree = null

var _is_front_side : bool = false

var effects : Array

func _ready() -> void:
	_front_node = get_node(front_node_path) as CharacterBones
	_front_animation_player = get_node(front_animation_player_path) as AnimationPlayer
	_front_animation_tree = get_node(front_animation_tree_path) as AnimationTree

	_side_node = get_node(side_node_path) as CharacterBones
	_side_animation_player = get_node(side_animation_player_path) as AnimationPlayer
	_side_animation_tree = get_node(side_animation_tree_path) as AnimationTree

	set_character_atlas(character_atlas)
	
	_front_node.hide()
	_side_node.show()
	_active_node = _side_node
	_active_animation_player = _side_animation_player
	_active_animation_tree = _side_animation_tree
	_is_front_side = false

#func _enter_tree():
#	var body = get_node("/root/Main").get_body().instance()
#	add_child(body)


func update_facing(input_direction : Vector2) -> void:
	var front : bool = abs(input_direction.dot(Vector2(0, 1))) > 0.9
	
	if front:
		if not _is_front_side:
			_is_front_side = true
			
			_side_node.hide()
			_front_node.show()

			_active_node = _front_node
			_active_animation_tree = _front_animation_tree
			
			if input_direction.y > 0:
				set_facing(CharacterFacing.FACING_FRONT)
			else:
				set_facing(CharacterFacing.FACING_BACK)

	else:
		if _is_front_side:
			_is_front_side = false
			
			_side_node.show()
			_front_node.hide()

			_active_node = _side_node
			_active_animation_tree = _side_animation_tree
			
		if input_direction.x > 0.01 and _facing != CharacterFacing.FACING_RIGHT:
			set_facing(CharacterFacing.FACING_RIGHT)
			_active_node.transform.x.x = -1
		elif input_direction.x < -0.01 and _facing != CharacterFacing.FACING_LEFT:
			set_facing(CharacterFacing.FACING_LEFT)
			_active_node.transform.x.x = 1

func add_effect(bone_id : int, effect : PackedScene) -> void:
	pass

func remove_effect(bone_id : int, effect : PackedScene) -> void:
	pass

func get_animation_player() -> AnimationPlayer:
	return _active_animation_player
	
func get_animation_tree() -> AnimationTree:
	return _active_animation_tree

func set_character_atlas(atlas : CharacterAtlas) -> void:
	character_atlas = atlas
	
	_atlas = atlas as CharacterAtlas2D
	
	if _front_node != null:
		_front_node.set_atlas(_atlas)
	
	if _front_node != null:
		_side_node.set_atlas(_atlas)
	
func set_facing(facing : int) -> void:
	_facing = facing
	
	_active_node.set_facing(facing)
	
