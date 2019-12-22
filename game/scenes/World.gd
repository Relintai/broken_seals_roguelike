extends Node2D

# Copyright (c) 2019 Péter Magyar
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

export(PackedScene) var world_layer : PackedScene

export(bool) var editor_generate : bool = false setget set_editor_generate, get_editor_generate
export(bool) var show_loading_screen : bool = true
export(bool) var generate_on_ready : bool = false

var initial_generation : bool = false

var _editor_generate : bool

var _player_file_name : String
var _player : Entity

func _ready():
#	print(get_layer(2))
	pass # Replace with function body.

func get_layer(index : int) -> Navigation2D:
	for ch in get_children():
		if ch.has_method('collision_layer') and ch.collision_layer() == index:
			return ch

	var wl : Navigation2D = world_layer.instance() as Navigation2D
	add_child(wl)
	wl.collision_layer = index
	
	return wl

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
