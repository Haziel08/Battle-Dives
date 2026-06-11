extends Node2D

# --- CONFIGURACIÓN DEL NIVEL (arrastra el .tres aquí) ---
@export var nivel_actual: LevelData

# --- ESCENAS BASE ---
var especialista_scene = preload("res://entities/entity_base.tscn")
var threat_scene = preload("res://entities/threats/threat_base.tscn")

# --- ECONOMÍA (se llenan desde nivel_actual) ---
var fondo_investigacion: float = 100.0
const FI_MAX: float = 500.0
var fi_pasivo_base: float = 5.0

# --- MEJORA DE FI PASIVO ---
var nivel_generacion: int = 1
const COSTO_MEJORA_BASE: float = 80.0
const INCREMENTO_FI_POR_NIVEL: float = 2.0
const MAX_NIVEL_GENERACION: int = 5

# --- REFERENCIAS ---
@onready var path: Path2D = $Path2D
@onready var label_fi: Label = $HUD/TopPanel/LabelFI
@onready var finding = $FindingZone/Finding
@onready var label_nombre: Label = $HUD/TopPanel/LabelNombre
@onready var barra_fisica: ProgressBar = $HUD/TopPanel/BarraFisica
@onready var label_if: Label = $HUD/TopPanel/LabelIF
@onready var barra_cientifica: ProgressBar = $HUD/TopPanel/BarraCientifica
@onready var label_ic: Label = $HUD/TopPanel/LabelIC
@onready var label_mensaje: Label = $HUD/LabelMensaje
@onready var bottom_bar = $HUD/BottomPanel
@onready var btn_mejora: Button = $HUD/BottomPanel/BtnMejoraFI

var botones: Array = []
var timer_fi: float = 0.0
var timer_oleada: float = 0.0
var indice_amenaza_actual: int = 0
var juego_activo: bool = true

func _ready() -> void:
	if nivel_actual == null:
		print("ERROR: No hay LevelData asignado a este nivel")
		return

	_cargar_configuracion()
	print("Path length: ", path.curve.get_baked_length())

	finding.hallazgo_destruido.connect(_on_hallazgo_destruido)
	finding.contexto_perdido.connect(_on_contexto_perdido)
	finding.stats_actualizados.connect(_on_stats_actualizados)

	barra_fisica.max_value = finding.get_if_max()
	barra_fisica.value = finding.get_if_max()
	barra_cientifica.max_value = finding.get_ic_max()
	barra_cientifica.value = finding.get_ic_max()
	label_nombre.text = finding.get_nombre()
	label_mensaje.text = ""

	_setup_botones()
	btn_mejora.pressed.connect(_on_mejora_pressed)
	_actualizar_btn_mejora()
	actualizar_hud()

func _cargar_configuracion() -> void:
	# Cargar datos del hallazgo
	finding.nombre_hallazgo = nivel_actual.nombre_hallazgo
	finding.integridad_fisica = nivel_actual.hallazgo_if
	finding.integridad_cientifica = nivel_actual.hallazgo_ic
	finding._ready()  # re-inicializar con los nuevos valores

	# Economía
	fondo_investigacion = nivel_actual.fi_inicial
	fi_pasivo_base = nivel_actual.fi_pasivo_base

func _setup_botones() -> void:
	botones = bottom_bar.get_children()
	var especialistas = nivel_actual.especialistas_disponibles

	var idx_boton = 0
	for i in botones.size():
		if botones[i] == btn_mejora:
			continue
		if idx_boton < especialistas.size():
			var ficha = especialistas[idx_boton]
			botones[i].text = "%s\n%d FI" % [ficha.nombre, ficha.costo]
			botones[i].show()
			var idx = idx_boton
			botones[i].pressed.connect(func(): desplegar(idx))
			idx_boton += 1
		else:
			botones[i].hide()

func _process(delta: float) -> void:
	if not juego_activo:
		return

	timer_fi += delta
	if timer_fi >= 1.0:
		timer_fi = 0.0
		var fi_pasivo = fi_pasivo_base + (nivel_generacion - 1) * INCREMENTO_FI_POR_NIVEL
		agregar_fi(fi_pasivo)

	if indice_amenaza_actual < nivel_actual.amenazas_oleada.size():
		timer_oleada += delta
		if timer_oleada >= nivel_actual.intervalo_oleada:
			timer_oleada = 0.0
			_spawnear_amenaza()
	if indice_amenaza_actual >= nivel_actual.amenazas_oleada.size() and _no_quedan_amenazas():
		_victoria()

	var especialistas = nivel_actual.especialistas_disponibles
	var idx_boton = 0
	for i in botones.size():
		if botones[i] == btn_mejora:
			continue
		if idx_boton < especialistas.size():
			botones[i].disabled = fondo_investigacion < especialistas[idx_boton].costo
			idx_boton += 1

	_actualizar_btn_mejora()
	if nivel_generacion < MAX_NIVEL_GENERACION:
		btn_mejora.disabled = fondo_investigacion < costo_mejora_actual()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or not juego_activo:
		return
	var num = event.keycode - KEY_0
	var especialistas = nivel_actual.especialistas_disponibles
	if num >= 1 and num <= especialistas.size():
		desplegar(num - 1)

func desplegar(indice: int) -> void:
	var especialistas = nivel_actual.especialistas_disponibles
	if indice >= especialistas.size():
		return
	var ficha = especialistas[indice]
	if fondo_investigacion < ficha.costo:
		return

	fondo_investigacion -= ficha.costo
	var tropa = especialista_scene.instantiate()
	path.add_child(tropa)
	tropa.inicializar(ficha, finding, self)
	# Spawn justo antes del hallazgo, con pequeño margen
	var path_length = path.curve.get_baked_length()
	var margen = 30.0
	tropa.progress = path_length - margen
	actualizar_hud()

func _spawnear_amenaza() -> void:
	var lista = nivel_actual.amenazas_oleada
	var ficha: ThreatData
	if nivel_actual.oleada_aleatoria:
		ficha = lista[randi() % lista.size()]
	else:
		ficha = lista[indice_amenaza_actual]

	var amenaza = threat_scene.instantiate()
	path.add_child(amenaza)
	amenaza.inicializar(ficha, finding)
	amenaza.progress = 0.0
	indice_amenaza_actual += 1

func costo_mejora_actual() -> float:
	return COSTO_MEJORA_BASE * nivel_generacion

func _on_mejora_pressed() -> void:
	var costo = costo_mejora_actual()
	if nivel_generacion >= MAX_NIVEL_GENERACION:
		return
	if fondo_investigacion < costo:
		return
	fondo_investigacion -= costo
	nivel_generacion += 1
	actualizar_hud()
	_actualizar_btn_mejora()

func _actualizar_btn_mejora() -> void:
	if nivel_generacion >= MAX_NIVEL_GENERACION:
		btn_mejora.text = "Generación\nMÁX"
		btn_mejora.disabled = true
	else:
		btn_mejora.text = "Mejorar Gen.\n%d FI" % costo_mejora_actual()

func agregar_fi(cantidad: float) -> void:
	fondo_investigacion = min(FI_MAX, fondo_investigacion + cantidad)
	actualizar_hud()

func actualizar_hud() -> void:
	label_fi.text = "FI: %d / %d" % [fondo_investigacion, FI_MAX]

func _on_stats_actualizados(if_actual, if_maximo, ic_actual, ic_maximo) -> void:
	barra_fisica.value = if_actual
	label_if.text = "IF: %d/%d" % [if_actual, if_maximo]
	barra_cientifica.value = ic_actual
	label_ic.text = "IC: %d/%d" % [ic_actual, ic_maximo]

func _on_hallazgo_destruido() -> void:
	juego_activo = false
	label_mensaje.text = "DERROTA\nEl hallazgo fue destruido"

func _on_contexto_perdido() -> void:
	juego_activo = false
	label_mensaje.text = "DERROTA\nEl contexto científico fue perdido"

func _victoria() -> void:
	juego_activo = false
	label_mensaje.text = "¡VICTORIA!\nHallazgo protegido"
	
func _no_quedan_amenazas() -> bool:
	for hijo in path.get_children():
		if hijo.has_method("recibir_danio_de_tropa"):
			return false
	return true
