extends Button

func _ready():
	connect("pressed", self, "on_click")
	
func on_click() -> void:
	get_node("/root/Main").switch_scene(Main.StartSceneTypes.MENU)
