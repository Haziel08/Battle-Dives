class_name SpecialistData
extends Resource

@export var nombre: String = ""
@export var costo: int = 50
@export var duracion: float = 15.0  # segundos activo sobre el hallazgo

# --- PASIVA (constante mientras está activo) ---
@export var pasiva_ic_por_seg: float = 0.0
@export var pasiva_if_por_seg: float = 0.0
@export var pasiva_reduce_prob_evento: float = 0.0  # 0.0 - 1.0

# --- REDUCCIÓN DE PROBABILIDAD DE AMENAZA (Educador Comunitario) ---
@export var reduce_prob_amenaza_tipo: String = ""
@export var reduce_prob_amenaza_pct: float = 0.0

# --- ACTIVA (botón con cooldown) ---
@export var tiene_activa: bool = false
@export var nombre_activa: String = ""
@export var cooldown_activa: float = 20.0

@export var activa_ic_instantaneo: float = 0.0
@export var activa_if_instantaneo: float = 0.0
@export var activa_reduce_danio_pct: float = 0.0   # próximo golpe (Conservador)
@export var activa_cura_efecto: String = ""        # "baja_visibilidad", etc.
@export var pasiva_fi_por_seg: float = 0.0
@export var activa_fi_instantaneo: float = 0.0

# Campaña de Concientización (Educador)
@export var activa_reduce_danio_amenaza_pct: float = 0.0
@export var activa_aplica_a_tipos: Array[String] = []
@export var activa_duracion_efecto: float = 10.0
# Si esta activa completa un paso de extracción, su ID va aquí
@export var accion_extraccion_id: String = ""

@export var color_debug: Color = Color.GREEN

@export var spritesheet_path: String = ""
@export var spritesheet_hframes: int = 4

@export_multiline var info_real: String = ""
@export_multiline var descripcion_graciosa: String = ""

@export var imagen_almanaque: Texture2D = null
@export var titulo_entrada: String = ""
@export_multiline var texto_entrada: String = ""
@export var desbloqueado_en_nivel: int = -1
