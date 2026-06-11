extends PathFollow2D

var datos: SpecialistData = null
var hp_actual: float = 0.0
var objetivo = null
var timer_ataque: float = 0.0
var timer_curacion: float = 0.0
var en_combate: bool = false
var esta_vivo: bool = true
var offset_golpe: float = 0.0
var ref_hallazgo = null
var ref_nivel = null

func inicializar(ficha: SpecialistData, hallazgo, nivel) -> void:
	datos = ficha
	hp_actual = ficha.hp
	ref_hallazgo = hallazgo
	ref_nivel = nivel

func _process(delta: float) -> void:
	if not esta_vivo or datos == null:
		return

	offset_golpe = lerp(offset_golpe, 0.0, delta * 10.0)

	if datos.curacion_fisica > 0.0 or datos.curacion_cientifica > 0.0:
		timer_curacion += delta
		if timer_curacion >= 1.0:
			timer_curacion = 0.0
			if ref_hallazgo != null:
				if datos.curacion_fisica > 0.0:
					ref_hallazgo.curar_fisico(datos.curacion_fisica)
				if datos.curacion_cientifica > 0.0:
					ref_hallazgo.curar_cientifico(datos.curacion_cientifica)

	if datos.es_estatico:
		return

	if objetivo == null or not is_instance_valid(objetivo):
		objetivo = null
		en_combate = false
		_buscar_enemigo()

	if en_combate and objetivo != null:
		timer_ataque += delta
		if timer_ataque >= 1.0 / datos.velocidad_ataque:
			timer_ataque = 0.0
			_atacar()
	else:
		progress -= datos.velocidad * delta
		if progress <= 0.0:
			queue_free()

func _buscar_enemigo() -> void:
	var path_node = get_parent()
	if path_node == null:
		return
	for hijo in path_node.get_children():
		if hijo == self:
			continue
		if hijo.has_method("recibir_danio_de_tropa"):
			var dist = global_position.distance_to(hijo.global_position)
			if dist <= datos.radio_deteccion:
				objetivo = hijo
				en_combate = true
				hijo.entrar_en_combate(self)
				return

func _atacar() -> void:
	if objetivo == null or not is_instance_valid(objetivo):
		objetivo = null
		en_combate = false
		return

	if objetivo.datos == null:
		objetivo = null
		en_combate = false
		return

	var danio_final = datos.danio

	# Solo aplica ventaja si el objetivo es una amenaza (tiene threat_data con .tipo)
	if objetivo.datos is ThreatData:
		if datos.efectivo_contra.has(objetivo.datos.tipo):
			danio_final *= datos.multiplicador_danio

	if datos.genera_fi_bonus > 0.0 and objetivo.hp_actual - danio_final <= 0.0:
		if ref_nivel != null:
			ref_nivel.agregar_fi(datos.genera_fi_bonus)

	objetivo.recibir_danio_de_tropa(danio_final, datos.fuerza_empuje)
	offset_golpe = 8.0

func recibir_danio(cantidad: float, fuerza_empuje_atacante: float = 0.0) -> void:
	hp_actual -= cantidad
	offset_golpe = -6.0
	if randf() < fuerza_empuje_atacante:
		progress += 30.0
	if hp_actual <= 0.0:
		esta_vivo = false
		queue_free()

func _draw() -> void:
	if datos == null:
		return
	draw_rect(Rect2(-16 + offset_golpe, -16, 32, 32), datos.color_debug)
	if not datos.es_estatico:
		draw_arc(Vector2.ZERO, datos.radio_deteccion, 0, TAU, 32, Color(datos.color_debug.r, datos.color_debug.g, datos.color_debug.b, 0.2))
