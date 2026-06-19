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

var cartas_volteadas: Dictionary = {}

# --- REFERENCIAS ---
@onready var path: Path2D = $Path2D
@onready var label_fi: Label = $HUD/TopPanel/LabelFI
@onready var label_tiempo: Label = $HUD/TopPanel/LabelTiempo
@onready var finding = $FindingZone/Finding
@onready var label_nombre: Label = $HUD/TopPanel/LabelNombre
@onready var barra_fisica: ProgressBar = $HUD/TopPanel/BarraFisica
@onready var barra_cientifica: ProgressBar = $HUD/TopPanel/BarraCientifica
@onready var label_mensaje: Label = $HUD/LabelMensaje
@onready var bottom_bar = $HUD/BottomPanel
@onready var contenedor_tecnicas = $HUD/BottomPanel/ContenedorTecnicas
@onready var contenedor_especialistas = $HUD/BottomPanel/ContenedorEspecialistas
@onready var btn_tab_tecnicas: Button = $HUD/BottomPanel/BtnTabTecnicas
@onready var btn_tab_especialistas: Button = $HUD/BottomPanel/BtnTabEspecialistas
@onready var btn_mejora: Button = $HUD/BottomPanel/BtnMejoraFI


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

@onready var panel_tutorial = $HUD/PanelTutorial
@onready var label_tutorial: Label = $HUD/PanelTutorial/LabelTexto
@onready var btn_tutorial_siguiente: Button = $HUD/PanelTutorial/BtnContinuar

@onready var overlay_evento: ColorRect = $HUD/OverlayEvento
@onready var label_evento: Label = $HUD/LabelEvento
@onready var fondo_layer: CanvasLayer = $FondoLayer

@onready var tooltip_panel: Panel = $HUD/TooltipPanel
@onready var tooltip_label: Label = $HUD/TooltipPanel/TooltipLabel

@onready var panel_extraccion: Panel = $HUD/PanelExtraccion
@onready var labels_pasos_extraccion: Array = [
	$HUD/PanelExtraccion/LabelPaso1, $HUD/PanelExtraccion/LabelPaso2,
	$HUD/PanelExtraccion/LabelPaso3, $HUD/PanelExtraccion/LabelPaso4,
	$HUD/PanelExtraccion/LabelPaso5
]
@onready var btn_autorizacion: Button = $HUD/PanelExtraccion/BtnAutorizacion
@onready var btn_capsula: Button = $HUD/PanelExtraccion/BtnCapsula
@onready var btn_extraer: Button = $HUD/PanelExtraccion/BtnExtraer
@onready var label_aviso: Label = $HUD/TopPanel/LabelAviso
@onready var btn_colapsar_extraccion: Button = $HUD/PanelExtraccion/BtnColapsar

var pasos_extraccion_completados: Array[bool] = []
var timer_aviso: float = 0.0

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

# --- EVENTOS ---
var evento_actual: EventData = null
var timer_evento_actual: float = 0.0
var timer_chequeo_evento: float = 0.0
const INTERVALO_CHEQUEO_EVENTO: float = 5.0  # revisa 1 vez por minuto

var modificador_radio_deteccion: float = 1.0
var modificador_velocidad_amenazas: float = 1.0

# --- SHAKE DE PANTALLA ---
var shake_timer: float = 0.0
var shake_intensidad: float = 6.0

var panel_extraccion_colapsado: bool = false

func _ready() -> void:
	if GameState.get_nivel_actual() != null:
		nivel_actual = GameState.get_nivel_actual()
	
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
	_setup_tutorial()
	tooltip_panel.hide()
	
	btn_tab_tecnicas.pressed.connect(func(): _cambiar_tab("tecnicas"))
	btn_tab_especialistas.pressed.connect(func(): _cambiar_tab("especialistas"))
	_cambiar_tab("tecnicas")  # inicia mostrando técnicas
	


	btn_mejora.pressed.connect(_on_mejora_pressed)
	_actualizar_btn_mejora()
	actualizar_hud()
	overlay_evento.hide()
	label_evento.text = ""
	
	label_aviso.hide()
	if nivel_actual.permite_extraccion:
		panel_extraccion.show()
		for p in nivel_actual.pasos_extraccion:
			pasos_extraccion_completados.append(false)
		btn_autorizacion.pressed.connect(_on_btn_autorizacion_pressed)
		btn_capsula.pressed.connect(_on_btn_capsula_pressed)
		btn_extraer.pressed.connect(_on_extraer_pressed)
		btn_colapsar_extraccion.pressed.connect(_on_colapsar_extraccion_pressed)
		_actualizar_panel_extraccion()
	else:
		panel_extraccion.hide()

func _cargar_configuracion() -> void:
	finding.nombre_hallazgo = nivel_actual.nombre_hallazgo
	finding.integridad_fisica = nivel_actual.hallazgo_if
	finding.integridad_cientifica = nivel_actual.hallazgo_ic
	finding.ref_nivel = self
	# Reinicializar sin llamar _ready() para evitar señales duplicadas
	finding.if_max = nivel_actual.hallazgo_if
	finding.ic_max = nivel_actual.hallazgo_ic

	fondo_investigacion = nivel_actual.fi_inicial
	fi_pasivo_base = nivel_actual.fi_pasivo_base

	# Resetear estado runtime de oleadas
	for ola in nivel_actual.oleadas:
		ola.spawneados = 0
		ola.timer_spawn = 0.0
		ola.iniciada = false
		
	var clave_musica = "nivel_%d" % (GameState.indice_nivel_actual + 1)
	AudioManager.cambiar_musica(clave_musica)

# ============================================================
# SETUP BOTONES
# ============================================================

func _setup_botones_tecnicas() -> void:
	botones_tecnicas = contenedor_tecnicas.get_children()
	var tecnicas = nivel_actual.tecnicas_disponibles

	var idx_boton = 0
	for i in botones_tecnicas.size():
		if idx_boton < tecnicas.size():
			var ficha = tecnicas[idx_boton]
			botones_tecnicas[i].text = "%s\n%d FI" % [ficha.nombre, ficha.costo]
			botones_tecnicas[i].show()
			var ficha_tt = ficha
			var btn_tt = botones_tecnicas[i]
			btn_tt.gui_input.connect(func(event): _input_tooltip_tecnica(event, ficha_tt, btn_tt))
			var idx = idx_boton
			botones_tecnicas[i].pressed.connect(func(): desplegar_tecnica(idx))
			idx_boton += 1
		else:
			botones_tecnicas[i].hide()

func _setup_botones_especialistas() -> void:
	botones_especialistas = contenedor_especialistas.get_children()
	var especialistas = nivel_actual.especialistas_disponibles

	for i in botones_especialistas.size():
		if i < especialistas.size():
			botones_especialistas[i].show()
			var ficha_tt = especialistas[i]
			var btn_tt = botones_especialistas[i]
			btn_tt.gui_input.connect(func(event): _input_tooltip_especialista(event, ficha_tt, btn_tt))
			_reconectar_boton_especialista(i)
		else:
			botones_especialistas[i].hide()

func _reconectar_boton_especialista(i: int) -> void:
	var btn = botones_especialistas[i]
	
	# Desconectar pressed
	for c in btn.pressed.get_connections():
		btn.pressed.disconnect(c["callable"])
	
	# Desconectar gui_input también (evita duplicados del flip)
	for c in btn.gui_input.get_connections():
		btn.gui_input.disconnect(c["callable"])

	var ficha = nivel_actual.especialistas_disponibles[i]
	
	# Reconectar gui_input para el flip
	var ficha_tt = ficha
	var btn_tt = btn
	btn.gui_input.connect(func(event): _input_tooltip_especialista(event, ficha_tt, btn_tt))

	# Reconectar pressed según estado
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
	if shake_timer > 0.0:
		shake_timer -= delta
		var offset = Vector2(randf_range(-shake_intensidad, shake_intensidad), randf_range(-shake_intensidad, shake_intensidad))
		position = offset
		fondo_layer.offset = offset
		if shake_timer <= 0.0:
			position = Vector2.ZERO
			fondo_layer.offset = Vector2.ZERO
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
	_procesar_eventos(delta)
	
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
	
	if timer_aviso > 0.0:
		timer_aviso -= delta
		if timer_aviso <= 0.0:
			label_aviso.hide()

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
		if not en_abandono:
			AudioManager.play_sfx("abandono")

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
		AudioManager.play_sfx("falta_fi")
		return

	fondo_investigacion -= ficha.costo
	AudioManager.play_sfx("despliegue_tecnica")
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
		AudioManager.play_sfx("falta_fi")
		return

	fondo_investigacion -= ficha.costo
	AudioManager.play_sfx("despliegue_especialista")
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
					botones_especialistas[i].text = "%s\nCD %.0fs" % [ficha.nombre_activa, (1.0-cd)*ficha.cooldown_activa]
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
	print("Intentando curar: '", efecto, "' | Evento actual: '", evento_actual.tipo if evento_actual else "ninguno", "'")
	if evento_actual != null and evento_actual.tipo == efecto:
		_terminar_evento()

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
	AudioManager.play_sfx("mejora_dinero")
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
	barra_cientifica.value = ic_actual


# ============================================================
# FIN DE JUEGO
# ============================================================

func _on_hallazgo_destruido() -> void:
	_terminar_juego("DERROTA\nEl hallazgo fue destruido", false)

func _on_contexto_perdido() -> void:
	_terminar_juego("DERROTA\nEl contexto científico fue perdido", false)

func _victoria() -> void:
	GameState.desbloquear_siguiente()
	GameState.marcar_hallazgo_descubierto(GameState.indice_nivel_actual)
	_terminar_juego("¡VICTORIA!\nHallazgo protegido", true)

func _terminar_juego(mensaje: String, gano: bool) -> void:
	if not juego_activo:
		return
	juego_activo = false

	# Detener música del nivel
	AudioManager.detener_musica()

	# Reproducir SFX de resultado
	if gano:
		AudioManager.play_sfx("victoria")
	else:
		AudioManager.play_sfx("derrota")

	label_resultado.text = mensaje
	btn_siguiente.visible = gano
	panel_fin.show()

	# Pausar el árbol después de un frame
	get_tree().paused = true

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
	for player in AudioManager.sfx_players:
		player.stop()
	get_tree().reload_current_scene()

func _on_siguiente_pressed() -> void:
	get_tree().paused = false
	for player in AudioManager.sfx_players:
		player.stop()
	if GameState.hay_siguiente_nivel():
		GameState.ir_a_siguiente_nivel()
		get_tree().change_scene_to_file("res://levels/level_base/level_base.tscn")
	else:
		get_tree().change_scene_to_file("res://ui/level_select/level_select.tscn")

func _on_salir_pressed() -> void:
	get_tree().paused = false
	for player in AudioManager.sfx_players:
		player.stop()
	get_tree().change_scene_to_file("res://ui/level_select/level_select.tscn")

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

	# Inicializar valores en 80%
	slider_musica.value = 0.8
	slider_sfx.value = 0.8
	AudioManager.set_volumen_musica(0.8)
	AudioManager.set_volumen_sfx(0.8)

	btn_pausa.process_mode = Node.PROCESS_MODE_ALWAYS
	panel_pausa.process_mode = Node.PROCESS_MODE_ALWAYS
	for hijo in panel_pausa.get_children():
		hijo.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_pausa_pressed() -> void:
	AudioManager.play_sfx("boton")
	if juego_activo and not tutorial_activo:
		get_tree().paused = true
		panel_pausa.show()

func _on_reanudar_pressed() -> void:
	AudioManager.play_sfx("boton")
	get_tree().paused = false
	panel_pausa.hide()

func _on_volumen_musica_changed(valor: float) -> void:
	AudioManager.set_volumen_musica(valor)

func _on_volumen_sfx_changed(valor: float) -> void:
	AudioManager.set_volumen_sfx(valor)

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
	print("Setup tutorial. es_tutorial=", nivel_actual.es_tutorial, " pasos=", nivel_actual.pasos_tutorial.size())
	panel_tutorial.hide()
	btn_tutorial_siguiente.pressed.connect(_tutorial_siguiente_paso)

	if nivel_actual.es_tutorial and nivel_actual.pasos_tutorial.size() > 0:
		tutorial_activo = true
		paso_tutorial_actual = -1
		print("Tutorial activado, llamando primer paso")
		_tutorial_siguiente_paso()

func _tutorial_siguiente_paso() -> void:
	paso_tutorial_actual += 1
	print("Paso tutorial: ", paso_tutorial_actual, " / ", nivel_actual.pasos_tutorial.size())
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
		
# ============================================================
# EVENTOS ALEATORIOS
# ============================================================

func _procesar_eventos(delta: float) -> void:
	if evento_actual != null:
		timer_evento_actual += delta
		if timer_evento_actual >= evento_actual.duracion:
			_terminar_evento()
		return

	timer_chequeo_evento += delta
	if timer_chequeo_evento >= INTERVALO_CHEQUEO_EVENTO:
		timer_chequeo_evento = 0.0
		_intentar_lanzar_evento()

func _intentar_lanzar_evento() -> void:
	if nivel_actual.eventos_posibles.is_empty():
		return

	var prob = nivel_actual.prob_evento_por_minuto

	# Reducción por especialistas activos (ej. Oceanógrafo)
	for esp in especialistas_activos:
		if is_instance_valid(esp) and esp.datos.pasiva_reduce_prob_evento > 0.0:
			prob *= (1.0 - esp.datos.pasiva_reduce_prob_evento)

	if randf() > prob:
		return  # no ocurre evento esta vez

	var evento = nivel_actual.eventos_posibles[randi() % nivel_actual.eventos_posibles.size()]
	_iniciar_evento(evento)

func _iniciar_evento(evento: EventData) -> void:
	evento_actual = evento
	timer_evento_actual = 0.0
	efectos_activos[evento.tipo] = true
	
	match evento.tipo:
		"sismo":
			AudioManager.play_sfx("sismo")
		"inestabilidad", "huracan":
			AudioManager.play_sfx("huracan")
		"baja_visibilidad":
			AudioManager.play_sfx("baja_visibilidad")
		"corrientes_marinas":
			AudioManager.play_sfx("corrientes_marinas")
		"abandono":
			AudioManager.play_sfx("abandono")
		_:
			AudioManager.play_sfx("boton")

	if evento.oculta_pantalla:
		overlay_evento.show()
		var mat = overlay_evento.material as ShaderMaterial
		if mat:
			if evento.tipo == "baja_visibilidad":
				mat.set_shader_parameter("intensidad", 0.88)
				mat.set_shader_parameter("velocidad", 0.6)
				mat.set_shader_parameter("tinte_agua", Color(0.25, 0.22, 0.12, 1.0))
			elif evento.tipo == "huracan":
				mat.set_shader_parameter("intensidad", 0.75)
				mat.set_shader_parameter("velocidad", 2.5)
				mat.set_shader_parameter("tinte_agua", Color(0.08, 0.12, 0.22, 1.0))

	if evento.reduce_radio_deteccion_pct > 0.0:
		modificador_radio_deteccion = 1.0 - evento.reduce_radio_deteccion_pct

	if evento.multiplica_velocidad_amenazas != 1.0:
		modificador_velocidad_amenazas = evento.multiplica_velocidad_amenazas

	if evento.danio_fisico_instantaneo > 0.0:
		finding.recibir_danio_fisico(evento.danio_fisico_instantaneo)
		iniciar_shake(0.5, 8.0)

	label_evento.text = "⚠ " + evento.nombre

func _terminar_evento() -> void:
	if evento_actual != null:
		efectos_activos[evento_actual.tipo] = false

	evento_actual = null
	timer_evento_actual = 0.0
	overlay_evento.hide()
	modificador_radio_deteccion = 1.0
	modificador_velocidad_amenazas = 1.0
	label_evento.text = ""

func get_modificador_radio_deteccion() -> float:
	return modificador_radio_deteccion

func get_modificador_velocidad_amenazas() -> float:
	return modificador_velocidad_amenazas
	
func iniciar_shake(duracion: float = 0.5, intensidad: float = 6.0) -> void:
	shake_timer = duracion
	shake_intensidad = intensidad
	
func mostrar_tooltip(texto: String, posicion: Vector2) -> void:
	tooltip_label.text = texto
	# Evita que el tooltip se salga de la pantalla
	posicion.x = clamp(posicion.x, 10, 1152 - 290)
	posicion.y = clamp(posicion.y, 10, 648 - 160)
	tooltip_panel.position = posicion
	tooltip_panel.show()

func ocultar_tooltip() -> void:
	tooltip_panel.hide()
	
func _tooltip_tecnica(ficha: TechniqueData, btn: Button) -> void:
	var texto = "%s\nCosto: %d FI\n\nHP: %d   Daño: %d\nVelocidad: %.0f\nVel. Ataque: %.1f/s" \
		% [ficha.nombre, ficha.costo, ficha.hp, ficha.danio, ficha.velocidad, ficha.velocidad_ataque]
	if ficha.efectivo_contra.size() > 0:
		texto += "\n\nEfectivo contra:\n%s (x%.1f)" % [", ".join(ficha.efectivo_contra), ficha.multiplicador_danio]
	mostrar_tooltip(texto, btn.global_position + Vector2(0, -160))
	
func _tooltip_especialista(ficha: SpecialistData, btn: Button) -> void:
	var texto = "%s\nCosto: %d FI | Duración: %ds" % [ficha.nombre, ficha.costo, int(ficha.duracion)]

	if ficha.pasiva_ic_por_seg > 0:
		texto += "\n\nPasiva: +%.1f IC/seg" % ficha.pasiva_ic_por_seg
	if ficha.pasiva_if_por_seg > 0:
		texto += "\n\nPasiva: +%.1f IF/seg" % ficha.pasiva_if_por_seg
	if ficha.pasiva_reduce_prob_evento > 0:
		texto += "\n\nPasiva: -%.0f%% prob. eventos" % (ficha.pasiva_reduce_prob_evento * 100)
	if ficha.reduce_prob_amenaza_tipo != "":
		texto += "\n\nPasiva: -%.0f%% prob. %s" % [ficha.reduce_prob_amenaza_pct * 100, ficha.reduce_prob_amenaza_tipo]

	if ficha.tiene_activa:
		texto += "\n\nActiva: %s\n(Cooldown %ds)" % [ficha.nombre_activa, int(ficha.cooldown_activa)]

	mostrar_tooltip(texto, btn.global_position + Vector2(-300, 0))

# ============================================================
# PROTOCOLO DE EXTRACCIÓN
# ============================================================

func registrar_paso_extraccion(accion_id: String) -> void:
	if accion_id == "" or not nivel_actual.permite_extraccion:
		return
	var pasos = nivel_actual.pasos_extraccion
	for i in pasos.size():
		if pasos[i].accion_id == accion_id:
			_completar_paso(i)
			return

func _on_btn_autorizacion_pressed() -> void:
	AudioManager.play_sfx("boton")
	_intentar_paso_directo("autorizacion")

func _on_btn_capsula_pressed() -> void:
	AudioManager.play_sfx("boton")
	_intentar_paso_directo("capsula")

func _intentar_paso_directo(accion_id: String) -> void:
	var pasos = nivel_actual.pasos_extraccion
	for i in pasos.size():
		if pasos[i].accion_id == accion_id:
			if pasos_extraccion_completados[i]:
				return
			if i > 0 and not pasos_extraccion_completados[i - 1]:
				_mostrar_aviso("Completa el paso anterior primero")
				return
			if pasos[i].costo_fi > 0:
				if fondo_investigacion < pasos[i].costo_fi:
					_mostrar_aviso("FI insuficiente")
					return
				fondo_investigacion -= pasos[i].costo_fi
				actualizar_hud()
			_completar_paso(i)
			return

func _completar_paso(i: int) -> void:
	if pasos_extraccion_completados[i]:
		return
	if i > 0 and not pasos_extraccion_completados[i - 1]:
		_mostrar_aviso("Completa el paso anterior primero")
		return
	pasos_extraccion_completados[i] = true
	_actualizar_panel_extraccion()

func _actualizar_panel_extraccion() -> void:
	var pasos = nivel_actual.pasos_extraccion
	for i in pasos.size():
		var check = "✅" if pasos_extraccion_completados[i] else "⬜"
		labels_pasos_extraccion[i].text = "%s %s" % [check, pasos[i].nombre]

func _on_extraer_pressed() -> void:
	AudioManager.play_sfx("boton")
	var completo = true
	for c in pasos_extraccion_completados:
		if not c:
			completo = false
			break

	if completo:
		GameState.desbloquear_siguiente()
		GameState.marcar_hallazgo_descubierto(GameState.indice_nivel_actual)
		_terminar_juego("¡EXTRACCIÓN EXITOSA!\nEl hallazgo fue resguardado\nsiguiendo el protocolo completo", true)
	else:
		finding.recibir_danio_cientifico(nivel_actual.ic_penalizacion_extraccion)
		_mostrar_aviso("¡Protocolo incompleto! -%.0f IC" % nivel_actual.ic_penalizacion_extraccion)

func _mostrar_aviso(texto: String) -> void:
	label_aviso.text = texto
	label_aviso.show()
	timer_aviso = 2.5
	
func _on_colapsar_extraccion_pressed() -> void:
	AudioManager.play_sfx("boton")
	panel_extraccion_colapsado = not panel_extraccion_colapsado

	# Oculta todo excepto el título y el botón de colapsar
	var ocultar = panel_extraccion_colapsado

	for lbl in labels_pasos_extraccion:
		lbl.visible = not ocultar
	btn_autorizacion.visible = not ocultar
	btn_capsula.visible = not ocultar
	btn_extraer.visible = not ocultar

	if panel_extraccion_colapsado:
		btn_colapsar_extraccion.text = "+"
		panel_extraccion.custom_minimum_size = Vector2(320, 45)
		panel_extraccion.size = Vector2(320, 45)
	else:
		btn_colapsar_extraccion.text = "−"
		panel_extraccion.custom_minimum_size = Vector2(320, 360)
		panel_extraccion.size = Vector2(320, 360)

func _input_tooltip_tecnica(event: InputEvent, ficha: TechniqueData, btn: Button) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var volteada = cartas_volteadas.get(btn, false)
		cartas_volteadas[btn] = not volteada
		if cartas_volteadas[btn]:
			_mostrar_reverso_tecnica(ficha, btn)
		else:
			_mostrar_frente_tecnica(ficha, btn)

func _mostrar_frente_tecnica(ficha: TechniqueData, btn: Button) -> void:
	btn.text = "%s\n%d FI" % [ficha.nombre, ficha.costo]

func _mostrar_reverso_tecnica(ficha: TechniqueData, btn: Button) -> void:
	var contra = ", ".join(PackedStringArray(ficha.efectivo_contra)) if ficha.efectivo_contra.size() > 0 else "—"
	btn.text = "HP:%d DMG:%d\nVS: %s" % [int(ficha.hp), int(ficha.danio), contra]

func _input_tooltip_especialista(event: InputEvent, ficha: SpecialistData, btn: Button) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var volteada = cartas_volteadas.get(btn, false)
		cartas_volteadas[btn] = not volteada
		if cartas_volteadas[btn]:
			_mostrar_reverso_especialista(ficha, btn)
		else:
			_mostrar_frente_especialista(ficha, btn)

func _mostrar_frente_especialista(ficha: SpecialistData, btn: Button) -> void:
	btn.text = "%s\n%d FI" % [ficha.nombre, ficha.costo]

func _mostrar_reverso_especialista(ficha: SpecialistData, btn: Button) -> void:
	var pasiva = ""
	if ficha.pasiva_ic_por_seg > 0: pasiva = "+%.0fIC/s" % ficha.pasiva_ic_por_seg
	elif ficha.pasiva_if_por_seg > 0: pasiva = "+%.0fIF/s" % ficha.pasiva_if_por_seg
	elif ficha.pasiva_fi_por_seg > 0: pasiva = "+%.0fFI/s" % ficha.pasiva_fi_por_seg
	elif ficha.pasiva_reduce_prob_evento > 0: pasiva = "-%.0f%%eventos" % (ficha.pasiva_reduce_prob_evento*100)
	elif ficha.reduce_prob_amenaza_tipo != "": pasiva = "-%.0f%%%s" % [ficha.reduce_prob_amenaza_pct*100, ficha.reduce_prob_amenaza_tipo]
	btn.text = "%ds | %s\n%s" % [int(ficha.duracion), pasiva, ficha.nombre_activa if ficha.tiene_activa else "Sin activa"]
				
				
func _cambiar_tab(tab: String) -> void:
	contenedor_tecnicas.visible = (tab == "tecnicas")
	contenedor_especialistas.visible = (tab == "especialistas")
	# Resaltar tab activo
	btn_tab_tecnicas.modulate = Color.WHITE if tab == "tecnicas" else Color(0.6, 0.6, 0.6)
	btn_tab_especialistas.modulate = Color.WHITE if tab == "especialistas" else Color(0.6, 0.6, 0.6)
	
	
