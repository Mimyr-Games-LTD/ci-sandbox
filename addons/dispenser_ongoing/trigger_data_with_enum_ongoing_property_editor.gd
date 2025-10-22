@tool
extends EditorProperty
class_name TriggerDataWithEnumOngoingPropertyEditor

var _object: Object
var _variant_data_property_name: String
var _variant_type_enum_property_name: String
var _base_enum: Dictionary
var _predefined_enum_value: int
var _except_base_enum_values: Array

var _enum_control: OptionButton
var _base_enum_key_idx_map: Dictionary[String, int] = {}
var _predefined_variant_name_idx_map: Dictionary[String, int] = {}

var _predefined_idx: int
var _name_resource_map: NameResourceMapConfig


func _init(
	object: Object,
	variant_data_property_name: String,
	variant_enum_type_property_name: String,
	base_enum: Dictionary,
	predefined_enum_value: int,
	with_name_resource_map: NameResourceMapConfig,
	with_except_base_enum_keys: Array = []
) -> void:
	_object = object
	_variant_data_property_name = variant_data_property_name
	_variant_type_enum_property_name = variant_enum_type_property_name
	_base_enum = base_enum
	_predefined_enum_value = predefined_enum_value
	_name_resource_map = with_name_resource_map
	_except_base_enum_values = with_except_base_enum_keys

	var vbox: VBoxContainer = VBoxContainer.new()
	add_child(vbox)

	_enum_control = OptionButton.new()
	_enum_control.item_selected.connect(_on_enum_item_selected)
	vbox.add_child(_enum_control)

	_populate_enum()
	call_deferred("_reload_property")


func _populate_enum() -> void:
	_enum_control.clear()
	_base_enum_key_idx_map.clear()
	_predefined_variant_name_idx_map.clear()

	for enum_name: String in _base_enum.keys():
		var idx: int = _enum_control.get_item_count()
		if _base_enum[enum_name] == _predefined_enum_value:
			continue
		if _base_enum[enum_name] in _except_base_enum_values:
			continue
		_enum_control.add_item(enum_name.capitalize(), idx)
		_base_enum_key_idx_map[enum_name] = idx
	if not _base_enum_key_idx_map.is_empty():
		_enum_control.add_separator("")
	for key: String in _name_resource_map.value().keys():
		var idx: int = _enum_control.get_item_count()
		_enum_control.add_item(key, idx)
		_predefined_variant_name_idx_map[key] = idx


func _reload_property() -> void:
	var current = _object.get(_variant_data_property_name)
	for key: String in _predefined_variant_name_idx_map.keys():
		if _name_resource_map.value()[key] == current:
			_enum_control.select(_predefined_variant_name_idx_map[key])
			return

	# базовый enum
	var enum_val: int = _object.get(_variant_type_enum_property_name)
	for key: String in _base_enum_key_idx_map.keys():
		if _base_enum[key] == enum_val:
			_enum_control.select(_base_enum_key_idx_map[key])
			return


func _on_enum_item_selected(index: int) -> void:
	var selected_id: int = _enum_control.get_selected_id()
	if _predefined_variant_name_idx_map.values().has(selected_id):
		var key = _predefined_variant_name_idx_map.find_key(selected_id)
		var value = _name_resource_map.value()[key]

		_object.set(_variant_type_enum_property_name, _predefined_enum_value)
		emit_changed(_variant_type_enum_property_name, _predefined_enum_value)

		_object.set(_variant_data_property_name, value)
		emit_changed(_variant_data_property_name, value)
	else:
		# базовый enum
		var key = _base_enum_key_idx_map.find_key(selected_id)
		var value: int = _base_enum[key]

		_object.set(_variant_data_property_name, null)
		emit_changed(_variant_data_property_name, null)

		_object.set(_variant_type_enum_property_name, value)
		emit_changed(_variant_type_enum_property_name, value)
	_object.property_list_changed.emit()
