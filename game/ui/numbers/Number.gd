extends Label

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

export(NodePath) var animation_player_path : NodePath = "AnimationPlayer"

export(Color) var damage_color : Color = Color.yellow
export(Color) var heal_color : Color = Color.green

var world_position : Vector2 = Vector2()
var animation_player : AnimationPlayer = null

func _ready() -> void:
	animation_player = get_node(animation_player_path) as AnimationPlayer
	
	animation_player.connect("animation_finished", self, "animation_finished")
	
	set_process(false)

func _process(delta):

	var new_pos : Vector2 = Vector2(world_position.x + rect_position.x / 2.0 - 8, world_position.y + rect_position.y)
	
	set_position(new_pos)
	

func damage(pos : Vector2, value : int, crit : bool) -> void:
	setup(pos, damage_color, value, crit)
	
func heal(pos : Vector2, value : int, crit : bool) -> void:
	setup(pos, heal_color, value, crit)

func setup(pos : Vector2, color : Color, value : int, crit : bool) -> void:
	world_position = pos
	
	text = str(value)
	add_color_override("font_color", color)
	
	if crit:
		animation_player.play("crit")
	else:
		animation_player.play("normal")
		
	set_process(true)

func animation_finished(anim_name : String) -> void:
	queue_free()
