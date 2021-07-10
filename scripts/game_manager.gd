class_name GameManager
extends Node

export var freeze_time = 3.0

onready var blue_knight = $BlueKnight
onready var red_knight = $RedKnight

onready var network_manager = $NetworkManager

onready var blue_knight_score_label = $ScoreUI/HBoxContainer/BlueKnightScore
onready var red_knight_score_label = $ScoreUI/HBoxContainer/RedKnightScore
onready var lobby_ui = $LobbyUI
onready var score_ui = $ScoreUI

onready var blue_knight_spawn = $Level/KnightOneSpawn
onready var red_knight_spawn = $Level/KnightTwoSpawn

var blue_knight_score = 0
var red_knight_score = 0


func _ready():
	pass

func start_game():
	if not get_tree().is_network_server():
		return
	
	if not network_manager.network_ready:
		return
	
	blue_knight.assign_control(network_manager.blue_knight_id)
	red_knight.assign_control(network_manager.red_knight_id)
	
	blue_knight.connect("knight_died", self, "_on_BlueKnight_knight_died")
	red_knight.connect("knight_died", self, "_on_RedKnight_knight_died")
	
	rpc("hide_lobby_show_score")
	rpc("enable_knights")
	
remotesync func enable_knights():
	blue_knight.enable()
	red_knight.enable()

remotesync func disable_knights():
	blue_knight.disable()
	red_knight.disable()

remotesync func freeze_game():
	# called on server and client
	print("Freezing for %d seconds" % (freeze_time))
	yield(get_tree().create_timer(freeze_time), "timeout")

func reset_knights():
	blue_knight.position = blue_knight_spawn.position
	red_knight.position = red_knight_spawn.position
	blue_knight.reset()
	red_knight.reset()

func _on_BlueKnight_knight_died():
	# only called on the server
	rpc("end_round")
	rpc("increase_red_knight_score")

func _on_RedKnight_knight_died():
	# only called on the server
	rpc("end_round")
	rpc("increase_blue_knight_score")

remotesync func end_round():
	disable_knights()
	yield(freeze_game(), "completed")
	reset_knights()
	enable_knights()

remotesync func hide_lobby_show_score():
	lobby_ui.hide()
	score_ui.show()

remotesync func increase_blue_knight_score():
	blue_knight_score += 1
	blue_knight_score_label.text = str(blue_knight_score)
	print("INCREASING BLUE SCORE")

remotesync func increase_red_knight_score():
	red_knight_score += 1
	red_knight_score_label.text = str(red_knight_score)
	print("INCREASING RED SCORE")

func _on_StartButton_pressed():
	start_game()
