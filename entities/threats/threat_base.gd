extends PathFollow2D

var datos: ThreatData = null

var hp_actual: float = 0.0
var ref_hallazgo = null
var esta_viva: bool = true
var objetivo_tropa = null
var en_combate: bool = false
var timer_ataque: float = 0.0
var timer_danio_continuo: float = 0.0
var offset_golpe: float = 0.0
var velocidad_actual: float = 0.0
var pegado_al_hallazgo: bool = false
var timer_pegado: float = 0.0
const DURACION_PEGADO: float = 5.0  # segundos pegado antes de desaparecer

func inicializar(ficha: ThreatData, hallazgo) -> void:
	datos = ficha
	hp_actual = ficha.hp
	ref_hallazgo = hallazgo
	velocidad_actual = ficha.velocidad

# Reemplaza _process completo:
func _process(delta: float) -> void:
	if not esta_viva or datos == null:
		return

	offset_golpe = lerp(offset_golpe, 0.0, delta * 10.0)

	# Si está pegado al hallazgo, hacer daño continuo
	if pegado_al_hallazgo:
		timer_pegado += delta
		timer_danio_continuo += delta
		if timer_danio_continuo >= 1.0:
			timer_danio_continuo = 0.0
			if ref_hallazgo != null:
				ref_hallazgo.recibir_danio_fisico(datos.danio_fisico * 0.1)
				ref_hallazgo.recibir_danio_cientifico(datos.danio_cientifico * 0.1)
		if timer_pegado >= DURACION_PEGADO:
			esta_viva = false
			queue_free()
		return

	# Daño continuo en tránsito (Contaminación)
	if datos.danio_continuo and ref_hallazgo != null:
		timer_danio_continuo += delta
		if timer_danio_continuo >= 1.0:
			timer_danio_continuo = 0.0
			ref_hallazgo.recibir_danio_fisico(2.0)

	if not datos.ignora_tropas and en_combate and objetivo_tropa != null and is_instance_valid(objetivo_tropa):
		timer_ataque += delta
		if timer_ataque >= 1.0 / datos.velocidad_ataque:
			timer_ataque = 0.0
			objetivo_tropa.recibir_danio(datos.danio_a_tropas, datos.fuerza_empuje)
			offset_golpe = -8.0
	else:
		objetivo_tropa = null
		en_combate = false
		progress += velocidad_actual * delta
		if ref_hallazgo != null:
			var dist = global_position.distance_to(ref_hallazgo.global_position)
			if dist < 40.0:
				_llegar_al_hallazgo()

func entrar_en_combate(tropa) -> void:
	if datos != null and datos.ignora_tropas:
		return
	objetivo_tropa = tropa
	en_combate = true

func ralentizar(factor: float) -> void:
	if datos != null:
		velocidad_actual = datos.velocidad * factor

func recibir_danio_de_tropa(cantidad: float, fuerza_empuje_atacante: float = 0.0) -> void:
	if datos != null and datos.ignora_tropas:
		return
	hp_actual -= cantidad
	offset_golpe = 6.0
	if randf() < fuerza_empuje_atacante:
		progress -= 30.0
	if hp_actual <= 0.0:
		esta_viva = false
		queue_free()

# Reemplaza _llegar_al_hallazgo():
func _llegar_al_hallazgo() -> void:
	# Daño inicial de impacto
	if ref_hallazgo != null:
		ref_hallazgo.recibir_danio_fisico(datos.danio_fisico * 0.5)
		ref_hallazgo.recibir_danio_cientifico(datos.danio_cientifico * 0.5)
	# Quedarse pegado haciendo daño continuo
	pegado_al_hallazgo = true
	timer_pegado = 0.0

func _draw() -> void:
	if datos == null:
		return
	draw_rect(Rect2(-16 + offset_golpe, -16, 32, 32), datos.color_debug)
