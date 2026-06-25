extends Node

const RUTA_CONFIG = "user://config.cfg"

var volumen_musica: float = 0.8
var volumen_sfx: float = 0.8

func _ready() -> void:
	cargar()
	_aplicar()

func guardar() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "musica", volumen_musica)
	config.set_value("audio", "sfx", volumen_sfx)
	config.save(RUTA_CONFIG)

func cargar() -> void:
	var config = ConfigFile.new()
	if config.load(RUTA_CONFIG) != OK:
		return
	volumen_musica = config.get_value("audio", "musica", 0.8)
	volumen_sfx = config.get_value("audio", "sfx", 0.8)

func set_musica(valor: float) -> void:
	volumen_musica = valor
	AudioManager.set_volumen_musica(valor)
	guardar()

func set_sfx(valor: float) -> void:
	volumen_sfx = valor
	AudioManager.set_volumen_sfx(valor)
	guardar()

func _aplicar() -> void:
	AudioManager.set_volumen_musica(volumen_musica)
	AudioManager.set_volumen_sfx(volumen_sfx)
