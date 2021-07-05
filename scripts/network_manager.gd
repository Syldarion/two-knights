extends Node

const DEFAULT_PORT = 9999

export(NodePath) var knight_one_path
export(NodePath) var knight_two_path

onready var knight_one = get_node(knight_one_path) as Knight
onready var knight_two = get_node(knight_two_path) as Knight

var network_peer = null
var player_states = {}

# Connect all functions

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func _player_connected(id):
	# Called on both clients and server when a peer connects.
	# DebugHud.emit_message("Player connected: {0}".format([id]))
	rpc_id(id, "register_player", player_states[network_peer.get_unique_id()])
	print("PLAYER CONNECTED: %d" % (id))

func _player_disconnected(id):
	player_states.erase(id) # Erase player from info.
	update_player_list()

func _connected_ok():
	pass # Only called on clients, not server. Will go unused; not useful here.

func _server_disconnected():
	pass # Server kicked us; show error and abort.

func _connected_fail():
	pass # Could not even connect to server; abort.

remote func register_player(state):
	# Get the id of the RPC sender.
	var id = get_tree().get_rpc_sender_id()
	# Store the info
	player_states[id] = state
	
	if state["knight_one"]:
		knight_one.assign_control(id)
		knight_two.assign_control(get_tree().get_network_unique_id())
	if state["knight_two"]:
		knight_one.assign_control(get_tree().get_network_unique_id())
		knight_two.assign_control(id)
	
	update_player_list()
	
	# Call function to update lobby UI here
	
func update_player_list():
#	var player_ids = ""
#	for key in player_states.keys():
#		player_ids += str(key) + "\n"
#	$HUD/PlayerList.text = player_ids
	pass
	
func host_game(port):
	enable_knights()
	network_peer = NetworkedMultiplayerENet.new()
	network_peer.create_server(DEFAULT_PORT, 2)
	update_player_list()
	get_tree().set_network_peer(network_peer)
	knight_one.assign_control(network_peer.get_unique_id())
	knight_one.position = get_parent().get_node("Level/KnightOneSpawn").position
	knight_one.connect("knight_died", self, "reset_game")
	knight_two.connect("knight_died", self, "reset_game")
		
	player_states[network_peer.get_unique_id()] = {"knight_one": true, "knight_two": false}

func join_game(ip, port):
	enable_knights()
	network_peer = NetworkedMultiplayerENet.new()
	network_peer.create_client(ip, DEFAULT_PORT)
	update_player_list()
	get_tree().set_network_peer(network_peer)
	knight_two.assign_control(network_peer.get_unique_id())
	knight_two.position = get_parent().get_node("Level/KnightTwoSpawn").position
	knight_one.connect("knight_died", self, "reset_game")
	knight_two.connect("knight_died", self, "reset_game")
	
	player_states[network_peer.get_unique_id()] = {"knight_one": false, "knight_two": true}

func reset_game():
	rpc("reset_knights")
	
remotesync func reset_knights():
	knight_one.position = get_parent().get_node("Level/KnightOneSpawn").position
	knight_two.position = get_parent().get_node("Level/KnightTwoSpawn").position
	knight_one.reset()
	knight_two.reset()

func enable_knights():
	knight_one.enable()
	knight_two.enable()

func _on_HostButton_pressed():
	get_parent().get_node("LobbyUI").hide()
	var ip_port = get_ip_port_from_input()
	host_game(ip_port[1])

func _on_JoinButton_pressed():
	get_parent().get_node("LobbyUI").hide()
	var ip_port = get_ip_port_from_input()
	join_game(ip_port[0], ip_port[1])

func get_ip_port_from_input():
	var text = get_parent().get_node("LobbyUI/VBoxContainer/AddressInput").text
	return text.split(":")
