@tool
extends EditorInspectorPlugin
class_name DispenserOngoingEditorInspectorPlugin

var _predefined_remove_triggers: PredefinedTriggers = preload(
	"res://triggers/predefined/for_editor/predefined_remove_triggers_in_ongoing.tres"
)
var _predefined_add_triggers: PredefinedTriggers = preload(
	"res://triggers/predefined/for_editor/predefined_add_triggers_in_ongoing.tres"
)
var _predefined_affected_units_filters: PredefinedUnitCollectionFilters = preload(
	"res://filters/predefined/for_editor/affected_units_predefined_filters.tres"
)


func _can_handle(object: Object) -> bool:
	return object is DispenseOngoingStrategyData


func _parse_property(
	object: Object,
	_type: int,
	name: String,
	_hint_type: PropertyHint,
	_hint_string: String,
	_usage_flags: int,
	_wide: bool
) -> bool:
	var is_affected_unit_world: bool = object.get(DispenseOngoingStrategyData.AFFECTED_UNITS_TYPE_PROP_NAME) == DispenseOngoingStrategyData.AffectedUnitsType.WORLD
	var is_affected_unit_is_unit_creator: bool = object.get(DispenseOngoingStrategyData.AFFECTED_UNITS_TYPE_PROP_NAME) == DispenseOngoingStrategyData.AffectedUnitsType.UNIT_CREATOR_OF_ONGOING
	
	if name == DispenseOngoingStrategyData.REMOVE_TRIGGER_DATA_PROP_NAME:
		var custom_editor: TriggerDataWithEnumOngoingPropertyEditor = (
			TriggerDataWithEnumOngoingPropertyEditor
			. new(
				object,
				name,
				DispenseOngoingStrategyData.REMOVE_TRIGGER_TYPE_PROP_NAME,
				DispenseOngoingStrategyData.RemoveTriggerType,
				DispenseOngoingStrategyData.RemoveTriggerType.PREDEFINED,
				_predefined_remove_triggers
			)
		)
		var hint_label1: Label = Label.new()
		hint_label1.text = "Триггер удаления диспенсера, при его удалении удалятся созданные им онгоинги"
		hint_label1.offset_left = 12
		var v_box_container: VBoxContainer = VBoxContainer.new()
		v_box_container.add_child(hint_label1)
		var margin_container: MarginContainer = MarginContainer.new()
		margin_container.add_theme_constant_override("margin_left", 10)
		margin_container.add_child(v_box_container)

		add_property_editor(name, custom_editor, false, "Когда удаляется диспенсер")
		add_custom_control(margin_container)
		if not (
			object.get(DispenseOngoingStrategyData.AFFECTED_UNITS_TYPE_PROP_NAME)
			in [
				DispenseOngoingStrategyData.AffectedUnitsType.WORLD,
				DispenseOngoingStrategyData.AffectedUnitsType.ERROR
			]
		):
			if is_affected_unit_is_unit_creator:
				var hint_label3: Label = Label.new()
				hint_label3.text = "Юнит-создатель онгоингов (висит диспенсер на карте - ричард, на здании - здание и тд)"
				hint_label3.offset_left = 12
				v_box_container.add_child(hint_label3)
			else:
				var hint_label2: Label = Label.new()
				hint_label2.text = "При смерти юнита уничтожаются и онгоинги принадлежащие ему"
				hint_label2.offset_left = 12
				v_box_container.add_child(hint_label2)
		return (
			object.get(DispenseOngoingStrategyData.REMOVE_TRIGGER_TYPE_PROP_NAME)
			!= DispenseOngoingStrategyData.RemoveTriggerType.CUSTOM
		)
		
	if name == DispenseOngoingStrategyData.AFFECTED_UNITS_FILTER_DATA_PROP_NAME:
		var custom_editor: TriggerDataWithEnumOngoingPropertyEditor = (
			TriggerDataWithEnumOngoingPropertyEditor
			. new(
				object,
				name,
				DispenseOngoingStrategyData.AFFECTED_UNITS_TYPE_PROP_NAME,
				DispenseOngoingStrategyData.AffectedUnitsType,
				DispenseOngoingStrategyData.AffectedUnitsType.PREDEFINED,
				_predefined_affected_units_filters
			)
		)
		add_custom_control(_separator_between_props())
		add_property_editor(name, custom_editor, false, "На кого добавляется онгоинг")
		return (
			object.get(DispenseOngoingStrategyData.AFFECTED_UNITS_TYPE_PROP_NAME)
			!= DispenseOngoingStrategyData.AffectedUnitsType.CUSTOM
		)
	if name == DispenseOngoingStrategyData.ADD_TRIGGER_DATA_PROP_NAME:
		var custom_editor: TriggerDataWithEnumOngoingPropertyEditor = (
			TriggerDataWithEnumOngoingPropertyEditor
			. new(
				object,
				name,
				DispenseOngoingStrategyData.ADD_TRIGGER_TYPE_PROP_NAME,
				DispenseOngoingStrategyData.AddTriggerType,
				DispenseOngoingStrategyData.AddTriggerType.PREDEFINED,
				_predefined_add_triggers
			)
		)
		add_custom_control(_separator_between_props())
		var hint_label: String = "Когда добавляется онгоинг на юниты"
		if (is_affected_unit_world):
			hint_label = "Когда добавляется онгоинг в систему"
		add_property_editor(name, custom_editor, false, hint_label)
		return (
			object.get(DispenseOngoingStrategyData.ADD_TRIGGER_TYPE_PROP_NAME)
			!= DispenseOngoingStrategyData.AddTriggerType.CUSTOM
		)
	if name == DispenseOngoingStrategyData.AFFECTED_UNITS_DATAS_PROP_NAME:
		return (
			object.get(DispenseOngoingStrategyData.AFFECTED_UNITS_TYPE_PROP_NAME)
			!= DispenseOngoingStrategyData.AffectedUnitsType.UNIT_DATAS
		)


	var show_add_ongoing_when_dispenser_created_prop: bool = object.get(DispenseOngoingStrategyData.ADD_TRIGGER_TYPE_PROP_NAME) != DispenseOngoingStrategyData.AddTriggerType.DISPENSER_CREATED
	if show_add_ongoing_when_dispenser_created_prop:
		var add_ongoing_hint_label: Label = Label.new()
		if is_affected_unit_world:
			add_ongoing_hint_label.text = "Добавлять ли онгоинг в систему при создании диспенсере"
		else:
			add_ongoing_hint_label.text = "Добавлять ли онгоинг на юниты при создании диспенсере"
		add_ongoing_hint_label.offset_left = 12	
			
		var add_ongoing_margin_container: MarginContainer = MarginContainer.new()
		add_ongoing_margin_container.add_theme_constant_override("margin_left", 10)
		add_ongoing_margin_container.add_child(add_ongoing_hint_label)
		
		add_custom_control(add_ongoing_margin_container)	
	if name == DispenseOngoingStrategyData.ADD_ONGOING_WHEN_DISPENSER_CREATED_PROP_NAME:
		return not show_add_ongoing_when_dispenser_created_prop
	return false

func _separator_between_props() -> Control:
	var h_separator = HSeparator.new()
	var sb = StyleBoxLine.new()
	sb.color = Color.GRAY
	sb.thickness = 3
	h_separator.add_theme_constant_override("separation", 20)
	h_separator.add_theme_stylebox_override("separator", sb)
	return h_separator
