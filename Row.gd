extends Control
const TagScn = preload("Tag.tscn")

enum PLUGIN_STATE {
	PLUGGED, UNPLUGGED, INSTALLED, CHANGED, UPDATE
}

onready var plugin_name = $"%PluginName"
onready var plugin_args = $"%PluginArgs"
onready var plugin_state = $"%PluginState"


func add_tag(text):
	var tag = TagScn.instance()
	plugin_args.add_child(tag)
	tag.label.text = text
	return tag

func set_plugin_state(state):
	var color = Color.transparent
	var tooltip = ""
	match state:
		PLUGIN_STATE.PLUGGED:
			color = Color.orange
			tooltip = "Plugged"
		PLUGIN_STATE.UNPLUGGED:
			color = Color.red
			tooltip = "Unplugged"
		PLUGIN_STATE.INSTALLED:
			color = Color.green
			tooltip = "Installed"
		PLUGIN_STATE.CHANGED:
			color = Color.yellow
			tooltip = "Changed"
		PLUGIN_STATE.UPDATE:
			color = Color.blue
			tooltip = "Outdated"
	color.a = 0.1
	set_plugin_state_color(color)
	plugin_state.hint_tooltip = tooltip

func set_plugin_state_color(color):
	var stylebox = plugin_state.get("custom_styles/panel")
	stylebox.bg_color = color
	stylebox.shadow_color = color
	stylebox.shadow_color.a = 0.6
