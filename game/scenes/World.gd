extends Node2D

var _player_file_name : String
var _player : Entity

export(Array, NodePath) var level_paths : Array
var levels : Array
var current_level : int = -1

func _ready():
	for lp in level_paths:
		var l = get_node(lp)
		
		if l.visible:
			l.hide()
			
		levels.append(l)
		
func _unhandled_key_input(event):
	if event.scancode == KEY_M and event.pressed:
		var l : int = current_level + 1

		if l >= levels.size():
			l = 0
		
		switch_to_level(l)

func switch_to_level(level_index : int):
	_player.get_body().hide()
	
	if current_level != -1:
		levels[current_level].hide()
		
	current_level = level_index
	
	levels[current_level].show()
	
	if _player.get_parent():
		_player.get_parent().place_player(null)
		_player.get_parent().remove_child(_player)
	
	levels[current_level].add_child(_player)
	levels[current_level].place_player(_player)
#	_player.get_body().world = levels[current_level]
	_player.get_body().show()

func load_character(file_name: String) -> void:
	_player_file_name = file_name

	_player = ESS.entity_spawner.load_player(_player_file_name, Vector3.ZERO, 1) as Entity
	_player.get_body().hide()
	#Server.sset_seed(_player.sseed)
	
	call_deferred("switch_to_level", 0)

func save() -> void:
	if _player == null or _player_file_name == "":
		return

	ESS.entity_spawner.save_player(_player, _player_file_name)

#so body won't have to check things every time
func pixel_to_tile(x, y):
	return Vector2.ZERO

func tile_to_pixel_center(x, y):
	return Vector2.ZERO

func is_position_walkable(x : int, y : int) -> bool:
	return false
	
func get_enemy_at_tile(x : int, y : int) -> Entity:
	return null

func place_player(player: Entity) -> void:
	return
