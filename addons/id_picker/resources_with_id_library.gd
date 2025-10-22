@tool
class_name ResourcesWithIdLibrary
extends Object

static var _resources_libraries: Array[String]:
	get:
		if ResourcesWithIdLibrary._resources_libraries_underlying.is_empty():
			ResourcesWithIdLibrary._resources_libraries_underlying = (
				ResourcesWithIdLibrary._find_resources_library_folders()
			)
		return ResourcesWithIdLibrary._resources_libraries_underlying

static var _resources_libraries_underlying: Array[String] = []

static var pathes: Array[String]:
	get:
		return ResourcesWithIdLibrary._find_resource_pathes_in_folders(_resources_libraries)


static func _find_resources_library_folders(path: String = "res://") -> Array:
	var folders: Array[String] = []
	var dir: DirAccess = DirAccess.open(path)

	if dir == null or dir.list_dir_begin() != OK:
		return folders

	var file_name: String = dir.get_next()
	while file_name != "":
		var full_path: String = path + "/" + file_name

		if dir.current_is_dir():
			if file_name == "resources_library":
				folders.append(full_path)
			folders.append_array(ResourcesWithIdLibrary._find_resources_library_folders(full_path))

		file_name = dir.get_next()

	return folders


static func _find_resource_pathes_in_folders(folders: Array[String]) -> Array[String]:
	var resources: Array[String] = []

	for folder: String in folders:
		var dir: DirAccess = DirAccess.open(folder)
		if dir == null or dir.list_dir_begin() != OK:
			continue

		var file_name: String = dir.get_next()
		while file_name != "":
			var full_path: String = folder + "/" + file_name
			if not dir.current_is_dir():
				resources.append(full_path)
			file_name = dir.get_next()

	return resources
