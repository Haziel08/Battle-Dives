class_name TechniqueData
extends Resource

@export var nombre: String = ""
@export var costo: int = 50
@export var hp: float = 100.0
@export var danio: float = 25.0
@export var velocidad: float = 80.0
@export var velocidad_ataque: float = 1.0
@export var fuerza_empuje: float = 0.0
@export var radio_deteccion: float = 60.0
@export var es_estatico: bool = false
@export var duracion_estatico: float = 10.0

@export var efectivo_contra: Array[String] = []
@export var multiplicador_danio: float = 2.0

@export var color_debug: Color = Color.CYAN

@export var spritesheet_path: String = ""
@export var spritesheet_hframes: int = 4

@export_multiline var info_real: String = ""
@export_multiline var descripcion_graciosa: String = ""
