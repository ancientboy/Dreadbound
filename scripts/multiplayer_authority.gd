class_name MultiplayerAuthority
extends RefCounted

const MAX_PLAYERS := 4
const COMMANDS := ["move", "interact", "attack", "choose", "extract", "claim_loot"]

var rooms := {}


func create_room(room_id: String, host_id: String, seed: int) -> Dictionary:
	if room_id.is_empty() or host_id.is_empty() or rooms.has(room_id):
		return {}
	rooms[room_id] = {
		"room_id": room_id,
		"seed": seed,
		"revision": 0,
		"players": {host_id: _player_state(host_id)},
		"processed_commands": {},
		"loot_claims": {},
		"event_log": [],
	}
	return snapshot(room_id)


func join_room(room_id: String, player_id: String) -> Dictionary:
	if not rooms.has(room_id) or player_id.is_empty():
		return {}
	var room: Dictionary = rooms[room_id]
	if not room.players.has(player_id) and room.players.size() >= MAX_PLAYERS:
		return {}
	if not room.players.has(player_id):
		room.players[player_id] = _player_state(player_id)
		room.revision = int(room.revision) + 1
	rooms[room_id] = room
	return {"reconnect_token": _reconnect_token(room_id, player_id), "snapshot": snapshot(room_id)}


func submit(room_id: String, player_id: String, command_id: String, sequence: int, command_type: String, payload := {}) -> Dictionary:
	if not rooms.has(room_id) or command_id.is_empty() or not COMMANDS.has(command_type):
		return {"accepted": false, "error": "invalid_command"}
	var room: Dictionary = rooms[room_id]
	if room.processed_commands.has(command_id):
		return {"accepted": true, "duplicate": true, "snapshot": snapshot(room_id)}
	if not room.players.has(player_id):
		return {"accepted": false, "error": "unknown_player"}
	var player: Dictionary = room.players[player_id]
	if sequence != int(player.last_sequence) + 1:
		return {"accepted": false, "error": "sequence_conflict", "expected": int(player.last_sequence) + 1}
	var result := _apply_command(room, player, command_type, payload)
	if not bool(result.get("accepted", false)):
		return result
	player.last_sequence = sequence
	room.players[player_id] = player
	room.processed_commands[command_id] = true
	room.revision = int(room.revision) + 1
	room.event_log.append({"revision": room.revision, "command_id": command_id, "player_id": player_id, "type": command_type, "result": result.get("result", {})})
	if room.event_log.size() > 128:
		room.event_log = room.event_log.slice(room.event_log.size() - 128)
	rooms[room_id] = room
	return {"accepted": true, "duplicate": false, "revision": room.revision, "result": result.get("result", {})}


func reconnect(room_id: String, player_id: String, token: String) -> Dictionary:
	if token != _reconnect_token(room_id, player_id):
		return {}
	if not rooms.has(room_id) or not rooms[room_id].players.has(player_id):
		return {}
	return snapshot(room_id)


func snapshot(room_id: String) -> Dictionary:
	if not rooms.has(room_id):
		return {}
	var room: Dictionary = rooms[room_id]
	return {
		"room_id": room_id,
		"seed": int(room.seed),
		"revision": int(room.revision),
		"players": room.players.duplicate(true),
		"loot_claims": room.loot_claims.duplicate(true),
		"event_log": room.event_log.duplicate(true),
	}


func _apply_command(room: Dictionary, player: Dictionary, command_type: String, payload: Variant) -> Dictionary:
	var data: Dictionary = payload if payload is Dictionary else {}
	match command_type:
		"move":
			player.position = {"x": clampf(float(data.get("x", 0.0)), -4096.0, 4096.0), "y": clampf(float(data.get("y", 0.0)), -4096.0, 4096.0)}
			return {"accepted": true, "result": {"position": player.position}}
		"attack":
			return {"accepted": true, "result": {"target_id": str(data.get("target_id", "")), "server_validated": true}}
		"interact", "choose", "extract":
			return {"accepted": true, "result": data.duplicate(true)}
		"claim_loot":
			var loot_id := str(data.get("loot_id", ""))
			if loot_id.is_empty() or room.loot_claims.has(loot_id):
				return {"accepted": false, "error": "loot_already_claimed"}
			room.loot_claims[loot_id] = str(player.player_id)
			return {"accepted": true, "result": {"loot_id": loot_id, "owner": str(player.player_id)}}
	return {"accepted": false, "error": "unsupported_command"}


func _player_state(player_id: String) -> Dictionary:
	return {"player_id": player_id, "last_sequence": 0, "position": {"x": 0.0, "y": 0.0}, "connected": true}


func _reconnect_token(room_id: String, player_id: String) -> String:
	return ("%s|%s|dreadbound-v1" % [room_id, player_id]).sha256_text()
