extends Control
const RowScn = preload("res://Row.tscn")

onready var plugin_list = $"%PluginList"
onready var init_btn = $"%InitBtn"
onready var update_btn = $"%UpdateBtn"

var gd_plug
var project_dir = Directory.new()

var _is_executing = false


func _ready():
	project_dir.open("res://")
	load_gd_plug()
	update_plugin_list(get_plugged_plugins(), get_installed_plugins())
	update_btn.get_popup().connect("index_pressed", self, "_on_update_popup_menu_index_pressed")

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
		update_btn.show()

		var gd_plug_script = load("plug.gd")
		gd_plug_script.reload() # Reload gd-plug script to get updated
		gd_plug = gd_plug_script.new()
		gd_plug._plug_start()
		gd_plug._plugging()
	else:
		if project_dir.file_exists("addons/gd-plug/plug.gd"):
			init_btn.show()
			update_btn.hide()
			
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

	for child in plugin_list.get_children():
		child.queue_free()
	for plugin_name in plugin_names:
		var plugin = plugged.get(plugin_name) if plugin_name in plugged else installed.get(plugin_name)
		var is_plugged = plugin_name in plugged
		var is_installed = plugin_name in installed
		var row = RowScn.instance()
		plugin_list.add_child(row)

		row.plugin_name.text = plugin_name
		row.plugin_name.hint_tooltip = plugin.url

		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Color.transparent
		stylebox.bg_color.a = 0.1
		row.set("custom_styles/panel", stylebox)

		var color_state = Color.transparent
		if is_installed:
			if is_plugged:
				row.set_plugin_state(2)
				color_state = Color.green
			else:
				row.set_plugin_state(1)
				color_state = Color.red
		else:
			row.set_plugin_state(0)
			color_state = Color.orange
		
		for plugin_arg in plugin.keys():
			var value = plugin[plugin_arg]
			if not value:
				continue

			match plugin_arg:
				"install_root":
					row.add_tag("install root: %s" % str(value))
				"include":
					row.add_tag("include %s" % str(value))
				"exclude":
					row.add_tag("exclude %s" % str(value))
				"branch":
					row.add_tag("branch: %s" % str(value))
				"tag":
					row.add_tag("tag: %s" % str(value))
				"commit":
					var tag = row.add_tag(str(value).left(8))
					tag.hint_tooltip = str(value)
				"dev":
					if value:
						row.add_tag("dev")
				"on_updated":
					row.add_tag("on_updated: %s" % str(value))

func disable_buttons(disabled=true):
	init_btn.disabled = disabled
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

func _on_update_popup_menu_index_pressed(index):
	match index:
		1:
			OS.set_environment("production", "true")
		2:
			OS.set_environment("force", "true")
	gd_plug_execute_threaded("_plug_install")

func get_plugged_plugins():
	return gd_plug._plugged_plugins if is_instance_valid(gd_plug) else {}

func get_installed_plugins():
	return gd_plug.installation_config.get_value("plugin", "installed", {}) if is_instance_valid(gd_plug) else {}
