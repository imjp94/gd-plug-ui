tool
extends Control

enum PLUGIN_STATE {
	PLUGGED, UNPLUGGED, INSTALLED, CHANGED, UPDATE
}
const PLUGIN_STATE_COLOR = [
	Color.orange, Color.red, Color.green, Color.yellow, Color.blue
]

onready var tree = $Tree
onready var confirmation_dialog = $"%ConfirmationDialog"
onready var init_btn = $"%InitBtn"
onready var check_for_update_btn = $"%CheckForUpdateBtn"
onready var update_section = $"%UpdateSection"
onready var force_check = $"%ForceCheck"
onready var production_check = $"%ProductionCheck"
onready var update_btn = $"%UpdateBtn"

var gd_plug
var project_dir = Directory.new()

var _is_executing = false


func _ready():
	project_dir.open("res://")
	load_gd_plug()
	update_plugin_list(get_plugged_plugins(), get_installed_plugins())

	tree.set_column_title(0, "Name")
	tree.set_column_title(1, "Arguments")
	tree.set_column_title(2, "Status")

func _process(delta):
	if not is_instance_valid(gd_plug):
		return
	
	gd_plug.threadpool.process(delta)

func _notification(what):
	match what:
		NOTIFICATION_PREDELETE:
			if is_instance_valid(gd_plug):
				gd_plug.threadpool.stop()
		NOTIFICATION_WM_FOCUS_IN:
			load_gd_plug()
			update_plugin_list(get_plugged_plugins(), get_installed_plugins())

func load_gd_plug():
	if is_instance_valid(gd_plug):
		gd_plug.free() # Free instance in order to reload script
	if project_dir.file_exists("plug.gd"):
		init_btn.hide()
		check_for_update_btn.show()
		update_section.show()
		update_btn.show() # Not sure why it is always hidden

		var gd_plug_script = load("plug.gd")
		gd_plug_script.reload() # Reload gd-plug script to get updated
		gd_plug = gd_plug_script.new()
		gd_plug._plug_start()
		gd_plug._plugging()
	else:
		if project_dir.file_exists("addons/gd-plug/plug.gd"):
			init_btn.show()
			check_for_update_btn.hide()
			update_section.hide()
			
			gd_plug = load("addons/gd-plug/plug.gd").new()
		else:
			print("Missing dependency: gd-plug")

func update_plugin_list(plugged, installed):
	var plugin_names = []
	for plugin_name in plugged.keys():
		plugin_names.append(plugin_name)
	for plugin_name in installed.keys():
		if plugin_name in plugin_names:
			continue
		plugin_names.append(plugin_name)

	tree.clear()
	tree.create_item() # root
	for plugin_name in plugin_names:
		var plugin_plugged = plugged.get(plugin_name, {})
		var plugin_installed = installed.get(plugin_name, {})
		var plugin = plugin_plugged if plugin_name in plugged else plugin_installed
		
		var is_plugged = plugin_name in plugged
		var is_installed = plugin_name in installed
		var changes = gd_plug.compare_plugins(plugin_plugged, plugin_installed) if is_installed else {}
		var is_changed = changes.size() > 0

		var plugin_status = 0
		if is_installed:
			if is_plugged:
				if is_changed:
					plugin_status = 3
				else:
					plugin_status = 2
			else:
				plugin_status = 1
		else:
			plugin_status = 0
		
		var plugin_args = []
		for plugin_arg in plugin.keys():
			var value = plugin[plugin_arg]
			if not value:
				continue

			match plugin_arg:
				"install_root":
					plugin_args.append("install root: %s" % str(value))
				"include":
					plugin_args.append("include %s" % str(value))
				"exclude":
					plugin_args.append("exclude %s" % str(value))
				"branch":
					plugin_args.append("branch: %s" % str(value))
				"tag":
					plugin_args.append("tag: %s" % str(value))
				"commit":
					plugin_args.append(str(value).left(8))
				"dev":
					if value:
						plugin_args.append("dev")
				"on_updated":
					plugin_args.append("on_updated: %s" % str(value))
		var plugin_args_text = str(plugin_args).trim_prefix("[").trim_suffix("]")

		var child = tree.create_item(tree.get_root())
		child.set_text_align(0, TreeItem.ALIGN_LEFT)
		child.set_text_align(1, TreeItem.ALIGN_CENTER)
		child.set_text_align(2, TreeItem.ALIGN_CENTER)
		child.set_meta("plugin", plugin)
		child.set_text(0, plugin_name)
		child.set_tooltip(0, plugin.url)
		child.set_text(1, plugin_args_text)
		child.set_text(2, PLUGIN_STATE.keys()[plugin_status])
		child.set_custom_color(2, PLUGIN_STATE_COLOR[plugin_status])

func disable_buttons(disabled=true):
	init_btn.disabled = disabled
	check_for_update_btn.disabled = disabled
	update_btn.disabled = disabled

func gd_plug_execute_threaded(name):
	if not is_instance_valid(gd_plug):
		return
	if _is_executing:
		return
	
	_is_executing = true
	disable_buttons(true)
	gd_plug._plug_start()
	gd_plug._plugging()
	gd_plug.call(name)
	
	while true:
		if gd_plug.threadpool.is_all_thread_finished():
			break
		yield(get_tree(), "idle_frame")

	gd_plug._plug_end()
	disable_buttons(false)
	_is_executing = false
	clear_environment()

	update_plugin_list(get_plugged_plugins(), get_installed_plugins())

func gd_plug_execute(name):
	if not is_instance_valid(gd_plug):
		return
	if _is_executing:
		return
	
	_is_executing = true
	disable_buttons(true)
	gd_plug._plug_start()
	gd_plug._plugging()
	gd_plug.call(name)
	gd_plug._plug_end()
	disable_buttons(false)
	_is_executing = false
	clear_environment()

	update_plugin_list(get_plugged_plugins(), get_installed_plugins())

func clear_environment():
	OS.set_environment("production", "")
	OS.set_environment("test", "")
	OS.set_environment("force", "")

func _on_Init_pressed():
	gd_plug_execute("_plug_init")
	load_gd_plug()
	confirmation_dialog.dialog_text = "Added plug.gd to project"
	confirmation_dialog.popup_centered()

func _on_CheckForUpdateBtn_pressed():
	var installed_plugins = get_installed_plugins()
	var first_child = tree.get_root().get_children()
	if first_child:
		gd_plug.threadpool.enqueue_task(self, "check_for_update", first_child)
		disable_buttons(true)

		while true:
			if gd_plug.threadpool.is_all_thread_finished():
				break
			yield(get_tree(), "idle_frame")
		
		disable_buttons(false)

	confirmation_dialog.dialog_text = "Finished checking updates"
	confirmation_dialog.popup_centered()

func _on_UpdateBtn_pressed():
	if force_check.pressed:
		OS.set_environment("force", "true")
	if production_check.pressed:
		OS.set_environment("production", "true")
	gd_plug_execute_threaded("_plug_install")
	confirmation_dialog.dialog_text = "Finished updating plugins"
	confirmation_dialog.popup_centered()

func get_plugged_plugins():
	return gd_plug._plugged_plugins if is_instance_valid(gd_plug) else {}

func get_installed_plugins():
	return gd_plug.installation_config.get_value("plugin", "installed", {}) if is_instance_valid(gd_plug) else {}

func has_update(plugin):
	if not is_instance_valid(gd_plug):
		return false
	if not plugin:
		return false
	var git = gd_plug._GitExecutable.new(ProjectSettings.globalize_path(plugin.plug_dir), gd_plug.logger)

	var ahead_behind = []
	if git.fetch("origin " + plugin.branch if plugin.branch else "origin").exit == OK:
		ahead_behind = git.get_commit_comparison("HEAD", "origin/" + plugin.branch if plugin.branch else "origin")
	var is_commit_behind = !!ahead_behind[1] if ahead_behind.size() == 2 else false
	if is_commit_behind:
		gd_plug.logger.info("%s %d commits behind, update required" % [plugin.name, ahead_behind[1]])
		return true
	else:
		gd_plug.logger.info("%s up to date" % plugin.name)
		return false

func check_for_update(child):
	var plugin = child.get_meta("plugin")
	var has_update = has_update(plugin)
	if has_update: # TODO: !!!
		child.set_text(2, PLUGIN_STATE.keys()[PLUGIN_STATE.UPDATE])
		child.set_custom_color(2, PLUGIN_STATE_COLOR[PLUGIN_STATE.UPDATE])
	var next_child = child.get_next()
	if next_child:
		check_for_update(next_child)
