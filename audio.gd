extends Node

var music_player: AudioStreamPlayer = null
var sound_effects_pool: Array = []
var max_sfx: int = 20  # Limit the pool size to avoid excessive players
var sfx_bus: int = AudioServer.get_bus_index("SFX")
var sfx_count: int = 0

# Music fade-out properties
var is_fading_out: bool = false
var fade_duration: float = 1.0
var fade_timer: float = 0.0
var start_volume: float = 0.0

func _ready():
	_ensure_initialized()

func _process(delta: float):
	# Count active SFX players from the pool
	_ensure_initialized()
	sfx_count = 0
	for player in sound_effects_pool:
		if player is AudioStreamPlayer and player.playing:
			sfx_count += 1
	# Handle fading out the music
	if is_fading_out:
		fade_timer += delta
		music_player.volume_db = lerp(start_volume, -80.0, fade_timer / fade_duration)
		if fade_timer >= fade_duration:
			is_fading_out = false
			music_player.stop()

func play_sound(stream: AudioStream, pitch_min: float = 1, pitch_max: float = 1):
	if stream == null:
		return
	_ensure_initialized()
	# Find an available player in the pool
	for player in sound_effects_pool:
		if player is AudioStreamPlayer and not player.playing:
			player.stream = stream
			player.pitch_scale = randf_range(pitch_min, pitch_max)
			player.volume_db = -3.0
			player.play()
			return

func stop_all_sound():
	for player: AudioStreamPlayer in sound_effects_pool:
		if player.playing:
			player.stop()
	stop_music()

## Music stuff ##
func play_music(stream: AudioStream):
	_ensure_initialized()
	if music_player.playing:
		music_player.stop()
	music_player.stream = stream
	music_player.volume_db = -6.0
	music_player.play()

func stop_music():
	if music_player and music_player.playing:
		music_player.stop()

func fade_out_music(duration: float = 1.0):
	if music_player and music_player.playing:
		is_fading_out = true
		fade_duration = duration
		fade_timer = 0.0
		start_volume = music_player.volume_db

func is_playing_music() -> bool:
	return music_player and music_player.playing


func _ensure_initialized() -> void:
	# Create music player and SFX pool if they haven't been created yet.
	if not music_player:
		music_player = AudioStreamPlayer.new()
		music_player.process_mode = Node.PROCESS_MODE_ALWAYS
		music_player.bus = "Music"
		add_child(music_player)
	if sound_effects_pool.is_empty():
		for i in range(max_sfx):
			var stream_player = AudioStreamPlayer.new()
			stream_player.bus = "SFX"
			add_child(stream_player)
			sound_effects_pool.append(stream_player)
