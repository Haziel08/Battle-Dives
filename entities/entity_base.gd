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
var tiene_sprite: bool = false

func inicializar(ficha: TechniqueData, hallazgo, nivel) -> void:
	datos = ficha
	hp_actual = ficha.hp
	ref_hallazgo = hallazgo
	ref_nivel = nivel
	_configurar_sprite()

func _configurar_sprite() -> void:
	if datos.spritesheet_path == "":
		return
	var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
	if anim == null:
		return
	var tex = load(datos.spritesheet_path)
	if tex == null:
		return
	var frame_w = tex.get_width() / datos.spritesheet_hframes
	var frame_h = tex.get_height()
	var frames = SpriteFrames.new()
	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", 8.0)
	for i in datos.spritesheet_hframes:
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * frame_w, 0, frame_w, frame_h)
		frames.add_frame("walk", atlas)
	if datos.attack_frame >= 0:
		frames.add_animation("attack")
		frames.set_animation_loop("attack", false)
		var atk_atlas = AtlasTexture.new()
		atk_atlas.atlas = tex
		atk_atlas.region = Rect2(datos.attack_frame * frame_w, 0, frame_w, frame_h)
		frames.add_frame("attack", atk_atlas)
	anim.sprite_frames = frames
	anim.scale = Vector2(0.07, 0.07)
	anim.play("walk")
	tiene_sprite = true

func _process(delta: float) -> void:
	if not esta_vivo or datos == null:
		return

	offset_golpe = lerp(offset_golpe, 0.0, delta * 10.0)
	flash_danio = lerp(flash_danio, 0.0, delta * 15.0)

	if datos.es_estatico:
		z_index = 0
		timer_vida_estatico += delta
		if timer_vida_estatico >= datos.duracion_estatico:
			esta_vivo = false
			queue_free()
		return

	if objetivo == null or not is_instance_valid(objetivo):
		objetivo = null
		en_combate = false
		_buscar_enemigo()

	if tiene_sprite and datos.attack_frame >= 0:
		var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
		if anim != null:
			var anim_deseada = "attack" if en_combate else "walk"
			if anim.animation != anim_deseada:
				anim.play(anim_deseada)

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

	if objetivo.hp_actual - danio_final > 0.0:
		AudioManager.play_sfx("golpe_tecnica")
	else:
		# Golpe de gracia — sonido diferente
		AudioManager.play_sfx("amenaza_derrotada")

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

func _ready() -> void:
	if has_node("HoverArea"):
		$HoverArea.mouse_entered.connect(_on_hover_enter)
		$HoverArea.mouse_exited.connect(_on_hover_exit)
		
func _on_hover_enter() -> void:
	if ref_nivel == null or datos == null:
		return
	var texto = "%s (Técnica)\nHP: %.0f / %.0f\nDaño: %.0f" % [datos.nombre, hp_actual, datos.hp, datos.danio]
	if en_combate:
		texto += "\n¡En combate!"
	ref_nivel.mostrar_tooltip(texto, global_position + Vector2(20, -60))

func _on_hover_exit() -> void:
	if ref_nivel != null:
		ref_nivel.ocultar_tooltip()

func _draw() -> void:
	if datos == null:
		return
	if not tiene_sprite:
		var color = datos.color_debug.lerp(Color.WHITE, flash_danio)
		draw_rect(Rect2(-16 + offset_golpe, -16, 32, 32), color)
	if not datos.es_estatico:
		draw_arc(Vector2.ZERO, datos.radio_deteccion, 0, TAU, 32, Color(datos.color_debug.r, datos.color_debug.g, datos.color_debug.b, 0.2))
