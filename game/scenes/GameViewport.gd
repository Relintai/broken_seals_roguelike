extends Container

export(Vector2) var base_resolution : Vector2 = Vector2(600, 600)
var _scale : Vector2 = Vector2(1, 1)

func _init():
	set_process_input(true);
	set_process_unhandled_input(true);

func _notification(p_what):
	if (p_what == NOTIFICATION_RESIZED):

		for c in get_children():

			if not c is Viewport:
				continue
			
			var ar : float =  0
			var rc : Vector2 = Vector2()
			
#			if get_size().x > get_size().y:
			ar = get_size().y / get_size().x 
			rc = Vector2(base_resolution.x, base_resolution.y * ar)
#			else :
#				ar = get_size().x / get_size().y 
#				rc = Vector2(base_resolution.x * ar, base_resolution.y)

			c.set_size(rc)

			_scale = get_size() / rc

		
	if p_what == NOTIFICATION_ENTER_TREE || p_what == NOTIFICATION_VISIBILITY_CHANGED:
		for c in get_children():

			if not c is Viewport:
				continue

			if is_visible_in_tree():
				c.set_update_mode(Viewport.UPDATE_ALWAYS)
			else:
				c.set_update_mode(Viewport.UPDATE_DISABLED)

			c.set_handle_input_locally(false); #do not handle input locally here

	if p_what == NOTIFICATION_DRAW:
		for c in get_children():
			
			if not c is Viewport:
				continue

			draw_texture_rect(c.get_texture(), Rect2(Vector2(), get_size() * Vector2(1, -1)), false)

func _input(p_event):

	if (Engine.is_editor_hint()):
		return;

	var xform : Transform2D = get_global_transform()

	var scale_xf : Transform2D
	scale_xf = scale_xf.scaled(_scale)
	xform *= scale_xf

	var ev : InputEvent = p_event.xformed_by(xform.affine_inverse())

	for c in get_children():
		
		if not c is Viewport or c.is_input_disabled():
			continue

		c.input(ev)

func _unhandled_input(p_event):

	if Engine.is_editor_hint():
		return

	var xform : Transform2D = get_global_transform()

	var scale_xf : Transform2D
	scale_xf = scale_xf.scaled(_scale)
	xform *= scale_xf
	
	var ev : InputEvent = p_event.xformed_by(xform.affine_inverse())
	
	for c in get_children():
		
		if not c is Viewport or c.is_input_disabled():
			continue

		c.unhandled_input(ev)

