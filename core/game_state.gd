extends Node

# Lista de niveles del juego, en orden (índice 0 = Nivel 1)
var niveles: Array[LevelData] = []

var indice_nivel_actual: int = 0
var niveles_desbloqueados: Array[bool] = [true, false, false, false, false]

func _ready() -> void:
	# Carga los niveles disponibles.
	# Mientras no existan nivel_2..5, se repite nivel_1 como placeholder
	# para que la navegación no se rompa.
	var nivel1 = load("res://levels/level_base/nivel_1.tres")
	niveles = [nivel1, nivel1, nivel1, nivel1, nivel1]

func seleccionar_nivel(indice: int) -> void:
	if indice < 0 or indice >= niveles.size():
		return
	indice_nivel_actual = indice

func get_nivel_actual() -> LevelData:
	if indice_nivel_actual < niveles.size():
		return niveles[indice_nivel_actual]
	return null

func desbloquear_siguiente() -> void:
	var siguiente = indice_nivel_actual + 1
	if siguiente < niveles_desbloqueados.size():
		niveles_desbloqueados[siguiente] = true

func hay_siguiente_nivel() -> bool:
	return indice_nivel_actual + 1 < niveles.size()

func ir_a_siguiente_nivel() -> void:
	if hay_siguiente_nivel():
		indice_nivel_actual += 1
