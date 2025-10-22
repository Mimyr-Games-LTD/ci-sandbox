@tool
extends EditorPlugin

var _ongoings: DispenserOngoingEditorInspectorPlugin


func _enter_tree() -> void:
	if CiFlags.is_enabled():
		return
	
	_ongoings = DispenserOngoingEditorInspectorPlugin.new()
	add_inspector_plugin(_ongoings)


func _exit_tree() -> void:
	if _ongoings == null:
		return
	remove_inspector_plugin(_ongoings)
