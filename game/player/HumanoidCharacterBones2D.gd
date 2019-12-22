extends CharacterBones
class_name HumanoidCharacterBones2D

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

enum HumanoidBones {
	HUMANOID_BONE_HIP = 0,
	HUMANOID_BONE_TORSO = 1,
	HUMANOID_BONE_LEG_R = 2,
	HUMANOID_BONE_FOOT_R = 3,
	HUMANOID_BONE_TOE_R = 4,
	HUMANOID_BONE_LEG_L = 5,
	HUMANOID_BONE_FOOT_L = 6,
	HUMANOID_BONE_TOE_L = 7,
	HUMANOID_BONE_ARM_R = 8,
	#HUMANOID_BONE_SHOULDER_GUARD_R = 0,
	HUMANOID_BONE_HAND_R = 9,
	HUMANOID_BONE_FINGERS_R = 10,
	HUMANOID_BONE_ARM_L = 11,
	#HUMANOID_BONE_SHOULDER_GUARD_L = 0,
	HUMANOID_BONE_HAND_L = 12,
	HUMANOID_BONE_FINGERS_L = 13,
	HUMANOID_BONE_HEAD = 14,
	HUMANOID_BONE_HEAD_TOP = 15,
	
	HUMANOID_BONES_MAX = 16,
}

export (String, MULTILINE) var help : String
export (Array, NodePath) var bones : Array

var _atlas : CharacterAtlas2D

func set_facing(facing : int) -> void:
	if _atlas == null:
		return
	
	for i in range(len(_atlas.slots)):
		var entry : CharacterAtlasEntry2D = _atlas.slots[i] as CharacterAtlasEntry2D
		
		if entry == null:
			continue
			
		var r : Rect2 = entry.get_index(facing) as Rect2
		
		var bone : Sprite = get_node(bones[i]) as Sprite
		
		if bone == null:
			continue
			
		bone.region_rect = r


func set_atlas(atlas : CharacterAtlas2D) -> void:
	_atlas = atlas
