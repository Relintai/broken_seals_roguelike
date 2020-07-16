extends CharacterSkeleton2D

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

#export (NodePath) var sprite_path : NodePath = ""

var sprite : Sprite

var _facing : int = 0

var effects : Array

var _atlas : CharacterAtlas2D

enum CharacterFacing {
	FACING_FRONT = 0,
	FACING_BACK = 1,
	FACING_RIGHT = 2,
	FACING_LEFT = 3,
}

#func _ready() -> void:
#	sprite = get_node(sprite_path) as Sprite

func _enter_tree():
	sprite = get_node("/root/Main").get_body().instance()
	add_child(sprite)

func update_facing(input_direction : Vector2) -> void:

	if input_direction.x > 0.01 and _facing != CharacterFacing.FACING_RIGHT:
		_facing = CharacterFacing.FACING_RIGHT
		sprite.transform.x.x = -1
	elif input_direction.x < -0.01 and _facing != CharacterFacing.FACING_LEFT:
		_facing = CharacterFacing.FACING_LEFT
		sprite.transform.x.x = 1

#func add_effect(bone_id : int, effect : PackedScene) -> void:
#	pass
#
#func remove_effect(bone_id : int, effect : PackedScene) -> void:
#	pass
#
func _common_attach_point_index_get(point):
	if point == EntityEnums.COMMON_SKELETON_POINT_LEFT_HAND:
		return 0
	elif point == EntityEnums.COMMON_SKELETON_POINT_ROOT:
		return 3
	elif point == EntityEnums.COMMON_SKELETON_POINT_SPINE_2:
		return 6
	elif point == EntityEnums.COMMON_SKELETON_POINT_RIGHT_HAND:
		return 1
	elif point == EntityEnums.COMMON_SKELETON_POINT_BACK:
		return 6
	elif point == EntityEnums.COMMON_SKELETON_POINT_RIGHT_HIP:
		return 4
	elif point == EntityEnums.COMMON_SKELETON_POINT_WEAPON_LEFT:
		return 7
	elif point == EntityEnums.COMMON_SKELETON_POINT_WEAPON_LEFT_BACK:
		return 9
	elif point == EntityEnums.COMMON_SKELETON_POINT_WEAPON_RIGHT:
		return 8
	elif point == EntityEnums.COMMON_SKELETON_POINT_WEAPON_RIGHT_BACK:
		return 10
	elif point == EntityEnums.COMMON_SKELETON_POINT_WEAPON_LEFT_SHIELD:
		return 11
		
	return 3

func get_animation_player() -> AnimationPlayer:
	return null
	
func get_animation_tree() -> AnimationTree:
	return null

func set_character_atlas(atlas : CharacterAtlas) -> void:
	_atlas = atlas as CharacterAtlas2D

