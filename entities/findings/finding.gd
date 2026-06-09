extends Node2D

@export var nombre_hallazgo: String = "Hallazgo"
@export var integridad_fisica: float = 1000.0
@export var integridad_cientifica: float = 200.0

var if_max: float
var ic_max: float

signal hallazgo_destruido
signal contexto_perdido
signal stats_actualizados(if_actual, if_max, ic_actual, ic_max)

func _ready() -> void:
	if_max = integridad_fisica
	ic_max = integridad_cientifica

func recibir_danio_fisico(cantidad: float) -> void:
	integridad_fisica = max(0.0, integridad_fisica - cantidad)
	emit_signal("stats_actualizados", integridad_fisica, if_max, integridad_cientifica, ic_max)
	if integridad_fisica <= 0.0:
		emit_signal("hallazgo_destruido")

func recibir_danio_cientifico(cantidad: float) -> void:
	integridad_cientifica = max(0.0, integridad_cientifica - cantidad)
	emit_signal("stats_actualizados", integridad_fisica, if_max, integridad_cientifica, ic_max)
	if integridad_cientifica <= 0.0:
		emit_signal("contexto_perdido")

func get_nombre() -> String:
	return nombre_hallazgo

func get_if_max() -> float:
	return if_max

func get_ic_max() -> float:
	return ic_max

func _draw() -> void:
	draw_rect(Rect2(-32, -32, 64, 64), Color.YELLOW)
