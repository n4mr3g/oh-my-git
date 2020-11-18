class_name Item
extends Node2D

enum IconStatus {NONE, NEW, REMOVED, CONFLICT, EDIT, UNTRACKED}
export(IconStatus) var status setget _set_status
export var label: String setget _set_label
var type = "file"
var item_type
export var editable = true

var attributes

var held
var GRID_SIZE = 60
var file_browser

onready var label_node = $Label
onready var status_icon = $Status

func _ready():
	_set_label(label)
	_set_status(status)
	
	read_from_file()
#	if not editable:
#		type = "nothing"
	#$PopupMenu.add_item("Delete file", 0)

func read_from_file():
	var content
	match item_type:
		"wd":
			content = file_browser.shell.run("cat '%s'" % label)
		"index":
			content = file_browser.shell.run("git show :'%s'" % label)
			modulate = Color(0, 0, 1.0)
		"head":
			content = file_browser.shell.run("git show HEAD:'%s'" % label)
			modulate = Color(0, 0, 0, 0.5)
			
	attributes = helpers.parse(content)
	position.x = int(attributes["x"])
	position.y = int(attributes["y"])

func write_to_file():
	attributes["x"] = str(position.x)
	attributes["y"] = str(position.y)
	
	var content = ""
	for key in attributes:
		content += "%s = %s\n" % [key, attributes[key]]
	file_browser.shell.run("echo \"%s\" > %s" % [content, label])

func _set_label(new_label):
	label = new_label
	if label_node:
		label_node.text = helpers.abbreviate(new_label, 30)

#func _gui_input(event):
#	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
#		emit_signal("clicked", self)
#	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_RIGHT and status != IconStatus.REMOVED:
#		$PopupMenu.set_position(get_global_mouse_position())
#		$PopupMenu.popup()
		
func _set_status(new_status):
	if status_icon:
		match new_status:
			IconStatus.NEW:
				status_icon.texture = preload("res://images/new.svg")
				status_icon.modulate = Color("33BB33")
			IconStatus.REMOVED:
				status_icon.texture = preload("res://images/removed.svg")
				status_icon.modulate = Color("D10F0F")
			IconStatus.CONFLICT:
				status_icon.texture = preload("res://images/conflict.svg")
				status_icon.modulate = Color("DE5E09")
			IconStatus.EDIT:
				status_icon.texture = preload("res://images/modified.svg")
				status_icon.modulate = Color("344DED")
			IconStatus.UNTRACKED:
				status_icon.texture = preload("res://images/untracked.svg")
				status_icon.modulate = Color("9209B8")
			IconStatus.NONE:
				status_icon.texture = null
				
	status = new_status
		
func move(diff):
	position += diff
	write_to_file()
	if held:
		held.move(diff)
