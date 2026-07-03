class_name AlmanacEntryData
extends Resource

@export var titulo: String = ""
@export_multiline var contenido: String = ""
@export var imagen: Texture2D = null
@export var especialista_requerido: String = ""  # nombre exacto del especialista
@export var nivel_requerido: int = -1  # -1 = cualquier nivel
@export var icono_categoria: String = ""  # "🦴", "📷", "🌊", etc.
