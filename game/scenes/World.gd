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

export(bool) var spawn_mobs : bool = true
export(bool) var editor_generate : bool = false setget set_editor_generate, get_editor_generate
export(bool) var show_loading_screen : bool = true
export(bool) var generate_on_ready : bool = false

var initial_generation : bool = false

var _editor_generate : bool

var _player_file_name : String
var _player : Entity

enum Tile { Floor, Wall, Door, Ladder, Stone }

var tile_size : int = 32
export(Vector2) var level_size : Vector2 = Vector2(40, 40)
export(int) var level_room_count : int = 9
export(int) var min_room_dimension : int = 5
export(int) var max_room_dimension : int = 8
export(int) var enemy_count : int = 14

var map : Array = []
var rooms : Array = []
var enemies : Array = []
var nav_graph : AStar2D

onready var tile_map : TileMap = $Terrarin
onready var visibility_map : TileMap = $VisibilityMap

func _ready():
	tile_size = get_node("/root/Main").get_tile_size()
	pass # Replace with function body.

func load_character(file_name: String) -> void:
	_player_file_name = file_name
	
	randomize()
	build_level()

	#Place player
	var start_room = rooms.front()
	var player_x = start_room.position.x + 1 + randi() % int(start_room.size.x  - 2)
	var player_y = start_room.position.y + 1 + randi() % int(start_room.size.y  - 2)
	var pos : Vector3 = Vector3(player_x * tile_size + tile_size / 2, player_y * tile_size + tile_size / 2, 0)
	_player = ESS.entity_spawner.load_player(_player_file_name, pos, 1) as Entity
	Server.sset_seed(_player.sseed)
	
	#Place enemies
	for i in range(enemy_count):
		var room = rooms[1 + randi() % (rooms.size() - 1)]
		var x = room.position.x + 1 + randi() % int (room.size.x - 2)
		var y = room.position.y + 1 + randi() % int (room.size.y - 2)
		
		var blocked = false
		for enemy in enemies:
			var body = enemy.get_body()
			var bp = body.get_tile_position()
			if bp.x == x && bp.y == y:
				blocked = true
				break
				
		if !blocked:
			var t = tile_to_pixel_center(x, y)
			var enemy = ESS.entity_spawner.spawn_mob(1, 1, Vector3(t.x, t.y, 0))
			
			enemies.append(enemy)
			
	
	tile_map.update_dirty_quadrants()
	
	call_deferred("update_visibility")

func player_moved():
	_player.update(1)
	
	for e in enemies:
		e.update(1)
	
	call_deferred("update_visibility")

func update_visibility():
	if _player == null:
		return
		
	var body = _player.get_body()
	
	if body == null:
		return
		
	var tp : Vector2 = body.get_tile_position()
	
	var space_state : Physics2DDirectSpaceState = get_world_2d().direct_space_state
	
	for x in range(level_size.x):
		for y in range(level_size.y):
			if visibility_map.get_cell(x, y) == 0:
				var x_dir = 1 if x < tp.x else -1
				var y_dir = 1 if y < tp.y else -1
				var test_point = tile_to_pixel_center(x, y) + Vector2(x_dir, y_dir) * tile_size / 2
				
				var occlusion = space_state.intersect_ray(body.transform.origin, test_point)

				if !occlusion || (occlusion.position - test_point).length() < 1:
					visibility_map.set_cell(x, y, -1)
					
	for e in enemies:
		var b = e.get_body()
		
		if !b.visible:
			var pos : Vector2 = b.transform.origin
			
			var occlusion = space_state.intersect_ray(body.transform.origin, pos)
			
			if !occlusion:
				b.set_visibility(true)
				e.sets_target(_player)

func clear_path(tile):
	var new_point = nav_graph.get_available_point_id()
	nav_graph.add_point(new_point, Vector2(tile.x, tile.y))
	
	var points_to_conect = []
	
	if tile.x > 0 && map[tile.x - 1][tile.y] == Tile.Floor:
		points_to_conect.append(nav_graph.get_closest_point(Vector2(tile.x - 1, tile.y)))
		
	if tile.y > 0 && map[tile.x][tile.y - 1] == Tile.Floor:
		points_to_conect.append(nav_graph.get_closest_point(Vector2(tile.x, tile.y - 1)))
		
	if tile.x < 0 && map[tile.x + 1][tile.y] == Tile.Floor:
		points_to_conect.append(nav_graph.get_closest_point(Vector2(tile.x + 1, tile.y)))
		
	if tile.y < 0 && map[tile.x][tile.y + 1] == Tile.Floor:
		points_to_conect.append(nav_graph.get_closest_point(Vector2(tile.x, tile.y + 1)))
		
	for point in points_to_conect:
		nav_graph.connect_points(point, new_point)

func pixel_to_tile(x, y):
	return tile_map.world_to_map(Vector2(x, y))

func tile_to_pixel_center(x, y):
	return Vector2((x + 0.5) * tile_size, (y + 0.5) * tile_size)

func is_position_walkable(x : int, y : int) -> bool:
	var type = map[x][y]

	if type == Tile.Wall:
		return false
	elif type == Tile.Stone:
		return false
		
	for e in enemies:
		var pos : Vector2 = e.get_body().get_tile_position()
		if pos.x == x && pos.y == y:
			return false
		
	return true
	
func get_enemy_at_tile(x : int, y : int) -> Entity:
	for e in enemies:
		var pos : Vector2 = e.get_body().get_tile_position()
		if pos.x == x && pos.y == y:
			return e
		
	return null
		
func build_level():
	rooms.clear()
	map.clear()
	tile_map.clear()
	
	for e in enemies:
		e.queue_free()
		
	enemies.clear()
	
	nav_graph = AStar2D.new()
	
	for x in range(level_size.x):
		map.append([])
		for y in range(level_size.y):
			map[x].append(Tile.Stone)
			tile_map.set_cell(x, y, Tile.Stone)
			visibility_map.set_cell(x, y, 0)
			
	var free_regions = [Rect2(Vector2(2, 2), level_size - Vector2(4, 4))]

	for i in range(level_room_count):
		add_room(free_regions)
		
		if free_regions.empty():
			break
			
	connect_rooms()

func connect_rooms():
	var stone_graph : AStar2D = AStar2D.new()
	var point_id : int = 0
	
	for x in range(level_size.x):
		for y in range(level_size.y):
			if map[x][y] == Tile.Stone:
				stone_graph.add_point(point_id, Vector2(x, y))
				
				#connect to left if also stone
				if x > 0 && map[x - 1][y] == Tile.Stone:
					var left_point = stone_graph.get_closest_point(Vector2(x - 1, y))
					stone_graph.connect_points(point_id, left_point)
					
				#connect to above if also stone
				if y > 0 && map[x][y - 1] == Tile.Stone:
					var above_point = stone_graph.get_closest_point(Vector2(x, y - 1))
					stone_graph.connect_points(point_id, above_point)
					
				point_id += 1
				
	#Build an AStar graph of room connections
	var room_graph  : AStar2D = AStar2D.new()
	point_id = 0
	for room in rooms:
		var room_center = room.position + room.size / 2
		room_graph.add_point(point_id, Vector2(room_center.x, room_center.y))
		point_id += 1
		
	#Add random connections until everything is connected
		
		while !is_everything_connected(room_graph):
			add_random_connection(stone_graph, room_graph)
		
func is_everything_connected(graph : AStar2D):
	var points = graph.get_points()
	var start = points.pop_back()
	
	for point in points:
		var path = graph.get_point_path(start, point)
		
		if !path:
			return false
			
	return true
	
func add_random_connection(stone_graph : AStar2D, room_graph : AStar2D):
	#Pick rooms to connect
	
	var start_room_id = get_least_connected_point(room_graph)
	var end_room_id = get_nearest_unconnected_point(room_graph, start_room_id)
	
	#Pick door locations
	var start_position = pick_random_door_location(rooms[start_room_id])
	var end_position = pick_random_door_location(rooms[end_room_id])
	
	#Find a path to connect the doors to each other
	var closest_start_point = stone_graph.get_closest_point(start_position)
	var closest_end_point = stone_graph.get_closest_point(end_position)
	
	var path = stone_graph.get_point_path(closest_start_point, closest_end_point)
	assert(path)
	
	#Add path to the map
	set_tile(start_position.x, start_position.y, Tile.Door)
	set_tile(end_position.x, end_position.y, Tile.Door)
	
	for position in path:
		set_tile(position.x, position.y, Tile.Floor)
		
	room_graph.connect_points(start_room_id, end_room_id)
	
			
func get_least_connected_point(graph : AStar2D):
	var point_ids = graph.get_points()
	
	var least
	var tied_for_least = []
	
	for point in point_ids:
		var count = graph.get_point_connections(point).size()
		
		if !least || count < least:
			least = count
			tied_for_least = [point]
		elif count == least:
			tied_for_least.append(point)
			
	return tied_for_least[randi() % tied_for_least.size()]
	
func get_nearest_unconnected_point(graph : AStar2D, target_point):
	var target_position = graph.get_point_position(target_point)
	var point_ids = graph.get_points()
	
	var nearest
	var tied_for_nearest = []
	
	for point in point_ids:
		if point == target_point:
			continue
		
		var path = graph.get_point_path(point, target_point)
		
		if path:
			continue
			
		var dist = (graph.get_point_position(point) - target_position).length()
		
		if !nearest || dist < nearest:
			nearest = dist
			tied_for_nearest = [point]
		elif dist == nearest:
			tied_for_nearest.append(point)
			
	return tied_for_nearest[randi() % tied_for_nearest.size()]
			
func pick_random_door_location(room):
	var options = []
	
	#Top and bottom walls
	for x in range(room.position.x + 1, room.end.x - 2):
		options.append(Vector2(x, room.position.y))
		options.append(Vector2(x, room.end.y))
		
	#Left and right walls
	for y in range(room.position.y + 1, room.end.y - 2):
		options.append(Vector2(room.position.x, y))
		options.append(Vector2(room.end.x, y))
		
	return options[randi() % options.size()]
			
func add_room(free_regions):
	var region = free_regions[randi() % free_regions.size()]
	
	var size_x = min_room_dimension
	if region.size.x > min_room_dimension:
		size_x += randi() % int(region.size.x - min_room_dimension)
		
	var size_y = min_room_dimension
	if region.size.y > min_room_dimension:
		size_y += randi() % int(region.size.y - min_room_dimension)
		
	size_x = min(size_x, min_room_dimension)
	size_y = min(size_y, min_room_dimension)
	
	var start_x = region.position.x
	if region.size.x > size_x:
		start_x += randi() % int(region.size.x - size_x)
		
	var start_y = region.position.y
	if region.size.y > size_y:
		start_y += randi() % int(region.size.y - size_y)
		
	var room = Rect2(start_x, start_y, size_x, size_y)
	rooms.append(room)
	
	for x in range(start_x, start_x + size_x):
		set_tile(x, start_y, Tile.Wall)
		set_tile(x, start_y + size_y - 1, Tile.Wall)
		
	for y in range(start_y, start_y + size_y):
		set_tile(start_x, y, Tile.Wall)
		set_tile(start_x + size_x - 1, y, Tile.Wall)
		
		for x in range(start_x + 1, start_x + size_x - 1):
			set_tile(x, y, Tile.Floor)
			
	cut_regions(free_regions, room)

func cut_regions(free_regions, region_to_remove):
	var removal_queue = []
	var addition_queue = []
	
	for region in free_regions:
		if region.intersects(region_to_remove):
			removal_queue.append(region)
			
			var leftover_left = region_to_remove.position.x - region.position.x - 1
			var leftover_right = region_to_remove.end.x - region_to_remove.end.x - 1
			var leftover_above = region_to_remove.position.y - region.position.y - 1
			var leftover_below = region.end.y - region_to_remove.end.y - 1
			
			if leftover_left >= min_room_dimension:
				addition_queue.append(Rect2(region.position, Vector2(leftover_left, region.size.y)))
				
			if leftover_right >= min_room_dimension:
				addition_queue.append(Rect2(Vector2(region_to_remove.end.x + 1, region.position.y), Vector2(leftover_right, region.size.y)))
				
			if leftover_above >= min_room_dimension:
				addition_queue.append(Rect2(region.position, Vector2(region.size.x, leftover_above)))
				
			if leftover_below >= min_room_dimension:
				addition_queue.append(Rect2(Vector2(region.position.x, region_to_remove.end.y + 1), Vector2(region.size.x, leftover_below)))
				
	for region in removal_queue:
		free_regions.erase(region)
	
	for region in addition_queue:
		free_regions.append(region)


func set_tile(x, y, type):
	map[x][y] = type
	tile_map.set_cell(x, y, type)
	
	if type == Tile.Floor:
		clear_path(Vector2(x, y))

func save() -> void:
	if _player == null or _player_file_name == "":
		return

	ESS.entity_spawner.save_player(_player, _player_file_name)
	
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
