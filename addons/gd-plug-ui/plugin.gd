tool
extends EditorPlugin

const UI = preload("res://addons/gd-plug-ui/scene/plugin_settings/PluginSettings.tscn")

var control = UI.instance()
var plugins_tab
var plugins_tab_update_btn

func _enter_tree():
	add_control_to_container(EditorPlugin.CONTAINER_PROJECT_SETTING_TAB_LEFT, control)
	control.connect("updated", self, "_on_control_updated")
	var tab_container = control.get_parent()
	for child in tab_container.get_children():
		if child.name == "Plugins":
			plugins_tab = child
			break
	if plugins_tab:
		tab_container.move_child(control, plugins_tab.get_index())
	else:
		tab_container.move_child(control, tab_container.get_child_count()-1)

	for child in plugins_tab.get_children():
		if child is HBoxContainer:
			for grandchild in child.get_children():
				if grandchild is Button:
					if grandchild.text == "Update":
						plugins_tab_update_btn = grandchild
						plugins_tab_update_btn.connect("pressed", self, "_on_plugins_tab_update_btn_pressed")
						break

func _on_control_updated():
	plugins_tab_update_btn.emit_signal("pressed") # Programmatically press update button in "Plugins" tab

func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_PROJECT_SETTING_TAB_LEFT, control)
	control.queue_free()
