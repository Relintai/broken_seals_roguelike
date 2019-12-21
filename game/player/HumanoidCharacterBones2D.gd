extends CharacterBones
class_name HumanoidCharacterBones2D

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
