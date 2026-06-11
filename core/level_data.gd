class_name LevelData
extends Resource

# --- INFO GENERAL ---
@export var nombre_nivel: String = "Nivel 1"
@export var descripcion: String = ""

# --- HALLAZGO ---
@export var nombre_hallazgo: String = "Hallazgo"
@export var hallazgo_if: float = 1000.0
@export var hallazgo_ic: float = 200.0

# --- ECONOMÍA ---
@export var fi_inicial: float = 100.0
@export var fi_pasivo_base: float = 5.0

# --- ESPECIALISTAS DISPONIBLES EN ESTE NIVEL ---
@export var especialistas_disponibles: Array[SpecialistData] = []

# --- OLEADAS ---
@export var amenazas_oleada: Array[ThreatData] = []
@export var intervalo_oleada: float = 3.0
@export var oleada_aleatoria: bool = true

# --- TUTORIAL ---
@export var es_tutorial: bool = false
@export var pasos_tutorial: Array[String] = []  # mensajes a mostrar en orden

# --- EXTRACCIÓN CONTROLADA (Nivel 3/4) ---
@export var permite_extraccion: bool = false
@export var pasos_extraccion: Array[String] = []  # nombres de los pasos requeridos
