extends "res://common/game/Game.gd"

var unreadyPlayers := {}

func _init():
	self.connect("spawn_flag", self, "handle_spawn_flag")

func _ready():
	ClientNetwork.connect("remove_player", self, "remove_player")
	self.connect("spawn_projectile", self, "set_projectile_connection")
	$Level.connect("flag_picked_up", self, "flag_picked_up")
	for playerId in GameData.players:
		unreadyPlayers[playerId] = playerId
	for playerId in self.players:
		var player = self.players[playerId]
		player.connect("take_damage", self, "damage_taken")
		player.connect("weapon_auto_attack", self, "weapon_auto_attack", [ player ])
		player.connect("flag_captured", self, "player_captured_flag", [ playerId ])

remote func on_client_ready(playerId):
	print("client ready: %s" % playerId)
	unreadyPlayers.erase(playerId)
	print("Still waiting on %d players" % unreadyPlayers.size())
	
	# All clients are done, unpause the game
	if unreadyPlayers.empty():
		print("Starting the game")
		rpc("on_pre_configure_complete")


func remove_player(playerId: int):
	# If all players are gone, return to lobby
	if GameData.players.empty():
		print("All players disconnected, returning to lobby")
		get_tree().change_scene("res://server/lobby/ServerLobby.tscn")
	else:
		print("Players remaining: %d" % GameData.players.size())

func _physics_process(delta):
	var arr = []
	for playerId in self.players:
		var player = self.players[playerId]
		arr.append({position = player.position, id = player.id, lookDirection = player.server_direction})
	rpc_unreliable("update_player_position", arr)

func get_player_scene():
	return load("res://server/game/ServerPlayer.tscn")

func handle_spawn_flag(flag):
	print("handling spawn flag")
	flag.connect("flag_picked_up", self, "flag_picked_up")

func flag_picked_up(flag : Node2D, player : Node2D):
	print("telling clients, flag was picked up")
	rpc("on_flag_picked_up", flag.teamIndex, player.id)
	print("ServerGame: Flag ID: " + str(flag.teamIndex) + " PlayerId: " + str(player.id))

func damage_taken(playerId: int, newHealth: int):
	rpc("on_take_damage", playerId, newHealth)

func weapon_auto_attack(player):
	#print("Player: weapon auto attack")
	var playerId = player.id
	var weapon = player.get_weapon()
	# spawn projectile or other attack logic
	var position = player.get_projectile_spawn_position()
	var direction = player.get_direction()
	rpc("on_spawn_projectile", position, direction, weapon.projectile, UUID.v4())

remote func single_attacked():
	var playerId = get_tree().get_rpc_sender_id()
	print("Got gun_fired from: " + str(playerId))
	var player = get_player(playerId)
	var weapon = player.get_weapon()
	if weapon == null:
		print("no weapon")
		return
	var position = player.get_projectile_spawn_position()
	var direction = player.get_direction()
	rpc("on_spawn_projectile", position, direction, weapon.projectile, UUID.v4())

remote func auto_attacked(start):
	var playerId = get_tree().get_rpc_sender_id()
	var player = get_player(playerId)
	#print("ServerGame: player auto_attacked: " + str(start))
	player.set_attacking(start)

func respawn_player(playerId: int):
	var player = get_player(playerId)
	var aliveTeams = check_if_game_over()

	if aliveTeams.size() < 2:
		rpc("end_game")
		end_game()

	if !check_if_flag_is_taken(player.teamIndex):
		rpc("on_respawn_player", playerId)
		print("respawn player")

func check_if_game_over():
	var aliveTeams = []


	print("########################################################################################################################")
	for team in GameData.teams:
		print(team)
		if !check_if_flag_is_taken(team.index):
			if team.players.size() != 0:
				aliveTeams.append(team.index)
		else:
			for player in team.players:
				var gamePlayer = get_player(player)
				if !gamePlayer.dead:
					aliveTeams.append(team.index)
					break

	for at in aliveTeams:
		print(str(at))
	print("########################################################################################################################")
	return aliveTeams

func set_projectile_connection(projectile: Node):
	projectile.connect("hit", self, "projectile_hit")

func projectile_hit(projectile: Node2D, collider: Node2D):
	var tag = collider.get_meta("tag")
	if tag == "player":
		collider.take_damage(projectile.damage)
	rpc("on_projectile_hit", projectile.id)

func player_captured_flag(playerId : int):
	print("got flag captured from player " + str(playerId))
	rpc("on_flag_captured", playerId)

func load_lobby():
	get_tree().change_scene("res://server/lobby/ServerLobby.tscn")