extends Node2D

@onready var btn_jugar: TextureButton = $UI/BtnJugar
@onready var btn_almanaque: Button = $UI/BtnAlmanaque
@onready var btn_salir: TextureButton = $UI/BtnSalir

func _ready() -> void:
	AudioManager.cambiar_musica("main_menu")
	btn_jugar.pressed.connect(_on_jugar)
	btn_almanaque.pressed.connect(_on_almanaque)
	btn_salir.pressed.connect(_on_salir)

func _on_jugar() -> void:
	AudioManager.play_sfx("boton")
	get_tree().change_scene_to_file("res://ui/level_select/level_select.tscn")

func _on_almanaque() -> void:
	AudioManager.play_sfx("boton")
	get_tree().change_scene_to_file("res://ui/almanac/almanac.tscn")

func _on_salir() -> void:
	AudioManager.play_sfx("boton")
	get_tree().quit()
