class_name IDPicker
extends EditorProperty

const NoCreateEditorResourcePicker := preload("res://addons/id_picker/id_picker_resource_picker.gd")

var _resource_picker: EditorResourcePicker = NoCreateEditorResourcePicker.new()

var _object: Object
var _property_name: String
var _base_type: String


func _init(with_object: Object, with_property_name: String, with_base_type: String) -> void:
	_object = with_object
	_property_name = with_property_name
	_base_type = with_base_type

	_resource_picker.set_base_type("ResourceWithId")
	_resource_picker.editable = true
	_resource_picker.resource_changed.connect(_on_resource_changed)

	add_child(_resource_picker)


func _on_resource_changed(resource: Resource) -> void:
	if resource == null:
		return
	_object.set(_property_name, resource.id)
	emit_changed(_property_name, resource.id)
	update_property()


func _update_property() -> void:
	var resource_id: String = _object.get(_property_name)
	var edited_resource: Resource = _get_resource_by_id(resource_id)
	_resource_picker.edited_resource = edited_resource


func _get_resource_by_id(id: String) -> Resource:
	for resource_path: String in ResourcesWithIdLibrary.pathes:
		var resource: Resource = ResourceLoader.load(resource_path)
		if resource and resource.get("id") == id:
			return resource
	return null
