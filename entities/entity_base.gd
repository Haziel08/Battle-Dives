extends PathFollow2D

var datos: TechniqueData = null
var hp_actual: float = 0.0
var objetivo = null
var timer_ataque: float = 0.0
var en_combate: bool = false
var esta_vivo: bool = true
var offset_golpe: float = 0.0
var flash_danio: float = 0.0
var ref_hallazgo = null
var ref_nivel = null
var timer_vida_estatico: float = 0.0

func inicializar(ficha: TechniqueData, hallazgo, nivel) -> void:
	datos = ficha
	hp_actual = ficha.hp
	ref_hallazgo = hallazgo
	ref_nivel = nivel

func _process(delta: float) -> void:
	if not esta_vivo or datos == null:
		return

	offset_golpe = lerp(offset_golpe, 0.0, delta * 10.0)
	flash_danio = lerp(flash_danio, 0.0, delta * 15.0)

	if datos.es_estatico:
		timer_vida_estatico += delta
		if timer_vida_estatico >= datos.duracion_estatico:
			esta_vivo = false
			queue_free()
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
			# Si la amenaza ignora tropas, solo me ancho si soy su contador
			if hijo.datos != null and hijo.datos.ignora_tropas:
				if not datos.efectivo_contra.has(hijo.datos.tipo):
					continue
			var dist = global_position.distance_to(hijo.global_position)
			var radio_efectivo = datos.radio_deteccion
			if ref_nivel != null:
				radio_efectivo *= ref_nivel.get_modificador_radio_deteccion()
			if dist <= radio_efectivo:
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

	if objetivo.datos is ThreatData:
		if datos.efectivo_contra.has(objetivo.datos.tipo):
			danio_final *= datos.multiplicador_danio

	objetivo.recibir_danio_de_tropa(danio_final, datos.fuerza_empuje)
	offset_golpe = 8.0

func recibir_danio(cantidad: float, fuerza_empuje_atacante: float = 0.0) -> void:
	flash_danio = 1.0
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
	var color = datos.color_debug.lerp(Color.WHITE, flash_danio)
	draw_rect(Rect2(-16 + offset_golpe, -16, 32, 32), color)
	if not datos.es_estatico:
		draw_arc(Vector2.ZERO, datos.radio_deteccion, 0, TAU, 32, Color(datos.color_debug.r, datos.color_debug.g, datos.color_debug.b, 0.2))
