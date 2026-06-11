# threat_data.gd
class_name ThreatData
extends Resource

@export var nombre: String = "Amenaza"
@export var hp: float = 100.0
@export var velocidad: float = 40.0
@export var danio_fisico: float = 30.0
@export var danio_cientifico: float = 20.0
@export var danio_a_tropas: float = 20.0
@export var velocidad_ataque: float = 1.0
@export var fuerza_empuje: float = 0.3
@export var ignora_tropas: bool = false
@export var danio_continuo: bool = false
@export var color_debug: Color = Color.RED
# Tipo de amenaza para el sistema de ventajas
@export var tipo: String = "normal"
