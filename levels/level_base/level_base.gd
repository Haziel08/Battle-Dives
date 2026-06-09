extends Node2D

# --- ECONOMÍA ---
var fondo_investigacion: float = 100.0
const FI_MAX: float = 500.0
const FI_PASIVO_BASE: float = 5.0

# --- ESCENAS ---
var especialista_scene = preload("res://entities/entity_base.tscn")
var threat_scene = preload("res://entities/threats/threat_base.tscn")

# --- REFERENCIAS ---
@onready var path: Path2D = $Path2D
@onready var btn: Button = $HUD/BtnEspecialista
@onready var label_fi: Label = $HUD/LabelFI
@onready var finding = $FindingZone/Finding

# HUD del hallazgo
@onready var label_nombre: Label = $HUD/PanelHallazgo/LabelNombre
@onready var barra_fisica: ProgressBar = $HUD/PanelHallazgo/BarraFisica
@onready var label_if: Label = $HUD/PanelHallazgo/LabelIF
@onready var barra_cientifica: ProgressBar = $HUD/PanelHallazgo/BarraCientifica
@onready var label_ic: Label = $HUD/PanelHallazgo/LabelIC
@onready var label_mensaje: Label = $HUD/LabelMensaje

# --- TIMERS ---
var timer_fi: float = 0.0
var timer_oleada: float = 0.0
var intervalo_oleada: float = 3.0
var amenazas_restantes: int = 5

# --- ESTADO ---
var juego_activo: bool = true

func _ready() -> void:
	btn.pressed.connect(_on_btn_pressed)
	finding.hallazgo_destruido.connect(_on_hallazgo_destruido)
	finding.contexto_perdido.connect(_on_contexto_perdido)
	finding.stats_actualizados.connect(_on_stats_actualizados)

	# Inicializar barras con los valores del hallazgo
	barra_fisica.max_value = finding.get_if_max()
	barra_fisica.value = finding.get_if_max()
	barra_cientifica.max_value = finding.get_ic_max()
	barra_cientifica.value = finding.get_ic_max()
	label_nombre.text = finding.get_nombre()
	label_mensaje.text = ""

	actualizar_hud()

func _process(delta: float) -> void:
	if not juego_activo:
		return

	# FI pasivo
	timer_fi += delta
	if timer_fi >= 1.0:
		timer_fi = 0.0
		fondo_investigacion = min(FI_MAX, fondo_investigacion + FI_PASIVO_BASE)
		actualizar_hud()

	# Oleadas
	if amenazas_restantes > 0:
		timer_oleada += delta
		if timer_oleada >= intervalo_oleada:
			timer_oleada = 0.0
			_spawnear_amenaza()

	# Victoria: no quedan amenazas y ninguna está viva en el path
	if amenazas_restantes <= 0 and path.get_child_count() == 0:
		_victoria()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and juego_activo:
		if event.keycode == KEY_1:
			desplegar(50.0)

func _on_btn_pressed() -> void:
	desplegar(50.0)

func desplegar(costo: float) -> void:
	if fondo_investigacion >= costo:
		fondo_investigacion -= costo
		var tropa = especialista_scene.instantiate()
		path.add_child(tropa)
		tropa.progress_ratio = 1.0  # spawn al final, avanza hacia la izquierda
		actualizar_hud()
	else:
		print("FI insuficiente!")

func _spawnear_amenaza() -> void:
	var amenaza = threat_scene.instantiate()
	path.add_child(amenaza)
	amenaza.progress = 0.0
	amenaza.ref_hallazgo = finding
	amenazas_restantes -= 1
	print("Amenaza spawneada! Quedan: ", amenazas_restantes)

func actualizar_hud() -> void:
	label_fi.text = "FI: %d / %d" % [fondo_investigacion, FI_MAX]

func _on_stats_actualizados(if_actual, if_maximo, ic_actual, ic_maximo) -> void:
	barra_fisica.value = if_actual
	label_if.text = "Física: %d / %d" % [if_actual, if_maximo]
	barra_cientifica.value = ic_actual
	label_ic.text = "Científica: %d / %d" % [ic_actual, ic_maximo]

func _on_hallazgo_destruido() -> void:
	juego_activo = false
	label_mensaje.text = "DERROTA\nEl hallazgo fue destruido"
	print("=== DERROTA: Integridad Física perdida ===")

func _on_contexto_perdido() -> void:
	juego_activo = false
	label_mensaje.text = "DERROTA\nEl contexto científico fue perdido"
	print("=== DERROTA: Integridad Científica perdida ===")

func _victoria() -> void:
	juego_activo = false
	label_mensaje.text = "¡VICTORIA!\nHallazgo protegido"
	print("=== VICTORIA ===")
