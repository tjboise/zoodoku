extends Node

var muted: bool = false

var _player: AudioStreamPlayer
var _current_path: String = ""

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = -8.0
	add_child(_player)

func play(ogg_path: String) -> void:
	if ogg_path == _current_path:
		return
	_current_path = ogg_path
	if not muted:
		_try_load(ogg_path)

func _try_load(ogg_path: String) -> void:
	var abs_path: String = ProjectSettings.globalize_path(ogg_path)
	if not FileAccess.file_exists(abs_path):
		return
	var stream: AudioStreamOggVorbis = AudioStreamOggVorbis.load_from_file(abs_path)
	if stream == null:
		return
	stream.loop = true
	_player.stream = stream
	_player.play()

func toggle_mute() -> void:
	muted = not muted
	if muted:
		_player.stop()
	else:
		_try_load(_current_path)
