extends Node2D

@export var nombre_hallazgo: String = "Hallazgo"
@export var integridad_fisica: float = 1000.0
@export var integridad_cientifica: float = 200.0

var if_max: float
var ic_max: float
var ref_nivel = null

signal hallazgo_destruido
signal contexto_perdido
signal stats_actualizados(if_actual, if_max, ic_actual, ic_max)

func _ready() -> void:
	if_max = integridad_fisica
	ic_max = integridad_cientifica
	emit_signal("stats_actualizados", integridad_fisica, if_max, integridad_cientifica, ic_max)
	if has_node("HoverArea"):
		$HoverArea.mouse_entered.connect(_on_hover_enter)
		$HoverArea.mouse_exited.connect(_on_hover_exit)

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

func curar_fisico(cantidad: float) -> void:
	integridad_fisica = min(if_max, integridad_fisica + cantidad)
	emit_signal("stats_actualizados", integridad_fisica, if_max, integridad_cientifica, ic_max)

func curar_cientifico(cantidad: float) -> void:
	integridad_cientifica = min(ic_max, integridad_cientifica + cantidad)
	emit_signal("stats_actualizados", integridad_fisica, if_max, integridad_cientifica, ic_max)

func get_nombre() -> String:
	return nombre_hallazgo

func get_if_max() -> float:
	return if_max

func get_ic_max() -> float:
	return ic_max

func _on_hover_enter() -> void:
	if ref_nivel == null:
		return
	var texto = "%s\nIF: %.0f / %.0f\nIC: %.0f / %.0f" % [nombre_hallazgo, integridad_fisica, if_max, integridad_cientifica, ic_max]
	ref_nivel.mostrar_tooltip(texto, global_position + Vector2(40, -80))

func _on_hover_exit() -> void:
	if ref_nivel != null:
		ref_nivel.ocultar_tooltip()

func _draw() -> void:
	draw_rect(Rect2(-32, -32, 64, 64), Color.YELLOW)
