extends EditorInspectorPlugin
class_name LabelInEditorInspectorPlugin


func _can_handle(_object: Object) -> bool:
	return true

	

func _parse_property(
	_object: Object,
	_type: int,
	name: String,
	_hint_type: PropertyHint,
	hint_string: String,
	_usage_flags: int,
	_wide: bool
) -> bool:
	
	if hint_string.contains(LabelInEditor.HIGHLIGHTED_HINT_STRING):
		var container: HBoxContainer = HBoxContainer.new()
		var margin_container: MarginContainer = MarginContainer.new()
		margin_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin_container.add_theme_constant_override("margin_left", 10)
		
		var name_label: Label = Label.new()
		name_label.text = name
		name_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
		name_label.clip_text = true
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin_container.add_child(name_label)
		container.add_child(margin_container)
		
		var value_line_edit: LineEdit = LineEdit.new()
		value_line_edit.text = str(_object.get(name))
		value_line_edit.editable = false
		value_line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(value_line_edit)
		add_custom_control(container)
		return true
	if hint_string.contains(LabelInEditor.READONLY_HINT_STRING):
		var container: HBoxContainer = HBoxContainer.new()
		var margin_container: MarginContainer = MarginContainer.new()
		margin_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin_container.add_theme_constant_override("margin_left", 10)
		
		var name_label: Label = Label.new()
		name_label.text = name
		name_label.clip_text = true
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin_container.add_child(name_label)
		container.add_child(margin_container)
		
		var value_line_edit: LineEdit = LineEdit.new()
		value_line_edit.text = str(_object.get(name))
		value_line_edit.editable = false
		value_line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(value_line_edit)
		
		add_custom_control(container)
		return true
	return false
