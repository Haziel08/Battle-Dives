extends Node2D

@onready var botones_nivel: Array[TextureButton] = [
	$UI/BtnNivel1, $UI/BtnNivel2, $UI/BtnNivel3, $UI/BtnNivel4, $UI/BtnNivel5
]

@onready var btn_volver: TextureButton = $UI/BtnVolver

func _ready() -> void:
	for i in botones_nivel.size():
		var idx = i
		botones_nivel[i].pressed.connect(func(): _seleccionar(idx))
		var desbloqueado = GameState.niveles_desbloqueados[i]
		botones_nivel[i].disabled = not desbloqueado
		botones_nivel[i].get_node("Numero").visible = desbloqueado
		botones_nivel[i].get_node("Candado").visible = not desbloqueado
		if not desbloqueado:
			botones_nivel[i].modulate = Color(0.75, 0.75, 0.75, 1.0)

	btn_volver.pressed.connect(_on_volver)
	AudioManager.cambiar_musica("main_menu")


func _seleccionar(indice: int) -> void:
	AudioManager.play_sfx("boton")
	GameState.seleccionar_nivel(indice)
	get_tree().change_scene_to_file("res://levels/level_base/level_base.tscn")


func _on_volver() -> void:
	AudioManager.play_sfx("boton")
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")
