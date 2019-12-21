extends Navigation2D

export(bool) var editor_generate : bool = false setget set_editor_generate, get_editor_generate
export(bool) var show_loading_screen : bool = true
export(bool) var generate_on_ready : bool = false

var initial_generation : bool = false

var _editor_generate : bool

var _player_file_name : String
var _player : Entity

func _ready():
	pass # Replace with function body.

func load_character(file_name: String) -> void:
	_player_file_name = file_name
	_player = Entities.load_player(file_name, Vector2(5, 5), 1) as Entity
	#TODO hack, do this properly
#	_player.set_physics_process(false)
	
	Server.sset_seed(_player.sseed)
	
	generate()


func generate() -> void:
	for x in range(-5, 5):
		for y in range(-5, 5):
			Entities.spawn_mob(1, 50, Vector2(x * 200, y * 200))

func save() -> void:
	if _player == null or _player_file_name == "":
		return

	Entities.save_player(_player, _player_file_name)
	
func _generation_finished():

	if show_loading_screen and not Engine.editor_hint:
		get_node("..").hide_loading_screen()
		
#	if _player:
#		_player.set_physics_process(true)

func get_editor_generate() -> bool:
	return _editor_generate
	
func set_editor_generate(value : bool) -> void:
	if value:
		#library.refresh_rects()
		
		#level_generator.setup(self, current_seed, false, library)
		#spawn()
		pass
	else:
		#spawned = false
		#clear()
		pass
		
	_editor_generate = value
