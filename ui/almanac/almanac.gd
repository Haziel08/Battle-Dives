extends Node2D

@onready var btn_volver: Button = $UI/BtnVolver
@onready var tab_tecnicas: Button = $UI/TabTecnicas
@onready var tab_especialistas: Button = $UI/TabEspecialistas
@onready var tab_amenazas: Button = $UI/TabAmenazas
@onready var tab_eventos: Button = $UI/TabEventos
@onready var tab_hallazgos: Button = $UI/TabHallazgos

@onready var lista_container: VBoxContainer = $UI/ListaScroll/ListaContainer
@onready var detalle_color: ColorRect = $UI/DetallePanel/DetalleColor
@onready var detalle_nombre: Label = $UI/DetallePanel/DetalleNombre
@onready var detalle_stats: Label = $UI/DetallePanel/DetalleStats
@onready var detalle_info_real: Label = $UI/DetallePanel/DetalleInfoReal
@onready var detalle_curioso: Label = $UI/DetallePanel/DetalleCurioso

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

func _ready() -> void:
	btn_volver.pressed.connect(_on_volver)
	tab_tecnicas.pressed.connect(func(): _cambiar_categoria("tecnicas"))
	tab_especialistas.pressed.connect(func(): _cambiar_categoria("especialistas"))
	tab_amenazas.pressed.connect(func(): _cambiar_categoria("amenazas"))
	tab_eventos.pressed.connect(func(): _cambiar_categoria("eventos"))
	tab_hallazgos.pressed.connect(func(): _cambiar_categoria("hallazgos"))
	_cambiar_categoria("tecnicas")

func _on_volver() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")

func _cambiar_categoria(cat: String) -> void:
	for c in lista_container.get_children():
		c.queue_free()

	match cat:
		"tecnicas":
			for f in tecnicas:
				_agregar_item(f.nombre, func(): _mostrar_tecnica(f))
		"especialistas":
			for f in especialistas:
				_agregar_item(f.nombre, func(): _mostrar_especialista(f))
		"amenazas":
			for f in amenazas:
				_agregar_item(f.nombre, func(): _mostrar_amenaza(f))
		"eventos":
			for f in eventos:
				_agregar_item(f.nombre, func(): _mostrar_evento(f))
		"hallazgos":
			for i in GameState.niveles.size():
				var nivel = GameState.niveles[i]
				var descubierto = GameState.hallazgos_descubiertos[i]
				var nombre = nivel.nombre_hallazgo if descubierto else "??? (Nivel %d)" % (i + 1)
				var idx = i
				_agregar_item(nombre, func(): _mostrar_hallazgo(idx))

	_limpiar_detalle()

func _agregar_item(texto: String, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = texto
	btn.custom_minimum_size = Vector2(300, 50)
	btn.pressed.connect(callback)
	lista_container.add_child(btn)

func _limpiar_detalle() -> void:
	detalle_nombre.text = "Selecciona un elemento"
	detalle_stats.text = ""
	detalle_info_real.text = ""
	detalle_curioso.text = ""
	detalle_color.color = Color.DARK_GRAY

func _mostrar_tecnica(f: TechniqueData) -> void:
	detalle_color.color = f.color_debug
	detalle_nombre.text = f.nombre + " (Técnica)"
	detalle_stats.text = "En el juego:\nCosto: %d FI | HP: %d | Daño: %d\nVelocidad: %.0f | Vel. Ataque: %.1f/s\nContrarresta: %s (x%.1f)" \
		% [f.costo, f.hp, f.danio, f.velocidad, f.velocidad_ataque, ", ".join(PackedStringArray(f.efectivo_contra)), f.multiplicador_danio]
	detalle_info_real.text = "En la vida real:\n" + f.info_real
	detalle_curioso.text = "Dato curioso:\n" + f.descripcion_graciosa

func _mostrar_especialista(f: SpecialistData) -> void:
	detalle_color.color = f.color_debug
	detalle_nombre.text = f.nombre + " (Especialista)"
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

func _mostrar_amenaza(f: ThreatData) -> void:
	detalle_color.color = f.color_debug
	detalle_nombre.text = f.nombre + " (Amenaza)"
	detalle_stats.text = "En el juego:\nHP: %d | Velocidad: %.0f\nDaño Físico: %.0f | Daño Científico: %.0f\nDaño a Técnicas: %.0f" \
		% [f.hp, f.velocidad, f.danio_fisico, f.danio_cientifico, f.danio_a_tropas]
	if f.comportamiento == "roba_y_huye":
		detalle_stats.text += "\nRoba %.0f IC y huye" % f.ic_robado
	detalle_info_real.text = "En la vida real:\n" + f.info_real
	detalle_curioso.text = "Dato curioso:\n" + f.descripcion_graciosa

func _mostrar_evento(f: EventData) -> void:
	detalle_color.color = f.color_debug
	detalle_nombre.text = f.nombre + " (Evento)"
	detalle_stats.text = "En el juego:\nDuración: %.0fs" % f.duracion
	if f.oculta_pantalla: detalle_stats.text += "\nReduce visibilidad"
	if f.multiplica_velocidad_amenazas != 1.0: detalle_stats.text += "\nAmenazas x%.1f velocidad" % f.multiplica_velocidad_amenazas
	if f.danio_fisico_instantaneo > 0: detalle_stats.text += "\n-%.0f IF instantáneo" % f.danio_fisico_instantaneo
	if f.reduce_radio_deteccion_pct > 0: detalle_stats.text += "\n-%.0f%% radio detección" % (f.reduce_radio_deteccion_pct * 100)
	detalle_info_real.text = "En la vida real:\n" + f.info_real
	detalle_curioso.text = "Dato curioso:\n" + f.descripcion_graciosa

func _mostrar_hallazgo(indice: int) -> void:
	var nivel = GameState.niveles[indice]
	if not GameState.hallazgos_descubiertos[indice]:
		detalle_color.color = Color.DARK_GRAY
		detalle_nombre.text = "??? (Bloqueado)"
		detalle_stats.text = "Completa el Nivel %d para descubrir este hallazgo." % (indice + 1)
		detalle_info_real.text = ""
		detalle_curioso.text = ""
		return
	detalle_color.color = Color.GOLD
	detalle_nombre.text = nivel.nombre_hallazgo + " (Hallazgo)"
	detalle_stats.text = "En el juego:\nIntegridad Física: %.0f\nIntegridad Científica: %.0f" % [nivel.hallazgo_if, nivel.hallazgo_ic]
	detalle_info_real.text = "En la vida real:\n" + nivel.hallazgo_info_real
	detalle_curioso.text = "Dato curioso:\n" + nivel.hallazgo_descripcion_graciosa
