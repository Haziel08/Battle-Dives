extends Node2D

var datos: SpecialistData = null
var ref_nivel = null
var ref_hallazgo = null

var timer_vida: float = 0.0
var timer_pasiva: float = 0.0
var timer_cooldown_activa: float = 0.0
var activa_disponible: bool = true

# Estado de "Estabilizar" (Conservador) - reduce el próximo daño
var escudo_fisico_pct: float = 0.0

# Estado de "Campaña de Concientización" (Educador)
var campania_activa: bool = false
var timer_campania: float = 0.0

func inicializar(ficha: SpecialistData, hallazgo, nivel) -> void:
	datos = ficha
	ref_hallazgo = hallazgo
	ref_nivel = nivel
	if datos.tiene_activa:
		timer_cooldown_activa = 0.0
		activa_disponible = true

func _process(delta: float) -> void:
	if datos == null:
		return

	# --- Tiempo de vida ---
	timer_vida += delta
	if timer_vida >= datos.duracion:
		queue_free()
		return

	# --- Pasiva: curación/generación constante ---
	if datos.pasiva_ic_por_seg > 0.0 or datos.pasiva_if_por_seg > 0.0 or datos.pasiva_fi_por_seg > 0.0:
		timer_pasiva += delta
		if datos.pasiva_fi_por_seg > 0.0 and ref_nivel != null:
			ref_nivel.agregar_fi(datos.pasiva_fi_por_seg)
		if timer_pasiva >= 1.0:
			timer_pasiva = 0.0
			if ref_hallazgo != null:
				if datos.pasiva_ic_por_seg > 0.0:
					ref_hallazgo.curar_cientifico(datos.pasiva_ic_por_seg)
				if datos.pasiva_if_por_seg > 0.0:
					ref_hallazgo.curar_fisico(datos.pasiva_if_por_seg)

	# --- Cooldown de activa ---
	if datos.tiene_activa and not activa_disponible:
		timer_cooldown_activa += delta
		if timer_cooldown_activa >= datos.cooldown_activa:
			activa_disponible = true

	# --- Duración del efecto "Campaña de Concientización" ---
	if campania_activa:
		timer_campania += delta
		if timer_campania >= datos.activa_duracion_efecto:
			campania_activa = false
			if ref_nivel != null:
				ref_nivel.quitar_efecto_campania(self)

func usar_activa() -> bool:
	print("Activa usada: ", datos.nombre_activa, " | activa_cura_efecto: '", datos.activa_cura_efecto, "'")
	if not datos.tiene_activa or not activa_disponible:
		return false

	activa_disponible = false
	timer_cooldown_activa = 0.0

	# Efectos instantáneos
	if datos.activa_ic_instantaneo > 0.0 and ref_hallazgo != null:
		ref_hallazgo.curar_cientifico(datos.activa_ic_instantaneo)

	if datos.activa_if_instantaneo > 0.0 and ref_hallazgo != null:
		ref_hallazgo.curar_fisico(datos.activa_if_instantaneo)
	

	# Escudo (Conservador "Estabilizar")
	if datos.activa_reduce_danio_pct > 0.0:
		escudo_fisico_pct = datos.activa_reduce_danio_pct
		if ref_nivel != null:
			ref_nivel.aplicar_escudo_hallazgo(datos.activa_reduce_danio_pct)

	# Curar efecto de nivel (Fotogrametrista "Escaneo 3D")
	if datos.activa_cura_efecto != "" and ref_nivel != null:
		ref_nivel.curar_efecto_nivel(datos.activa_cura_efecto)

	# Campaña de Concientización (Educador)
	if datos.activa_reduce_danio_amenaza_pct > 0.0 and ref_nivel != null:
		campania_activa = true
		timer_campania = 0.0
		ref_nivel.aplicar_efecto_campania(self, datos.activa_aplica_a_tipos, datos.activa_reduce_danio_amenaza_pct)
	
	if datos.accion_extraccion_id != "" and ref_nivel != null and ref_nivel.has_method("registrar_paso_extraccion"):
		ref_nivel.registrar_paso_extraccion(datos.accion_extraccion_id)
	
	if datos.activa_fi_instantaneo > 0.0 and ref_nivel != null:
		ref_nivel.agregar_fi(datos.activa_fi_instantaneo)

	return true

func get_porcentaje_cooldown() -> float:
	if not datos.tiene_activa:
		return 1.0
	if activa_disponible:
		return 1.0
	return timer_cooldown_activa / datos.cooldown_activa

func get_tiempo_restante() -> float:
	return datos.duracion - timer_vida
	
func _ready() -> void:
	if has_node("HoverArea"):
		$HoverArea.mouse_entered.connect(_on_hover_enter)
		$HoverArea.mouse_exited.connect(_on_hover_exit)

func _on_hover_enter() -> void:
	if ref_nivel == null or datos == null:
		return
	var texto = "%s\nActivo: %.0fs restantes" % [datos.nombre, get_tiempo_restante()]
	if datos.tiene_activa:
		var estado = "Listo" if activa_disponible else "En cooldown"
		texto += "\n%s: %s" % [datos.nombre_activa, estado]
	ref_nivel.mostrar_tooltip(texto, global_position + Vector2(20, -60))

func _on_hover_exit() -> void:
	if ref_nivel != null:
		ref_nivel.ocultar_tooltip()

func _draw() -> void:
	if datos == null:
		return
	draw_rect(Rect2(-16, -16, 32, 32), datos.color_debug)
