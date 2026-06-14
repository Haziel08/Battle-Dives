class_name TutorialStep
extends Resource

@export_multiline var texto: String = ""
@export_enum("solo_texto", "esperar_accion") var tipo: String = "solo_texto"
@export var accion_esperada: String = "ninguna"
@export var pausar_oleadas: bool = true
