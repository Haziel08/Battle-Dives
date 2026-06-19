extends Node

# --- BUSES ---
# Asegúrate de tener en Project > Audio Buses: Master, Music, SFX

# --- MÚSICA ---
var music_player: AudioStreamPlayer
var musica_actual: String = ""

const MUSICA_POR_ESCENA: Dictionary = {
	"main_menu": "res://assets/audio/music/menu.ogg",
	"level_select": "res://assets/audio/music/menu.ogg",
	"nivel_1": "res://assets/audio/music/nivel_1.ogg",
	"nivel_2": "res://assets/audio/music/nivel_2.ogg",
	"nivel_3": "res://assets/audio/music/nivel_3.ogg",
	"nivel_4": "res://assets/audio/music/nivel_4.ogg",
	"nivel_5": "res://assets/audio/music/nivel_5.ogg",
}

# --- SFX ---
var sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE: int = 6
var sfx_index: int = 0

const SFX: Dictionary = {
	"seleccionar_carta": "res://assets/audio/sfx/seleccionar_carta.wav",
	"falta_fi": "res://assets/audio/sfx/falta_fi.wav",
	"abandono": "res://assets/audio/sfx/abandono.wav",
	"victoria": "res://assets/audio/sfx/victoria.wav",
	"derrota": "res://assets/audio/sfx/derrota.wav",
	"sismo": "res://assets/audio/sfx/sismo.wav",
	"huracan": "res://assets/audio/sfx/huracan.wav",
	"baja_visibilidad": "res://assets/audio/sfx/baja_visibilidad.wav",
	"corrientes_marinas": "res://assets/audio/sfx/corrientes_marinas.wav",
	"golpe_hallazgo": "res://assets/audio/sfx/golpe_hallazgo.wav",
	"boton": "res://assets/audio/sfx/boton.wav",
	"despliegue_especialista": "res://assets/audio/sfx/despliegue_especialista_dinero.wav",
	"despliegue_tecnica": "res://assets/audio/sfx/despliegue_tecnica_dinero.wav",
	"mejora_dinero": "res://assets/audio/sfx/mejora_dinero.wav",
}

func _ready() -> void:
	# Crear MusicPlayer
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	add_child(music_player)
	music_player.finished.connect(_on_musica_terminada)

	# Crear pool de SFX players
	for i in SFX_POOL_SIZE:
		var sp = AudioStreamPlayer.new()
		sp.bus = "SFX"
		add_child(sp)
		sfx_players.append(sp)

# ============================================================
# MÚSICA
# ============================================================

func _on_musica_terminada() -> void:
	music_player.play()

func cambiar_musica(clave: String) -> void:
	if clave == musica_actual:
		return
	if not MUSICA_POR_ESCENA.has(clave):
		return

	var ruta = MUSICA_POR_ESCENA[clave]
	if not ResourceLoader.exists(ruta):
		print("AudioManager: archivo no encontrado: ", ruta)
		return

	musica_actual = clave
	var stream = load(ruta)

	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamMP3:
		stream.loop = true

	music_player.stream = stream
	music_player.play()

func detener_musica() -> void:
	music_player.stop()
	musica_actual = ""

func set_volumen_musica(valor: float) -> void:
	var bus = AudioServer.get_bus_index("Music")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(max(valor, 0.001)))

func set_volumen_sfx(valor: float) -> void:
	var bus = AudioServer.get_bus_index("SFX")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(max(valor, 0.001)))

# ============================================================
# SFX
# ============================================================

func play_sfx(clave: String) -> void:
	if not SFX.has(clave):
		return
	var ruta = SFX[clave]
	if not ResourceLoader.exists(ruta):
		return

	var player = sfx_players[sfx_index]
	sfx_index = (sfx_index + 1) % SFX_POOL_SIZE
	player.stream = load(ruta)
	player.play()
