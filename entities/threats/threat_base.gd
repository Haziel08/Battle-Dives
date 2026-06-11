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

# Estado: pegada al hallazgo
var pegada_al_hallazgo: bool = false
const RADIO_HALLAZGO: float = 40.0
const INTERVALO_ATAQUE_HALLAZGO: float = 1.0

func inicializar(ficha: ThreatData, hallazgo) -> void:
	datos = ficha
	hp_actual = ficha.hp
	ref_hallazgo = hallazgo
	velocidad_actual = ficha.velocidad

func _process(delta: float) -> void:
	if not esta_viva or datos == null:
		return

	offset_golpe = lerp(offset_golpe, 0.0, delta * 10.0)

	# Si ya está pegada al hallazgo: solo atacarlo, no se mueve más
	if pegada_al_hallazgo:
		timer_danio_continuo += delta
		if timer_danio_continuo >= INTERVALO_ATAQUE_HALLAZGO:
			timer_danio_continuo = 0.0
			_atacar_hallazgo()
		return

	# Combate contra tropa
	if not datos.ignora_tropas and en_combate and objetivo_tropa != null and is_instance_valid(objetivo_tropa):
		timer_ataque += delta
		if timer_ataque >= 1.0 / datos.velocidad_ataque:
			timer_ataque = 0.0
			objetivo_tropa.recibir_danio(datos.danio_a_tropas, datos.fuerza_empuje)
			offset_golpe = -8.0
		return

	objetivo_tropa = null
	en_combate = false

	# Avanzar hacia el hallazgo
	progress += velocidad_actual * delta

	if ref_hallazgo != null:
		var dist = global_position.distance_to(ref_hallazgo.global_position)
		if dist < RADIO_HALLAZGO:
			pegada_al_hallazgo = true
			timer_danio_continuo = INTERVALO_ATAQUE_HALLAZGO  # ataca inmediatamente al llegar

func _atacar_hallazgo() -> void:
	if ref_hallazgo == null:
		return
	if datos.danio_fisico > 0.0:
		ref_hallazgo.recibir_danio_fisico(datos.danio_fisico)
	if datos.danio_cientifico > 0.0:
		ref_hallazgo.recibir_danio_cientifico(datos.danio_cientifico)
	offset_golpe = 6.0

func entrar_en_combate(tropa) -> void:
	if datos != null and datos.ignora_tropas:
		return
	if pegada_al_hallazgo:
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
	if randf() < fuerza_empuje_atacante and not pegada_al_hallazgo:
		progress -= 30.0
	if hp_actual <= 0.0:
		esta_viva = false
		queue_free()

func _draw() -> void:
	if datos == null:
		return
	draw_rect(Rect2(-16 + offset_golpe, -16, 32, 32), datos.color_debug)
