tool
extends EditorPlugin

const UI = preload("res://addons/gd-plug-ui/scene/plugin_settings/PluginSettings.tscn")

var control = UI.instance()

func _enter_tree():
	add_control_to_container(EditorPlugin.CONTAINER_PROJECT_SETTING_TAB_LEFT, control)
	var tab_container = control.get_parent()
	var plugins_tab
	for child in tab_container.get_children():
		if child.name == "Plugins":
			plugins_tab = child
			break
	if plugins_tab:
		tab_container.move_child(control, plugins_tab.get_index())
	else:
		tab_container.move_child(control, tab_container.get_child_count()-1)

func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_PROJECT_SETTING_TAB_LEFT, control)
	control.queue_free()
