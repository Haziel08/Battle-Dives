extends PathFollow2D

var datos: ThreatData = null
var hp_actual: float = 0.0
var ref_hallazgo = null
var ref_nivel = null
var esta_viva: bool = true
var objetivo_tropa = null
var en_combate: bool = false
var timer_ataque: float = 0.0
var timer_danio_continuo: float = 0.0
var offset_golpe: float = 0.0
var flash_danio: float = 0.0
var velocidad_actual: float = 0.0

# Estado: pegada al hallazgo (solo "avanza_y_pega")
var pegada_al_hallazgo: bool = false
const RADIO_HALLAZGO: float = 40.0
const INTERVALO_ATAQUE_HALLAZGO: float = 1.0

# Estado: roba y huye (Saqueador)
var robo_realizado: bool = false
var huyendo: bool = false

func inicializar(ficha: ThreatData, hallazgo) -> void:
	datos = ficha
	hp_actual = ficha.hp
	ref_hallazgo = hallazgo
	velocidad_actual = ficha.velocidad

func _process(delta: float) -> void:
	if not esta_viva or datos == null:
		return

	offset_golpe = lerp(offset_golpe, 0.0, delta * 10.0)
	flash_danio = lerp(flash_danio, 0.0, delta * 15.0)

	match datos.comportamiento:
		"roba_y_huye":
			_process_roba_y_huye(delta)
		_:
			_process_avanza_y_pega(delta)

# ============================================================
# COMPORTAMIENTO: avanza_y_pega (default)
# ============================================================

func _process_avanza_y_pega(delta: float) -> void:
	if pegada_al_hallazgo:
		timer_danio_continuo += delta
		if timer_danio_continuo >= INTERVALO_ATAQUE_HALLAZGO:
			timer_danio_continuo = 0.0
			_atacar_hallazgo()
		return

	if _combate_con_tecnica(delta):
		return

	progress += velocidad_actual * delta

	if ref_hallazgo != null:
		var dist = global_position.distance_to(ref_hallazgo.global_position)
		if dist < RADIO_HALLAZGO:
			pegada_al_hallazgo = true
			timer_danio_continuo = INTERVALO_ATAQUE_HALLAZGO

# ============================================================
# COMPORTAMIENTO: roba_y_huye (Saqueador)
# ============================================================

func _process_roba_y_huye(delta: float) -> void:
	# Mientras huye o avanza, siempre puede ser interceptado por técnicas
	if _combate_con_tecnica(delta):
		return

	if huyendo:
		# Avanza hacia el inicio del path (escapando)
		progress -= velocidad_actual * delta
		if progress <= 0.0:
			# Escapó con la pieza. La pérdida de IC ya se aplicó al robar.
			esta_viva = false
			queue_free()
		return

	# Aún no ha robado: avanza hacia el hallazgo
	progress += velocidad_actual * delta

	if ref_hallazgo != null and not robo_realizado:
		var dist = global_position.distance_to(ref_hallazgo.global_position)
		if dist < RADIO_HALLAZGO:
			_robar_pieza()

func _robar_pieza() -> void:
	robo_realizado = true
	huyendo = true

	var mult = 1.0
	if ref_nivel != null and ref_nivel.has_method("obtener_modificador_danio"):
		mult = ref_nivel.obtener_modificador_danio(datos.tipo)

	if ref_hallazgo != null:
		ref_hallazgo.recibir_danio_cientifico(datos.ic_robado * mult)

	# Reinicia estado de combate para la huida
	objetivo_tropa = null
	en_combate = false
	offset_golpe = -10.0  # pequeño "tirón" visual al robar

# ============================================================
# COMBATE CONTRA TÉCNICAS (compartido por ambos comportamientos)
# ============================================================

# Devuelve true si está en combate (y por lo tanto no debe avanzar)
func _combate_con_tecnica(delta: float) -> bool:
	if datos.ignora_tropas:
		return false

	if en_combate and objetivo_tropa != null and is_instance_valid(objetivo_tropa):
		timer_ataque += delta
		if timer_ataque >= 1.0 / datos.velocidad_ataque:
			timer_ataque = 0.0
			objetivo_tropa.recibir_danio(datos.danio_a_tropas, datos.fuerza_empuje)
			offset_golpe = -8.0
		return true

	objetivo_tropa = null
	en_combate = false
	return false

# ============================================================
# DAÑO AL HALLAZGO (solo avanza_y_pega)
# ============================================================

func _atacar_hallazgo() -> void:
	if ref_hallazgo == null:
		return

	var mult = 1.0
	if ref_nivel != null and ref_nivel.has_method("obtener_modificador_danio"):
		mult = ref_nivel.obtener_modificador_danio(datos.tipo)

	if datos.danio_fisico > 0.0:
		ref_hallazgo.recibir_danio_fisico(datos.danio_fisico * mult)
	if datos.danio_cientifico > 0.0:
		ref_hallazgo.recibir_danio_cientifico(datos.danio_cientifico * mult)
	offset_golpe = 6.0

# ============================================================
# INTERACCIÓN CON TÉCNICAS
# ============================================================

func entrar_en_combate(tropa) -> void:
	if pegada_al_hallazgo:
		return
	if datos != null and datos.ignora_tropas:
		if tropa.datos == null or not tropa.datos.efectivo_contra.has(datos.tipo):
			return
	objetivo_tropa = tropa
	en_combate = true

func ralentizar(factor: float) -> void:
	if datos != null:
		velocidad_actual = datos.velocidad * factor

func recibir_danio_de_tropa(cantidad: float, fuerza_empuje_atacante: float = 0.0) -> void:
	flash_danio = 1.0
	hp_actual -= cantidad
	offset_golpe = 6.0

	if randf() < fuerza_empuje_atacante and not pegada_al_hallazgo and not huyendo:
		progress -= 30.0

	if hp_actual <= 0.0:
		esta_viva = false
		# Si lo matan mientras huía con la pieza robada, se recupera la IC
		if datos.comportamiento == "roba_y_huye" and robo_realizado and huyendo:
			if ref_hallazgo != null:
				ref_hallazgo.curar_cientifico(datos.ic_robado)
		queue_free()

func _draw() -> void:
	if datos == null:
		return
	var color = datos.color_debug.lerp(Color.WHITE, flash_danio)
	draw_rect(Rect2(-16 + offset_golpe, -16, 32, 32), color)
