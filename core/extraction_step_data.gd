class_name ExtractionStepData
extends Resource

@export var nombre: String = ""
@export_multiline var descripcion: String = ""

# Identificador de la acción que completa este paso:
# "escaneo_3d", "documentar", "estabilizar", "autorizacion", "capsula"
@export var accion_id: String = ""

# Costo en FI (solo para pasos 4 y 5, que son botones directos)
@export var costo_fi: int = 0
