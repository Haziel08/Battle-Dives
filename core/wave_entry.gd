class_name WaveEntry
extends Resource

@export var threat: ThreatData
@export var cantidad: int = 3
@export var intervalo_spawn: float = 2.0
@export var tiempo_inicio: float = 0.0

# Estado runtime (no se edita en el Inspector)
var spawneados: int = 0
var timer_spawn: float = 0.0
var iniciada: bool = false
