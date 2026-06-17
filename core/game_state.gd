extends Node

# Lista de niveles del juego, en orden (índice 0 = Nivel 1)
var niveles: Array[LevelData] = []

var indice_nivel_actual: int = 0
var niveles_desbloqueados: Array[bool] = [true, false, false, false, false]

func _ready() -> void:
	var nivel1 = load("res://levels/nivel_1.tres")
	var nivel2 = load("res://levels/nivel_2.tres")
	var nivel3 = load("res://levels/nivel_3.tres")
	var nivel4 = load("res://levels/nivel_4.tres")
	var nivel5 = load("res://levels/nivel_5.tres")
	niveles = [nivel1, nivel2, nivel3, nivel4, nivel5]

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
		
var hallazgos_descubiertos: Array[bool] = [false, false, false, false, false]

func marcar_hallazgo_descubierto(indice: int) -> void:
	if indice >= 0 and indice < hallazgos_descubiertos.size():
		hallazgos_descubiertos[indice] = true
