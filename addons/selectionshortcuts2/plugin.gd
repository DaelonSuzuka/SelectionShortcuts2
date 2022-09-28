@tool
extends EditorPlugin

# ******************************************************************************

var move_selection_shortcut = 'Ctrl+F'

@onready var editor_viewport = find_editor_viewport()

func get_all_children(node: Node, _children={}) -> Dictionary:
	_children[node.get_path()] = node

	for child in node.get_children():
		_children[child.get_path()] = child
		if child.get_child_count():
			get_all_children(child, _children)

	return _children

func find_editor_viewport():
	var main_control = get_editor_interface().get_base_control()
	var canvas_item_editor = main_control.get_child(0)
	var children = get_all_children(canvas_item_editor)

	for node in children:
		if children[node] is SubViewport:
			return children[node]

# ------------------------------------------------------------------------------

func _enter_tree():
	pass

func _exit_tree():
	pass

# ******************************************************************************

func get_selected_nodes():
	return get_editor_interface().get_selection().get_selected_nodes()

func get_scene():
	return get_editor_interface().get_edited_scene_root()

# ******************************************************************************

var just_went = false

func _input(event):
	if !(event is InputEventKey):
		return

	if event.as_text() == move_selection_shortcut:
		if event.pressed:
			if just_went:
				return
			move_object_to_cursor()
			just_went = true
		else:
			just_went = false
		return

	if !event.pressed:
		return

# ******************************************************************************

# func get_target_position(mouse_pos):

func move_object_to_cursor():
	var selection = get_selected_nodes()

	var targets = []
	for node in selection:
		if node is CanvasItem:
			targets.append(node)

	var mouse = get_editor_interface().get_base_control().get_global_mouse_position()
	var viewport: Viewport = get_editor_interface().get_edited_scene_root().get_parent()
	var viewport_container = viewport.get_parent()

	var rect = viewport_container.get_global_rect()
	if !rect.has_point(mouse):
		return

	if targets.size() == 0:
		return
		
	var undo = get_undo_redo()
	if targets.size() == 1:
		var target = targets[0]

		var pos = viewport_container.make_canvas_position_local(mouse)
		var xform = viewport.get_final_transform()

		var scale = xform.get_scale().x
		pos = pos * xform
		pos = pos / scale

		var mod = pos / ( scale)
		pos = pos + (mod - pos)

		undo.create_action('Move "%s" to %s' % [target.name, str(target.global_position)])
		undo.add_undo_property(target, 'global_position', target.global_position)
		target.global_position = pos
		undo.add_do_property(target, 'global_position', target.global_position)
		undo.commit_action()

	if targets.size() > 1:
		var center = Vector2()
		
		for target in targets:
			center += target.global_position
		
		center /= targets.size()

		var pos = viewport_container.make_canvas_position_local(mouse)
		var xform = viewport.get_final_transform()

		var scale = xform.get_scale().x
		pos = pos * xform
		pos = pos / scale

		var mod = pos / ( scale)
		pos = pos + (mod - pos)

		var destination = pos
		
		undo.create_action('Move selection to %s' % [str(destination)])
		var offset = destination - center
		for target in targets:
			undo.add_undo_property(target, 'global_position', target.global_position)
			target.global_position += offset
			undo.add_do_property(target, 'global_position', target.global_position)
		undo.commit_action()