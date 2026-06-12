# specialist_data.gd
# Esta es la "ficha" de cada especialista. Solo datos, cero lógica.
class_name SpecialistData
extends Resource

@export var nombre: String = "Especialista"
@export var costo: int = 50
@export var hp: float = 100.0
@export var danio: float = 25.0
@export var velocidad: float = 80.0
@export var velocidad_ataque: float = 1.0
@export var fuerza_empuje: float = 0.0
@export var radio_deteccion: float = 60.0
@export var es_estatico: bool = false
@export var curacion_fisica: float = 0.0
@export var curacion_cientifica: float = 0.0
@export var genera_fi_bonus: float = 0.0
@export var color_debug: Color = Color.CYAN
@export var tecla_numero: int = 1  # qué tecla lo despliega (1-7)
@export var efectivo_contra: Array[String] = []
@export var multiplicador_danio: float = 2.0  # daño x2 contra esas amenazas
