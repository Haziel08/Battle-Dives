class_name LevelData
extends Resource

@export var nombre_nivel: String = "Nivel 1"
@export var descripcion: String = ""

@export var nombre_hallazgo: String = "Hallazgo"
@export var hallazgo_if: float = 1000.0
@export var hallazgo_ic: float = 200.0

@export var fi_inicial: float = 100.0
@export var fi_pasivo_base: float = 5.0

# --- TÉCNICAS Y ESPECIALISTAS DISPONIBLES ---
@export var tecnicas_disponibles: Array[TechniqueData] = []
@export var especialistas_disponibles: Array[SpecialistData] = []

# --- DURACIÓN Y OLEADAS ---
@export var duracion_nivel: float = 180.0
@export var oleadas: Array[WaveEntry] = []

# --- EVENTOS (Bloque D) ---
#@export var eventos_posibles: Array[EventData] = []
@export var prob_evento_por_minuto: float = 0.3
@export var danio_if_por_tiempo: float = 0.5

# --- VICTORIA ---
@export_enum("sobrevivir_tiempo", "eliminar_amenazas_clave") var condicion_victoria: String = "sobrevivir_tiempo"
@export var ic_minima_para_ganar: float = 50.0
@export var if_minima_para_ganar: float = 50.0

# --- TUTORIAL ---
@export var es_tutorial: bool = false
#@export var pasos_tutorial: Array[TutorialStep] = []

# --- EXTRACCIÓN (Bloque futuro, Nivel 3/4) ---
@export var permite_extraccion: bool = false
@export var pasos_extraccion: Array[String] = []
