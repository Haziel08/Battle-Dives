extends Node2D

var fondo_investigacion: float = 100.0
const FI_MAX: float = 500.0
const FI_PASIVO_BASE: float = 5.0

# --- MEJORA DE FI PASIVO ---
var nivel_generacion: int = 1
const COSTO_MEJORA_BASE: float = 80.0
const INCREMENTO_FI_POR_NIVEL: float = 2.0  # cada nivel suma +2 FI/s
const MAX_NIVEL_GENERACION: int = 5

var especialista_scene = preload("res://entities/entity_base.tscn")
var threat_scene = preload("res://entities/threats/threat_base.tscn")

@export var especialistas: Array[SpecialistData] = []
@export var amenazas_oleada: Array[ThreatData] = []
@export var intervalo_oleada: float = 3.0


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
	actualizar_hud()
	
	btn_mejora.pressed.connect(_on_mejora_pressed)
	_actualizar_btn_mejora()

func _setup_botones() -> void:
	botones.clear()
	
	for child in bottom_bar.get_children():
		if child is Button and child.name.begins_with("BtnSlot"):
			botones.append(child)
	
	print("Botones de especialista encontrados: ", botones.size())
	print("Especialistas cargados: ", especialistas.size())
	
	for i in botones.size():
		var boton: Button = botones[i]
		
		if i < especialistas.size():
			var ficha = especialistas[i]
			
			boton.text = "%s\n%d FI" % [ficha.nombre, ficha.costo]
			boton.show()
			
			var idx = i
			boton.pressed.connect(func(): desplegar(idx))
			
			print("Botón ", i + 1, " conectado a: ", ficha.nombre)
		else:
			boton.hide()
	
	# Asegurar que el botón de mejora siempre se vea
	btn_mejora.show()
	
func _process(delta: float) -> void:
	if not juego_activo:
		return

	# FI pasivo
	timer_fi += delta
	
	if timer_fi >= 1.0:
		timer_fi = 0.0
		var fi_pasivo = FI_PASIVO_BASE + (nivel_generacion - 1) * INCREMENTO_FI_POR_NIVEL
		agregar_fi(fi_pasivo)

	# Sistema de oleadas
	if indice_amenaza_actual < amenazas_oleada.size():
		timer_oleada += delta
		
		if timer_oleada >= intervalo_oleada:
			timer_oleada = 0.0
			_spawnear_amenaza()

	# Victoria
	if indice_amenaza_actual >= amenazas_oleada.size() and path.get_child_count() == 0:
		_victoria()

	# Actualizar estado visual de botones
	for i in botones.size():
		if i < especialistas.size():
			botones[i].disabled = fondo_investigacion < especialistas[i].costo
	
	_actualizar_btn_mejora()
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or not juego_activo:
		return
	var num = event.keycode - KEY_0
	if num >= 1 and num <= especialistas.size():
		desplegar(num - 1)

func desplegar(indice: int) -> void:
	if indice >= especialistas.size():
		return
	var ficha = especialistas[indice]
	if fondo_investigacion < ficha.costo:
		return

	fondo_investigacion -= ficha.costo
	var tropa = especialista_scene.instantiate()
	path.add_child(tropa)
	tropa.inicializar(ficha, finding, self)
	tropa.progress_ratio = 1.0
	actualizar_hud()

func _spawnear_amenaza() -> void:
	# Selección aleatoria de la lista de amenazas
	var indice_random = randi() % amenazas_oleada.size()
	var ficha = amenazas_oleada[indice_random]
	var amenaza = threat_scene.instantiate()
	path.add_child(amenaza)
	amenaza.inicializar(ficha, finding)
	amenaza.progress = 0.0
	indice_amenaza_actual += 1

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
