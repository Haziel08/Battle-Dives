extends PathFollow2D

@export var velocidad: float = 40.0
@export var danio_fisico: float = 30.0
@export var danio_cientifico: float = 20.0
@export var nombre_amenaza: String = "Amenaza"
@export var hp: float = 100.0
@export var danio_a_tropas: float = 20.0
@export var fuerza_empuje: float = 0.3
@export var velocidad_ataque: float = 1.0

var ref_hallazgo = null
var esta_viva: bool = true
var objetivo_tropa = null
var en_combate: bool = false
var timer_ataque: float = 0.0
var offset_golpe: float = 0.0

func _process(delta: float) -> void:
	if not esta_viva:
		return

	# Suavizar offset de golpe
	offset_golpe = lerp(offset_golpe, 0.0, delta * 10.0)

	if en_combate and objetivo_tropa != null and is_instance_valid(objetivo_tropa):
		# Atacar tropa
		timer_ataque += delta
		if timer_ataque >= 1.0 / velocidad_ataque:
			timer_ataque = 0.0
			objetivo_tropa.recibir_danio(danio_a_tropas, fuerza_empuje)
			offset_golpe = -8.0
	else:
		# Tropa murió, seguir avanzando
		objetivo_tropa = null
		en_combate = false
		progress += velocidad * delta

		if ref_hallazgo != null:
			var dist = global_position.distance_to(ref_hallazgo.global_position)
			if dist < 40.0:
				_llegar_al_hallazgo()

func entrar_en_combate(tropa) -> void:
	objetivo_tropa = tropa
	en_combate = true

func recibir_danio_de_tropa(cantidad: float, fuerza_empuje_atacante: float = 0.0) -> void:
	hp -= cantidad
	offset_golpe = 6.0
	print(nombre_amenaza, " HP: ", hp)

	if randf() < fuerza_empuje_atacante:
		progress -= 30.0
		print(nombre_amenaza, " empujada!")

	if hp <= 0.0:
		esta_viva = false
		queue_free()

func _llegar_al_hallazgo() -> void:
	esta_viva = false
	if ref_hallazgo != null:
		if danio_fisico > 0.0:
			ref_hallazgo.recibir_danio_fisico(danio_fisico)
		if danio_cientifico > 0.0:
			ref_hallazgo.recibir_danio_cientifico(danio_cientifico)
	queue_free()

func _draw() -> void:
	draw_rect(Rect2(-16 + offset_golpe, -16, 32, 32), Color.RED)
