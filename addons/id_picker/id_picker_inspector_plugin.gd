extends EditorInspectorPlugin
class_name IdPickerInspectorPlugin


func _can_handle(_object: Object) -> bool:
	return true


func _parse_property(
	object: Object,
	_type: int,
	name: String,
	_hint_type: PropertyHint,
	_hint_string: String,
	_usage_flags: int,
	_wide: bool
) -> bool:
	if name.ends_with("id_picker"):
		var base_type: String = name.replace("_id_picker", "").strip_edges()
		var custom_editor = IDPicker.new(object, name, base_type)
		add_property_editor(name, custom_editor)
		return true
	return false
