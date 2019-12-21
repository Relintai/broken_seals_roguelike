extends VBoxContainer

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

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
var health : Stat = null

func _ready():
	name_label = get_node(name_label_path) as Label
	health_bar = get_node(health_bar_path) as TextureProgress
	health_bar_label = get_node(health_bar_label_path) as Label
	
	entity = get_node("..") as Entity
	health = entity.get_health()
	
	health.connect("c_changed", self, "c_health_changed")
	
	name_label.text = entity.centity_name
	
	entity.connect("cname_changed", self, "cname_changed")
	entity.connect("onc_mouse_entered", self, "onc_entity_mouse_entered")
	entity.connect("onc_mouse_exited", self, "onc_entity_mouse_exited")
	entity.connect("onc_targeted", self, "onc_targeted")
	entity.connect("onc_untargeted", self, "onc_untargeted")

	c_health_changed(health)
	
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

	
	var position : Vector2 = entity.position
	
	position = get_global_transform().xform_inv(position)
	
	position.x -= (rect_size.x / 2.0 + 24) * rect_scale.x
	position.y -= 130 * rect_scale.y
	
	set_position(position)
	
	
func set_max_distance(var value : float) -> void:
	max_distance_squared = value * value
	
	max_distance = value

func c_health_changed(stat : Stat) -> void:
	if health.cmax == 0:
		health_bar.max_value = 1
		health_bar.value = 0
		
		return
	
	health_bar.max_value = stat.cmax
	health_bar.value = stat.ccurrent
	
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
	
func onc_targeted() -> void:
	targeted = true

	modulate = targeted_color
	interpolate_scale(targeted_scale)
	
func onc_untargeted() -> void:
	targeted = false
	
	modulate = normal_color
	interpolate_scale(normal_scale)

func interpolate_scale(target : Vector2) -> void:
	target_scale = target
	interpolating = true
