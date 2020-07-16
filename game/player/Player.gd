extends Entity
class_name PlayerGD

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

func _from_dict(dict):
	._from_dict(dict)
	
	randomize()
	sseed = randi()
	
#The world will propbably need to set these later
#func update_visibility() -> void:
#	_query.collision_layer = get_body().get_collision_layer()
#
#	_query.transform = Transform2D(0, get_body().position)
#	var res : Array = get_body().get_world_2d().direct_space_state.intersect_shape(_query)
#
#	#warning-ignore:unassigned_variable
#	var currenty_sees : Array = Array()
#
#	for collision in res:
#		var collider = collision["collider"]
#
#		if collider is Entity and not currenty_sees.has(collider):
#			currenty_sees.append(collider)
#
#
#	#warning-ignore:unassigned_variable
#	var used_to_see : Array = Array()
#
#	for i in range(sees_gets_count()):
#		var ent : Entity = sees_gets(i)
#
#		used_to_see.append(ent)
#
#
#	#warning-ignore:unassigned_variable
#	var currenty_sees_filtered : Array = Array()
#
#	for e in currenty_sees:
#		currenty_sees_filtered.append(e)
#
#	for e in currenty_sees:
#		if used_to_see.has(e):
#			used_to_see.erase(e)
#			currenty_sees_filtered.erase(e)
#
#	for e in used_to_see:
#		var ent : Entity = e as Entity
#
#		if self.get_network_master() != 1:
#			ESS.entity_spawner.despawn_for(self, ent)
#
#		sees_removes(ent)
#
#	for e in currenty_sees_filtered:
#		var ent : Entity = e as Entity
#
#		if self.get_network_master() != 1:
#			ESS.entity_spawner.spawn_for(self, ent)
#
#		sees_adds(ent)


#remote func set_position_remote(pos : Vector2) -> void:
#	if get_tree().is_network_server():
#		rpc("set_position_remote", pos)
#	#print(position)
#	get_body().position = pos

