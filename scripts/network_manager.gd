class_name NetworkManager
extends Node

var network_peer = null
var connected_to_game = false
var network_ready = false

remotesync var red_knight_id = -1
remotesync var blue_knight_id = -1

# Connect all functions

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	NetworkStatusUI.set_label("Not connected")

func _player_connected(id):
	# this should be called on the server when our client connects
	# set our second player id and close off connections
	# probably not the right way to do this
	
	rset("red_knight_id", network_peer.get_unique_id())
	rset("blue_knight_id", id)
	
	print("PLAYER CONNECTED: %d" % (id))
	
	network_ready = true
	get_tree().refuse_new_network_connections = true

func _player_disconnected(id):
	# Should only have the one other player, sooooo
	# This should be fine
	
	rset("red_knight_id", network_peer.get_unique_id())
	rset("blue_knight_id", -1)
	network_ready = false
	get_tree().refuse_new_network_connections = false

func _connected_ok():
	connected_to_game = true
	NetworkStatusUI.set_label("Connected to game")

func _server_disconnected():
	pass

func _connected_fail():
	pass
	
func host_game(port):
	network_peer = NetworkedMultiplayerENet.new()
	network_peer.create_server(port, 2)
	get_tree().set_network_peer(network_peer)
	
	connected_to_game = true
	
	NetworkStatusUI.set_label("Hosting game on port %d" % (port))

func join_game(ip, port):
	network_peer = NetworkedMultiplayerENet.new()
	network_peer.create_client(ip, port)
	get_tree().set_network_peer(network_peer)

func _on_HostButton_pressed():
	var ip_port = get_ip_port_from_input()
	host_game(int(ip_port[1]))

func _on_JoinButton_pressed():
	var ip_port = get_ip_port_from_input()
	join_game(ip_port[0], int(ip_port[1]))

func get_ip_port_from_input():
	var text = get_parent().get_node("LobbyUI/VBoxContainer/AddressInput").text
	return text.split(":")
