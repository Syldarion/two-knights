extends Node

onready var label = $VBoxContainer/Label

func _ready():
	pass

func set_label(text):
	label.text = text
