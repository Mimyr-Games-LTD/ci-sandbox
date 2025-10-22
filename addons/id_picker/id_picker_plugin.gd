@tool
extends EditorPlugin

var _instance: IdPickerInspectorPlugin


func _enter_tree() -> void:
	if CiFlags.is_enabled():
		return
	
	_instance = IdPickerInspectorPlugin.new()
	add_inspector_plugin(_instance)


func _exit_tree() -> void:
	if _instance == null:
		return
	remove_inspector_plugin(_instance)
