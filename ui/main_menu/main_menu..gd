extends Node2D

@onready var btn_jugar: TextureButton = $UI/BtnJugar
@onready var btn_almanaque: Button = $UI/BtnAlmanaque
@onready var btn_salir: TextureButton = $UI/BtnSalir
@onready var btn_ajustes: Button = $UI/BtnAjustes
@onready var panel_ajustes: Panel = $UI/PanelAjustes
@onready var slider_musica: HSlider = $UI/PanelAjustes/SliderMusica
@onready var slider_sfx: HSlider = $UI/PanelAjustes/SliderSFX
@onready var btn_cerrar_ajustes: Button = $UI/PanelAjustes/BtnCerrar

func _ready() -> void:
	AudioManager.cambiar_musica("main_menu")
	btn_jugar.pressed.connect(_on_jugar)
	btn_almanaque.pressed.connect(_on_almanaque)
	btn_salir.pressed.connect(_on_salir)
	btn_ajustes.pressed.connect(_on_ajustes)
	btn_cerrar_ajustes.pressed.connect(func(): panel_ajustes.hide())
	slider_musica.value_changed.connect(func(v): ConfigManager.set_musica(v))
	slider_sfx.value_changed.connect(func(v): ConfigManager.set_sfx(v))
	panel_ajustes.hide()
	# Cargar valores guardados
	slider_musica.value = ConfigManager.volumen_musica
	slider_sfx.value = ConfigManager.volumen_sfx

func _on_jugar() -> void:
	AudioManager.play_sfx("boton")
	get_tree().change_scene_to_file("res://ui/level_select/level_select.tscn")

func _on_almanaque() -> void:
	AudioManager.play_sfx("boton")
	get_tree().change_scene_to_file("res://ui/almanac/almanac.tscn")

func _on_salir() -> void:
	AudioManager.play_sfx("boton")
	get_tree().quit()
	
func _on_ajustes() -> void:
	AudioManager.play_sfx("boton")
	panel_ajustes.visible = not panel_ajustes.visible
