class_name EventData
extends Resource

@export var nombre: String = ""
@export var tipo: String = ""  # "huracan", "sismo", "baja_visibilidad", "corrientes"
@export var duracion: float = 15.0

# --- EFECTOS ---
@export var oculta_pantalla: bool = false
@export var reduce_radio_deteccion_pct: float = 0.0   # 0.0-1.0
@export var multiplica_velocidad_amenazas: float = 1.0
@export var danio_fisico_instantaneo: float = 0.0     # Sismo: golpe único al iniciar

@export var color_debug: Color = Color(0.3, 0.3, 0.5)
@export_multiline var info_real: String = ""
@export_multiline var descripcion_graciosa: String = ""
@export var fotos_reales: Array[String] = []
