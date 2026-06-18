extends Node2D

@onready var botones_nivel: Array = [
	$UI/BtnNivel1, $UI/BtnNivel2, $UI/BtnNivel3, $UI/BtnNivel4, $UI/BtnNivel5
]
@onready var btn_volver: Button = $UI/BtnVolver

func _ready() -> void:
	for i in botones_nivel.size():
		var idx = i
		botones_nivel[i].pressed.connect(func(): _seleccionar(idx))
		var desbloqueado = GameState.niveles_desbloqueados[i]
		botones_nivel[i].disabled = not desbloqueado
		if desbloqueado:
			botones_nivel[i].text = "Nivel %d" % (i + 1)
		else:
			botones_nivel[i].text = "🔒 Nivel %d" % (i + 1)

	btn_volver.pressed.connect(_on_volver)
	AudioManager.cambiar_musica("level_select")

func _seleccionar(indice: int) -> void:
	GameState.seleccionar_nivel(indice)
	get_tree().change_scene_to_file("res://levels/level_base/level_base.tscn")

func _on_volver() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")
