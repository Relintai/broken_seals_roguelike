tool
extends Resource
class_name MainDungeonGenerator

enum GenType {
	TEST = 0, NORMAL = 1, NOISE3D = 2, ANL = 3
}



export(int) var gen_type : int = GenType.NORMAL
export(int) var _level_seed : int
export(bool) var _spawn_mobs : bool

var _world : Navigation2D

func setup(world : Navigation2D, level_seed : int, spawn_mobs : bool) -> void:
	_level_seed = level_seed
	_world = world
	_spawn_mobs = spawn_mobs
	
func _generate_chunk(chunk : Resource) -> void:
	pass
