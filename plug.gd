extends "res://addons/gd-plug/plug.gd"




func _plugging():
	plug("imjp94/UIDesignTool")
	# plug("imjp94/gd-blender-3d-shortcuts")
	plug("imjp94/gd-YAFSM", {"include":["."], "exclude":["build", "addons"]})
	plug("imjp94/gd-shader-cache", {"branch": "godot3", "tag": "godot2", "commit": "71712ef6bc897df253282d32d54ad8a29522cdf8"})
	plug("imjp94/gd-test", {"dev": true, "on_updated": "po"})
	plug("HungryProton/scatter", {"install_root": "addons/scatter", "include": ["."]})
