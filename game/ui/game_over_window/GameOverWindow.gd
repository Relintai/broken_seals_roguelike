extends PanelContainer

var _player : Entity

func set_player(p_player: Entity) -> void:
	if _player != null:
		_player.disconnect("diecd", self, "on_died")

	_player = p_player
	
	_player.connect("diecd", self, "on_died")

func on_died(p_player: Entity) -> void:
	show()
