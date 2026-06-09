extends PathFollow2D

@export var velocidad: float = 80.0
@export var nombre_especialista: String = "Especialista"
@export var danio: float = 25.0
@export var hp: float = 100.0
@export var radio_deteccion: float = 60.0
@export var velocidad_ataque: float = 1.0
@export var fuerza_empuje: float = 0.5

var objetivo = null
var timer_ataque: float = 0.0
var en_combate: bool = false
var esta_vivo: bool = true

# Para el efecto de golpe visual
var offset_golpe: float = 0.0

func _ready() -> void:
	print(nombre_especialista, " desplegado!")

func _process(delta: float) -> void:
	if not esta_vivo:
		return

	# Suavizar offset de golpe
	offset_golpe = lerp(offset_golpe, 0.0, delta * 10.0)

	if objetivo == null or not is_instance_valid(objetivo):
		objetivo = null
		en_combate = false
		_buscar_enemigo()

	if en_combate and objetivo != null:
		timer_ataque += delta
		if timer_ataque >= 1.0 / velocidad_ataque:
			timer_ataque = 0.0
			_atacar()
	else:
		progress -= velocidad * delta
		# Desaparecer al llegar al extremo izquierdo
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
			if dist <= radio_deteccion:
				objetivo = hijo
				en_combate = true
				hijo.entrar_en_combate(self)
				return

func _atacar() -> void:
	if objetivo != null and is_instance_valid(objetivo):
		objetivo.recibir_danio_de_tropa(danio, fuerza_empuje)
		# Pequeño empujón visual hacia el enemigo
		offset_golpe = 8.0
	else:
		objetivo = null
		en_combate = false

func recibir_danio(cantidad: float, fuerza_empuje_atacante: float = 0.0) -> void:
	hp -= cantidad
	# Sacudida visual al recibir golpe
	offset_golpe = -6.0
	print(nombre_especialista, " HP: ", hp)

	if randf() < fuerza_empuje_atacante:
		progress += 30.0
		print(nombre_especialista, " empujado!")

	if hp <= 0.0:
		esta_vivo = false
		queue_free()

func _draw() -> void:
	# El offset_golpe mueve el cuadro levemente al atacar/recibir daño
	draw_rect(Rect2(-16 + offset_golpe, -16, 32, 32), Color.CYAN)
	draw_arc(Vector2.ZERO, radio_deteccion, 0, TAU, 32, Color(0, 1, 1, 0.2))
