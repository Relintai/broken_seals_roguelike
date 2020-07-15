extends VBoxContainer

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

export(float) var max_distance : float = 70 setget set_max_distance
var max_distance_squared : float = max_distance * max_distance

export(NodePath) var name_label_path : NodePath = "Name"
export(NodePath) var health_bar_path : NodePath = "HealthBar"
export(NodePath) var health_bar_label_path : NodePath = "HealthBar"

export(Color) var normal_color : Color = Color("#e7e7e7")
export(Vector2) var normal_scale : Vector2 = Vector2(0.75, 0.75)
export(Color) var mouseover_color : Color = Color("#ffffff")
export(Vector2) var mouseover_scale : Vector2 = Vector2(0.85, 0.85)
export(Color) var targeted_color : Color = Color("#ffffff")
export(Vector2) var targeted_scale : Vector2 = Vector2(0.85, 0.85)

var target_scale : Vector2
var interpolating : bool

var targeted : bool = false

var name_label : Label = null
var health_bar : TextureProgress = null
var health_bar_label : Label = null

var entity : Entity = null
var health : EntityResource = null

var _health : EntityResource

var offset : int = 60

func _enter_tree():
	var m = get_node_or_null("/root/Main")
	if m != null:
		var ts = m.get_tile_size()
		
		if ts == 8:
			offset = 20
		elif ts == 16:
			offset = 24
		elif ts == 32:
			offset = 34
	
	name_label = get_node(name_label_path) as Label
	health_bar = get_node(health_bar_path) as TextureProgress
	health_bar_label = get_node(health_bar_label_path) as Label
	
	entity = get_node("..") as Entity
	entity.connect("centity_resource_added", self, "on_centity_resource_added")
	
	name_label.text = entity.centity_name
	
	entity.connect("cname_changed", self, "cname_changed")
	entity.connect("notification_cmouse_entered", self, "onc_entity_mouse_entered")
	entity.connect("notification_cmouse_exited", self, "onc_entity_mouse_exited")
	entity.connect("notification_ctargeted", self, "notification_ctargeted")
	entity.connect("notification_cuntargeted", self, "notification_cuntargeted")
	
	modulate = normal_color
	set_scale(normal_scale)
	
	target_scale = normal_scale
	interpolating = false
	
	set_process(true)

func _process(delta):
	if interpolating:
		var d : Vector2 = ((target_scale - get_scale()).normalized() * delta) + get_scale()

		set_scale(d)

		if (get_scale() - target_scale).length() < 0.04:
			interpolating = false
	
	var position : Vector2 = entity.get_body().position
	
	position.x -= (rect_size.x / 2.0) * rect_scale.x
	position.y -= offset
	
	set_position(position)
	
	
func set_max_distance(var value : float) -> void:
	max_distance_squared = value * value
	
	max_distance = value
	
func c_health_changed() -> void:
	if _health.max_value == 0:
		health_bar.max_value = 1
		health_bar.value = 0
		return
		
	health_bar.max_value = _health.max_value
	health_bar.value = _health.current_value
	
#	if stat.cmax != 0:
#		health_bar_label.text = str(int(stat.ccurrent / stat.cmax * 100))


func cname_changed(ent : Entity) -> void:
	name_label.text = ent.centity_name

func onc_entity_mouse_entered() -> void:
	if targeted:
		return
	
	modulate = mouseover_color
	interpolate_scale(mouseover_scale)
	
func onc_entity_mouse_exited() -> void:
	if targeted:
		return
	
	modulate = normal_color
	interpolate_scale(normal_scale)
	
	
func notification_ctargeted() -> void:
	targeted = true

	modulate = targeted_color
	interpolate_scale(targeted_scale)
	
func notification_cuntargeted() -> void:
	targeted = false
	
	modulate = normal_color
	interpolate_scale(normal_scale)

func interpolate_scale(target : Vector2) -> void:
	target_scale = target
	interpolating = true

func on_centity_resource_added(resorce) -> void:
	if health != null:
		return
	
	_health = entity.getc_health()
	_health.connect("changed", self, "c_health_changed")
	c_health_changed()
