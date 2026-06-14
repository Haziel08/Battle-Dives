extends Node2D

@export var nivel_actual: LevelData

# --- ESCENAS ---
var technique_scene = preload("res://entities/entity_base.tscn")  # técnicas (combate)
var threat_scene = preload("res://entities/threats/threat_base.tscn")
var specialist_scene = preload("res://entities/specialists/specialist_base.tscn")  # nuevo

# --- ECONOMÍA ---
var fondo_investigacion: float = 100.0
const FI_MAX: float = 500.0
var fi_pasivo_base: float = 5.0

var nivel_generacion: int = 1
const COSTO_MEJORA_BASE: float = 80.0
const INCREMENTO_FI_POR_NIVEL: float = 2.0
const MAX_NIVEL_GENERACION: int = 5

# --- ABANDONO ---
const FI_UMBRAL_ABANDONO: float = 100.0
const DANIO_IC_ABANDONO: float = 1.0
var timer_abandono: float = 0.0
var en_abandono: bool = false

# --- TIEMPO DE NIVEL ---
var tiempo_transcurrido: float = 0.0

# --- ESCUDO TEMPORAL (Conservador) ---
var escudo_fisico_pct: float = 0.0

# --- CAMPAÑA DE CONCIENTIZACIÓN (Educador) ---
var campania_tipos: Array[String] = []
var campania_reduccion: float = 0.0

# --- EFECTOS DE NIVEL (Bloque D) ---
var efectos_activos: Dictionary = {}  # "baja_visibilidad" -> true/false
var timer_erosion: float = 0.0

# --- REFERENCIAS ---
@onready var path: Path2D = $Path2D
@onready var label_fi: Label = $HUD/TopPanel/LabelFI
@onready var label_tiempo: Label = $HUD/TopPanel/LabelTiempo
@onready var finding = $FindingZone/Finding
@onready var label_nombre: Label = $HUD/TopPanel/LabelNombre
@onready var barra_fisica: ProgressBar = $HUD/TopPanel/BarraFisica
@onready var label_if: Label = $HUD/TopPanel/LabelIF
@onready var barra_cientifica: ProgressBar = $HUD/TopPanel/BarraCientifica
@onready var label_ic: Label = $HUD/TopPanel/LabelIC
@onready var label_mensaje: Label = $HUD/LabelMensaje
@onready var bottom_bar = $HUD/BottomPanel
@onready var btn_mejora: Button = $HUD/BottomPanel/BtnMejoraFI
@onready var side_panel = $HUD/SidePanel

@onready var panel_fin: Panel = $HUD/PanelFin
@onready var label_resultado: Label = $HUD/PanelFin/LabelResultado
@onready var btn_reintentar: Button = $HUD/PanelFin/BtnReintentar
@onready var btn_siguiente: Button = $HUD/PanelFin/BtnSiguiente
@onready var btn_salir: Button = $HUD/PanelFin/BtnSalir

@onready var btn_pausa: Button = $HUD/BtnPausa
@onready var panel_pausa: Panel = $HUD/PanelPausa
@onready var slider_musica: HSlider = $HUD/PanelPausa/SliderMusica
@onready var slider_sfx: HSlider = $HUD/PanelPausa/SliderSFX
@onready var btn_reanudar: Button = $HUD/PanelPausa/BtnReanudar
@onready var btn_salir_pausa: Button = $HUD/PanelPausa/BtnSalirPausa

@onready var panel_tutorial: Panel = $HUD/PanelTutorial
@onready var label_tutorial: Label = $HUD/PanelTutorial/LabelTexto
@onready var btn_tutorial_siguiente: Button = $HUD/PanelTutorial/BtnContinuar

# --- BOTONES ---
var botones_tecnicas: Array = []
var botones_especialistas: Array = []
var especialistas_activos: Array = []  # instancias en pantalla

# --- TIMERS ---
var timer_fi: float = 0.0
var juego_activo: bool = true

# --- TUTORIAL ---
var tutorial_activo: bool = false
var paso_tutorial_actual: int = 0
var esperando_accion_tutorial: bool = false

func _ready() -> void:
	if nivel_actual == null:
		print("ERROR: No hay LevelData asignado")
		return

	_cargar_configuracion()

	finding.hallazgo_destruido.connect(_on_hallazgo_destruido)
	finding.contexto_perdido.connect(_on_contexto_perdido)
	finding.stats_actualizados.connect(_on_stats_actualizados)

	barra_fisica.max_value = finding.get_if_max()
	barra_fisica.value = finding.get_if_max()
	barra_cientifica.max_value = finding.get_ic_max()
	barra_cientifica.value = finding.get_ic_max()
	label_nombre.text = finding.get_nombre()
	label_mensaje.text = ""
	label_mensaje.hide()

	_setup_botones_tecnicas()
	_setup_botones_especialistas()
	_setup_panel_fin()
	_setup_panel_pausa()
	#_setup_tutorial()

	btn_mejora.pressed.connect(_on_mejora_pressed)
	_actualizar_btn_mejora()
	actualizar_hud()

func _cargar_configuracion() -> void:
	finding.nombre_hallazgo = nivel_actual.nombre_hallazgo
	finding.integridad_fisica = nivel_actual.hallazgo_if
	finding.integridad_cientifica = nivel_actual.hallazgo_ic
	finding._ready()

	fondo_investigacion = nivel_actual.fi_inicial
	fi_pasivo_base = nivel_actual.fi_pasivo_base

	# Resetear estado runtime de oleadas (por si se reinicia el nivel)
	for ola in nivel_actual.oleadas:
		ola.spawneados = 0
		ola.timer_spawn = 0.0
		ola.iniciada = false

# ============================================================
# SETUP BOTONES
# ============================================================

func _setup_botones_tecnicas() -> void:
	botones_tecnicas = bottom_bar.get_children()
	var tecnicas = nivel_actual.tecnicas_disponibles

	var idx_boton = 0
	for i in botones_tecnicas.size():
		if botones_tecnicas[i] == btn_mejora:
			continue
		if idx_boton < tecnicas.size():
			var ficha = tecnicas[idx_boton]
			botones_tecnicas[i].text = "%s\n%d FI" % [ficha.nombre, ficha.costo]
			botones_tecnicas[i].show()
			var idx = idx_boton
			botones_tecnicas[i].pressed.connect(func(): desplegar_tecnica(idx))
			idx_boton += 1
		else:
			botones_tecnicas[i].hide()

func _setup_botones_especialistas() -> void:
	botones_especialistas = side_panel.get_children()
	var especialistas = nivel_actual.especialistas_disponibles

	for i in botones_especialistas.size():
		if i < especialistas.size():
			botones_especialistas[i].show()
			_reconectar_boton_especialista(i)
		else:
			botones_especialistas[i].hide()

func _reconectar_boton_especialista(i: int) -> void:
	var btn = botones_especialistas[i]
	for c in btn.pressed.get_connections():
		btn.pressed.disconnect(c["callable"])

	var ficha = nivel_actual.especialistas_disponibles[i]
	var instancia_activa = null
	for esp in especialistas_activos:
		if esp.datos == ficha:
			instancia_activa = esp
			break

	if instancia_activa != null and ficha.tiene_activa:
		btn.pressed.connect(func(): instancia_activa.usar_activa())
	else:
		var idx = i
		btn.pressed.connect(func(): desplegar_especialista(idx))
		
# ============================================================
# PROCESS PRINCIPAL
# ============================================================

func _process(delta: float) -> void:
	if not juego_activo:
		return

	tiempo_transcurrido += delta
	_actualizar_label_tiempo()

	# --- FI pasivo ---
	timer_fi += delta
	if timer_fi >= 1.0:
		timer_fi = 0.0
		var fi_pasivo = fi_pasivo_base + (nivel_generacion - 1) * INCREMENTO_FI_POR_NIVEL
		agregar_fi(fi_pasivo)

	# --- Abandono ---
	_procesar_abandono(delta)
	
	# Erosión natural: el tiempo degrada la integridad física
	if nivel_actual.danio_if_por_tiempo > 0.0:
		timer_erosion += delta
		if timer_erosion >= 1.0:
			timer_erosion = 0.0
			finding.recibir_danio_fisico(nivel_actual.danio_if_por_tiempo)

	# --- Oleadas por tiempo ---
	if not _tutorial_esta_pausando_oleadas():
		_procesar_oleadas(delta)

	# --- Condición de victoria/derrota por tiempo ---
	_verificar_fin_de_nivel()

	# --- Actualizar botones ---
	_actualizar_botones_tecnicas()
	_actualizar_btn_mejora()
	if nivel_generacion < MAX_NIVEL_GENERACION:
		btn_mejora.disabled = fondo_investigacion < costo_mejora_actual()
	_actualizar_botones_especialistas()

# ============================================================
# OLEADAS POR TIEMPO
# ============================================================

func _procesar_oleadas(delta: float) -> void:
	for ola in nivel_actual.oleadas:
		if ola.spawneados >= ola.cantidad:
			continue

		if not ola.iniciada:
			if tiempo_transcurrido >= ola.tiempo_inicio:
				ola.iniciada = true
				ola.timer_spawn = ola.intervalo_spawn  # spawnea el primero de inmediato
			else:
				continue

		ola.timer_spawn += delta
		if ola.timer_spawn >= ola.intervalo_spawn:
			ola.timer_spawn = 0.0
			_spawnear_amenaza(ola.threat)
			ola.spawneados += 1

func _spawnear_amenaza(ficha: ThreatData) -> void:
	var amenaza = threat_scene.instantiate()
	path.add_child(amenaza)
	amenaza.inicializar(ficha, finding)
	amenaza.progress = 0.0
	amenaza.ref_nivel = self  # para campañas y escudos

# ============================================================
# ABANDONO
# ============================================================

func _procesar_abandono(delta: float) -> void:
	if fondo_investigacion < FI_UMBRAL_ABANDONO:
		en_abandono = true
		timer_abandono += delta
		if timer_abandono >= 1.0:
			timer_abandono = 0.0
			finding.recibir_danio_cientifico(DANIO_IC_ABANDONO)
	else:
		en_abandono = false
		timer_abandono = 0.0

# ============================================================
# FIN DE NIVEL (tiempo / condición)
# ============================================================

func _verificar_fin_de_nivel() -> void:
	if tiempo_transcurrido >= nivel_actual.duracion_nivel:
		# Tiempo agotado: revisar condición de victoria
		if finding.integridad_cientifica >= nivel_actual.ic_minima_para_ganar \
		and finding.integridad_fisica >= nivel_actual.if_minima_para_ganar:
			_victoria()
		else:
			_terminar_juego("DERROTA\nNo se mantuvo la integridad mínima\nrequerida al finalizar el tiempo", false)

func _actualizar_label_tiempo() -> void:
	var restante = max(0.0, nivel_actual.duracion_nivel - tiempo_transcurrido)
	var minutos = int(restante) / 60
	var segundos = int(restante) % 60
	label_tiempo.text = "%02d:%02d" % [minutos, segundos]
	if en_abandono:
		label_tiempo.text += "  [ABANDONO]"

# ============================================================
# DESPLIEGUE: TÉCNICAS (combate)
# ============================================================

func desplegar_tecnica(indice: int) -> void:
	if tutorial_activo and esperando_accion_tutorial:
		_tutorial_verificar_accion("tecnica_" + str(indice + 1))

	var tecnicas = nivel_actual.tecnicas_disponibles
	if indice >= tecnicas.size():
		return
	var ficha = tecnicas[indice]
	if fondo_investigacion < ficha.costo:
		return

	fondo_investigacion -= ficha.costo
	var tecnica = technique_scene.instantiate()
	path.add_child(tecnica)
	tecnica.inicializar(ficha, finding, self)

	var path_length = path.curve.get_baked_length()
	var margen = 30.0
	tecnica.progress = path_length - margen

	actualizar_hud()

func _actualizar_botones_tecnicas() -> void:
	var tecnicas = nivel_actual.tecnicas_disponibles
	var idx = 0
	for i in botones_tecnicas.size():
		if botones_tecnicas[i] == btn_mejora:
			continue
		if idx < tecnicas.size():
			botones_tecnicas[i].disabled = fondo_investigacion < tecnicas[idx].costo
			idx += 1

# ============================================================
# DESPLIEGUE: ESPECIALISTAS (habilidades)
# ============================================================

func desplegar_especialista(indice: int) -> void:
	if tutorial_activo and esperando_accion_tutorial:
		_tutorial_verificar_accion("especialista_" + str(indice + 1))

	var especialistas = nivel_actual.especialistas_disponibles
	if indice >= especialistas.size():
		return
	var ficha = especialistas[indice]
	if fondo_investigacion < ficha.costo:
		return

	fondo_investigacion -= ficha.costo
	var esp = specialist_scene.instantiate()
	# Se coloca cerca del hallazgo (offset pequeño para no superponerse exacto)
	esp.position = finding.position + Vector2(-40, especialistas_activos.size() * 20 - 20)
	$FindingZone.add_child(esp)
	esp.inicializar(ficha, finding, self)

	especialistas_activos.append(esp)

	# Reducción de probabilidad de amenaza (Educador)
	if ficha.reduce_prob_amenaza_tipo != "":
		_aplicar_reduccion_prob(ficha.reduce_prob_amenaza_tipo, ficha.reduce_prob_amenaza_pct)

	actualizar_hud()

func _actualizar_botones_especialistas() -> void:
	var especialistas = nivel_actual.especialistas_disponibles
	especialistas_activos = especialistas_activos.filter(func(e): return is_instance_valid(e))

	for i in botones_especialistas.size():
		if i >= especialistas.size():
			continue
		var ficha = especialistas[i]

		var instancia_activa = null
		for esp in especialistas_activos:
			if esp.datos == ficha:
				instancia_activa = esp
				break

		if instancia_activa != null:
			var restante = instancia_activa.get_tiempo_restante()
			if ficha.tiene_activa:
				var cd = instancia_activa.get_porcentaje_cooldown()
				if cd >= 1.0:
					botones_especialistas[i].text = "%s\n[%.0fs] LISTO" % [ficha.nombre_activa, restante]
					botones_especialistas[i].disabled = false
				else:
					botones_especialistas[i].text = "%s\nCD %.0fs (%.0fs)" % [ficha.nombre_activa, (1.0-cd)*ficha.cooldown_activa, restante]
					botones_especialistas[i].disabled = true
			else:
				botones_especialistas[i].text = "%s\nActivo (%.0fs)" % [ficha.nombre, restante]
				botones_especialistas[i].disabled = true
		else:
			botones_especialistas[i].text = "%s\n%d FI" % [ficha.nombre, ficha.costo]
			botones_especialistas[i].disabled = fondo_investigacion < ficha.costo

		_reconectar_boton_especialista(i)

# ============================================================
# EFECTOS GLOBALES (llamados por specialist_base.gd)
# ============================================================

func aplicar_escudo_hallazgo(porcentaje: float) -> void:
	escudo_fisico_pct = porcentaje
	print("Escudo aplicado: -", porcentaje * 100, "% próximo daño físico")

func curar_efecto_nivel(efecto: String) -> void:
	efectos_activos[efecto] = false
	print("Efecto curado: ", efecto)

func aplicar_efecto_campania(especialista, tipos: Array, porcentaje: float) -> void:
	campania_tipos = tipos
	campania_reduccion = porcentaje
	print("Campaña activa: -", porcentaje*100, "% daño de ", tipos)

func quitar_efecto_campania(especialista) -> void:
	campania_tipos = []
	campania_reduccion = 0.0
	print("Campaña terminada")

func _aplicar_reduccion_prob(tipo: String, pct: float) -> void:
	# Se usa en Bloque D (eventos) y para reducir spawn de saqueador.
	# Por ahora solo print; el efecto real se conecta cuando exista
	# el spawner de amenazas "aleatorias" además de las oleadas fijas.
	print("Reducción de probabilidad de '", tipo, "': -", pct*100, "%")

# Llamado por threat_base.gd antes de aplicar daño al hallazgo
func obtener_modificador_danio(tipo_amenaza: String) -> float:
	var mult = 1.0
	if escudo_fisico_pct > 0.0:
		mult *= (1.0 - escudo_fisico_pct)
		escudo_fisico_pct = 0.0  # se consume con un golpe
	if campania_tipos.has(tipo_amenaza):
		mult *= (1.0 - campania_reduccion)
	return mult

# ============================================================
# ECONOMÍA / MEJORA FI
# ============================================================

func costo_mejora_actual() -> float:
	return COSTO_MEJORA_BASE * nivel_generacion

func _on_mejora_pressed() -> void:
	if tutorial_activo and esperando_accion_tutorial:
		_tutorial_verificar_accion("click_mejora")

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

# ============================================================
# FIN DE JUEGO
# ============================================================

func _on_hallazgo_destruido() -> void:
	_terminar_juego("DERROTA\nEl hallazgo fue destruido", false)

func _on_contexto_perdido() -> void:
	_terminar_juego("DERROTA\nEl contexto científico fue perdido", false)

func _victoria() -> void:
	_terminar_juego("¡VICTORIA!\nHallazgo protegido", true)

func _terminar_juego(mensaje: String, gano: bool) -> void:
	if not juego_activo:
		return
	juego_activo = false
	get_tree().paused = true
	label_resultado.text = mensaje
	btn_siguiente.visible = gano
	panel_fin.show()

func _setup_panel_fin() -> void:
	panel_fin.hide()
	btn_reintentar.pressed.connect(_on_reintentar_pressed)
	btn_siguiente.pressed.connect(_on_siguiente_pressed)
	btn_salir.pressed.connect(_on_salir_pressed)

	panel_fin.process_mode = Node.PROCESS_MODE_ALWAYS
	btn_reintentar.process_mode = Node.PROCESS_MODE_ALWAYS
	btn_siguiente.process_mode = Node.PROCESS_MODE_ALWAYS
	btn_salir.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_reintentar_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_siguiente_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_salir_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

# ============================================================
# PAUSA
# ============================================================

func _setup_panel_pausa() -> void:
	panel_pausa.hide()
	btn_pausa.pressed.connect(_on_pausa_pressed)
	btn_reanudar.pressed.connect(_on_reanudar_pressed)
	btn_salir_pausa.pressed.connect(_on_salir_pressed)
	slider_musica.value_changed.connect(_on_volumen_musica_changed)
	slider_sfx.value_changed.connect(_on_volumen_sfx_changed)

	btn_pausa.process_mode = Node.PROCESS_MODE_ALWAYS
	panel_pausa.process_mode = Node.PROCESS_MODE_ALWAYS
	for hijo in panel_pausa.get_children():
		hijo.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_pausa_pressed() -> void:
	if juego_activo and not tutorial_activo:
		get_tree().paused = true
		panel_pausa.show()

func _on_reanudar_pressed() -> void:
	get_tree().paused = false
	panel_pausa.hide()

func _on_volumen_musica_changed(valor: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(max(valor, 0.001)))

func _on_volumen_sfx_changed(valor: float) -> void:
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(max(valor, 0.001)))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if panel_pausa.visible:
			_on_reanudar_pressed()
		elif juego_activo and not tutorial_activo:
			_on_pausa_pressed()
		return

	if not event is InputEventKey or not event.pressed or not juego_activo:
		return

	# Teclas 1-7: técnicas. Teclas Q,W,E,R,T: especialistas (ejemplo)
	var num = event.keycode - KEY_0
	if num >= 1 and num <= nivel_actual.tecnicas_disponibles.size():
		desplegar_tecnica(num - 1)

# ============================================================
# TUTORIAL
# ============================================================

func _setup_tutorial() -> void:
	panel_tutorial.hide()
	btn_tutorial_siguiente.pressed.connect(_tutorial_siguiente_paso)

	if nivel_actual.es_tutorial and nivel_actual.pasos_tutorial.size() > 0:
		tutorial_activo = true
		paso_tutorial_actual = -1
		_tutorial_siguiente_paso()

func _tutorial_siguiente_paso() -> void:
	paso_tutorial_actual += 1

	if paso_tutorial_actual >= nivel_actual.pasos_tutorial.size():
		tutorial_activo = false
		panel_tutorial.hide()
		return

	var paso: TutorialStep = nivel_actual.pasos_tutorial[paso_tutorial_actual]
	label_tutorial.text = paso.texto
	panel_tutorial.show()

	if paso.tipo == "solo_texto":
		btn_tutorial_siguiente.show()
		esperando_accion_tutorial = false
	else:
		btn_tutorial_siguiente.hide()
		esperando_accion_tutorial = true

func _tutorial_esta_pausando_oleadas() -> bool:
	if not tutorial_activo:
		return false
	if paso_tutorial_actual < 0 or paso_tutorial_actual >= nivel_actual.pasos_tutorial.size():
		return false
	return nivel_actual.pasos_tutorial[paso_tutorial_actual].pausar_oleadas

func _tutorial_verificar_accion(accion: String) -> void:
	if not tutorial_activo or not esperando_accion_tutorial:
		return
	var paso: TutorialStep = nivel_actual.pasos_tutorial[paso_tutorial_actual]
	if paso.accion_esperada == accion:
		_tutorial_siguiente_paso()
