extends Node2D

@onready var btn_volver: TextureButton = $UI/BtnVolver
@onready var tab_tecnicas: Button = $UI/TabTecnicas
@onready var tab_especialistas: Button = $UI/TabEspecialistas
@onready var tab_amenazas: Button = $UI/TabAmenazas
@onready var tab_eventos: Button = $UI/TabEventos
@onready var tab_hallazgos: Button = $UI/TabHallazgos
@onready var tab_descubrimientos: Button = $UI/BtnTabDescubrimientos

@onready var lista_container: VBoxContainer = $UI/ListaScroll/ListaContainer
@onready var detalle_nombre: Label = $UI/DetallePanel/DetalleNombre
@onready var detalle_sprite: TextureRect = $UI/DetallePanel/DetalleSprite
@onready var detalle_stats: Label = $UI/DetallePanel/DetalleStats
@onready var detalle_info_real: Label = $UI/DetallePanel/DetalleInfoReal
@onready var detalle_curioso: Label = $UI/DetallePanel/DetalleCurioso
@onready var galeria_label: Label = $UI/DetallePanel/GaleriaLabel
@onready var galeria_container: HBoxContainer = $UI/DetallePanel/GaleriaScroll/GaleriaContainer
@onready var foto_overlay: Panel = $UI/FotoOverlay
@onready var foto_overlay_img: TextureRect = $UI/FotoOverlay/FotoImg

var tecnicas: Array[TechniqueData] = [
	preload("res://entities/specialists/tec_espeleobuzo.tres"),
	preload("res://entities/specialists/tec_ingeniero.tres"),
	preload("res://entities/specialists/tec_cient_materiales.tres"),
	preload("res://entities/specialists/tec_vigilancia.tres"),
	preload("res://entities/specialists/tec_policia_maritima.tres"),
]

var especialistas: Array[SpecialistData] = [
	preload("res://entities/specialists/esp_arqueologo.tres"),
	preload("res://entities/specialists/esp_conservadore.tres"),
	preload("res://entities/specialists/esp_oceanografo.tres"),
	preload("res://entities/specialists/esp_fotogrametrista.tres"),
	preload("res://entities/specialists/esp_divulgador.tres"),
	preload("res://entities/specialists/esp_paleontologo.tres"),
]

var amenazas: Array[ThreatData] = [
	preload("res://entities/threats/sedimento.tres"),
	preload("res://entities/threats/contaminacion.tres"),
	preload("res://entities/threats/buceador.tres"),
	preload("res://entities/threats/saqueador.tres"),
]

var eventos: Array[EventData] = [
	preload("res://core/events/evento_huracan.tres"),
	preload("res://core/events/evento_sismo.tres"),
	preload("res://core/events/evento_baja_visibilidad.tres"),
	preload("res://core/events/evento_corrientes.tres"),
]

# ============================================================
# SETUP
# ============================================================

func _setup_hover_scale(btn: Button) -> void:
	btn.pivot_offset = Vector2(90, 35)
	btn.mouse_entered.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_CUBIC)
	)
	btn.mouse_exited.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_CUBIC)
	)

func _ready() -> void:
	foto_overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			foto_overlay.visible = false
	)

	AudioManager.cambiar_musica("main_menu")

	_setup_hover_scale(tab_tecnicas)
	_setup_hover_scale(tab_especialistas)
	_setup_hover_scale(tab_amenazas)
	_setup_hover_scale(tab_eventos)
	_setup_hover_scale(tab_hallazgos)

	btn_volver.pressed.connect(_on_volver)

	tab_tecnicas.pressed.connect(func():
		AudioManager.play_sfx("boton")
		_cambiar_categoria("tecnicas")
	)
	tab_especialistas.pressed.connect(func():
		AudioManager.play_sfx("boton")
		_cambiar_categoria("especialistas")
	)
	tab_amenazas.pressed.connect(func():
		AudioManager.play_sfx("boton")
		_cambiar_categoria("amenazas")
	)
	tab_eventos.pressed.connect(func():
		AudioManager.play_sfx("boton")
		_cambiar_categoria("eventos")
	)
	tab_hallazgos.pressed.connect(func():
		AudioManager.play_sfx("boton")
		_cambiar_categoria("hallazgos")
	)
	tab_descubrimientos.pressed.connect(func():
		AudioManager.play_sfx("boton")
		_cambiar_categoria("descubrimientos")
	)

	_cambiar_categoria("tecnicas")

func _on_volver() -> void:
	AudioManager.play_sfx("boton")
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")

# ============================================================
# IMAGEN — funciones centralizadas
# ============================================================

func _ocultar_imagen() -> void:
	detalle_sprite.texture = null
	detalle_sprite.hide()

func _mostrar_imagen(tex: Texture2D) -> void:
	if tex != null:
		detalle_sprite.texture = tex
		detalle_sprite.show()
	else:
		_ocultar_imagen()

func _cargar_sprite_detalle(sprite_path: String, hframes: int) -> void:
	if sprite_path == "":
		_ocultar_imagen()
		return
	var tex = load(sprite_path) as Texture2D
	if tex == null:
		_ocultar_imagen()
		return
	var src = tex.get_image()
	if src == null:
		_ocultar_imagen()
		return
	var frame_w = src.get_width() / hframes
	var cropped = src.get_region(Rect2i(0, 0, frame_w, src.get_height()))
	_mostrar_imagen(ImageTexture.create_from_image(cropped))

# ============================================================
# GALERÍA
# ============================================================

func _limpiar_galeria() -> void:
	for c in galeria_container.get_children():
		c.queue_free()
	galeria_label.visible = false

func _cargar_galeria(fotos: Array[String]) -> void:
	_limpiar_galeria()
	if fotos.is_empty():
		return
	galeria_label.text = "Galería:"
	galeria_label.visible = true
	for path in fotos:
		var tex := load(path) as Texture2D
		if tex == null:
			continue
		var rect := TextureRect.new()
		rect.texture = tex
		rect.custom_minimum_size = Vector2(110, 110)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var captured_tex := tex
		rect.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				foto_overlay_img.texture = captured_tex
				foto_overlay.visible = true
		)
		galeria_container.add_child(rect)

# ============================================================
# LISTA
# ============================================================

func _agregar_item(texto: String, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = texto
	btn.custom_minimum_size = Vector2(300, 50)
	btn.pressed.connect(func():
		AudioManager.play_sfx("boton")
		callback.call()
	)
	lista_container.add_child(btn)

# ============================================================
# DETALLE
# ============================================================

func _limpiar_detalle() -> void:
	detalle_nombre.text = "Selecciona un elemento"
	detalle_stats.text = ""
	detalle_info_real.text = ""
	detalle_curioso.text = ""
	_ocultar_imagen()
	_limpiar_galeria()

func _cambiar_categoria(cat: String) -> void:
	for c in lista_container.get_children():
		c.queue_free()
	_limpiar_detalle()

	match cat:
		"tecnicas":
			for f in tecnicas:
				var item = f
				_agregar_item(f.nombre, func(): _mostrar_tecnica(item))
			if tecnicas.size() > 0:
				_mostrar_tecnica(tecnicas[0])

		"especialistas":
			for f in especialistas:
				var item = f
				_agregar_item(f.nombre, func(): _mostrar_especialista(item))
			if especialistas.size() > 0:
				_mostrar_especialista(especialistas[0])

		"amenazas":
			for f in amenazas:
				var item = f
				_agregar_item(f.nombre, func(): _mostrar_amenaza(item))
			if amenazas.size() > 0:
				_mostrar_amenaza(amenazas[0])

		"eventos":
			for f in eventos:
				var item = f
				_agregar_item(f.nombre, func(): _mostrar_evento(item))
			if eventos.size() > 0:
				_mostrar_evento(eventos[0])

		"hallazgos":
			for i in GameState.niveles.size():
				var nivel = GameState.niveles[i]
				var descubierto = GameState.hallazgos_descubiertos[i]
				var nombre = nivel.nombre_hallazgo if descubierto else "??? (Nivel %d)" % (i + 1)
				var idx = i
				_agregar_item(nombre, func(): _mostrar_hallazgo(idx))
			if GameState.niveles.size() > 0:
				_mostrar_hallazgo(0)

		"descubrimientos":
			if GameState.entradas_desbloqueadas.is_empty():
				_agregar_item("(Ninguna entrada desbloqueada aún)", func(): _limpiar_detalle())
				return
			for entrada in GameState.entradas_desbloqueadas:
				var e = entrada
				_agregar_item(entrada.icono_categoria + " " + entrada.titulo, func(): _mostrar_entrada(e))
			# Mostrar la primera entrada automáticamente
			if not GameState.entradas_desbloqueadas.is_empty():
				_mostrar_entrada(GameState.entradas_desbloqueadas[0])

# ============================================================
# MOSTRAR POR TIPO
# ============================================================

func _mostrar_tecnica(f: TechniqueData) -> void:
	_limpiar_detalle()
	detalle_nombre.text = f.nombre + " (Técnica)"
	_cargar_sprite_detalle(f.spritesheet_path, f.spritesheet_hframes)
	detalle_stats.text = "En el juego:\nCosto: %d FI | HP: %d | Daño: %d\nVelocidad: %.0f | Vel. Ataque: %.1f/s\nContrarresta: %s (x%.1f)" \
		% [f.costo, f.hp, f.danio, f.velocidad, f.velocidad_ataque,
		   ", ".join(PackedStringArray(f.efectivo_contra)), f.multiplicador_danio]
	detalle_info_real.text = "En la vida real:\n" + f.info_real
	detalle_curioso.text = "Dato curioso:\n" + f.descripcion_graciosa
	_cargar_galeria(f.fotos_reales)

func _mostrar_especialista(f: SpecialistData) -> void:
	_limpiar_detalle()
	detalle_nombre.text = f.nombre + " (Especialista)"
	_cargar_sprite_detalle(f.spritesheet_path, f.spritesheet_hframes)
	var pasiva = ""
	if f.pasiva_ic_por_seg > 0: pasiva += "+%.1f IC/seg  " % f.pasiva_ic_por_seg
	if f.pasiva_if_por_seg > 0: pasiva += "+%.1f IF/seg  " % f.pasiva_if_por_seg
	if f.pasiva_fi_por_seg > 0: pasiva += "+%.1f FI/seg  " % f.pasiva_fi_por_seg
	if f.pasiva_reduce_prob_evento > 0: pasiva += "-%.0f%% eventos  " % (f.pasiva_reduce_prob_evento * 100)
	if f.reduce_prob_amenaza_tipo != "": pasiva += "-%.0f%% %s  " % [f.reduce_prob_amenaza_pct * 100, f.reduce_prob_amenaza_tipo]
	detalle_stats.text = "En el juego:\nCosto: %d FI | Duración: %ds\nPasiva: %s\nActiva: %s (CD %ds)" \
		% [f.costo, int(f.duracion), pasiva, f.nombre_activa, int(f.cooldown_activa)]
	detalle_info_real.text = "En la vida real:\n" + f.info_real
	detalle_curioso.text = "Dato curioso:\n" + f.descripcion_graciosa
	_cargar_galeria(f.fotos_reales)

func _mostrar_amenaza(f: ThreatData) -> void:
	_limpiar_detalle()
	detalle_nombre.text = f.nombre + " (Amenaza)"
	_cargar_sprite_detalle(f.spritesheet_path, f.spritesheet_hframes)
	detalle_stats.text = "En el juego:\nHP: %d | Velocidad: %.0f\nDaño Físico: %.0f | Daño Científico: %.0f\nDaño a Técnicas: %.0f" \
		% [f.hp, f.velocidad, f.danio_fisico, f.danio_cientifico, f.danio_a_tropas]
	if f.comportamiento == "roba_y_huye":
		detalle_stats.text += "\nRoba %.0f IC y huye" % f.ic_robado
	detalle_info_real.text = "En la vida real:\n" + f.info_real
	detalle_curioso.text = "Dato curioso:\n" + f.descripcion_graciosa
	_cargar_galeria(f.fotos_reales)

func _mostrar_evento(f: EventData) -> void:
	_limpiar_detalle()
	detalle_nombre.text = f.nombre + " (Evento)"
	detalle_stats.text = "En el juego:\nDuración: %.0fs" % f.duracion
	if f.oculta_pantalla: detalle_stats.text += "\nReduce visibilidad"
	if f.multiplica_velocidad_amenazas != 1.0: detalle_stats.text += "\nAmenazas x%.1f velocidad" % f.multiplica_velocidad_amenazas
	if f.danio_fisico_instantaneo > 0: detalle_stats.text += "\n-%.0f IF instantáneo" % f.danio_fisico_instantaneo
	if f.reduce_radio_deteccion_pct > 0: detalle_stats.text += "\n-%.0f%% radio detección" % (f.reduce_radio_deteccion_pct * 100)
	detalle_info_real.text = "En la vida real:\n" + f.info_real
	detalle_curioso.text = "Dato curioso:\n" + f.descripcion_graciosa
	_cargar_galeria(f.fotos_reales)

func _mostrar_hallazgo(indice: int) -> void:
	_limpiar_detalle()
	var nivel = GameState.niveles[indice]
	if not GameState.hallazgos_descubiertos[indice]:
		detalle_nombre.text = "??? (Bloqueado)"
		detalle_stats.text = "Completa el Nivel %d para descubrir este hallazgo." % (indice + 1)
		detalle_info_real.text = ""
		detalle_curioso.text = ""
		return
	detalle_nombre.text = nivel.nombre_hallazgo + " (Hallazgo)"
	detalle_stats.text = "Sitio: Hoyo Negro, Tulum, Q. Roo\nIF: %.0f | IC: %.0f" % [nivel.hallazgo_if, nivel.hallazgo_ic]
	detalle_info_real.text = "En la vida real:\n" + nivel.hallazgo_info_real
	detalle_curioso.text = "Dato curioso:\n" + nivel.hallazgo_descripcion_graciosa
	if nivel.hallazgo_imagen != null:
		_mostrar_imagen(nivel.hallazgo_imagen)

func _mostrar_entrada(entrada: AlmanacEntryData) -> void:
	_limpiar_detalle()
	detalle_nombre.text = entrada.titulo
	detalle_stats.text = entrada.icono_categoria + " Descubrimiento desbloqueado"
	detalle_info_real.text = entrada.contenido
	detalle_curioso.text = ""
	if entrada.imagen != null:
		_mostrar_imagen(entrada.imagen)
