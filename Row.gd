extends Control
const TagScn = preload("Tag.tscn")

onready var plugin_name = $"%PluginName"
onready var plugin_args = $"%PluginArgs"


func add_tag(text):
	var tag = TagScn.instance()
	plugin_args.add_child(tag)
	tag.label.text = text
	return tag
