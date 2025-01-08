extends Node3D

var buildScript
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_world_chunk_loaded(chunk: Chunk) -> void:
	if(!chunk.isEmpty):
		buildScript = preload("res://ChunkMeshBuilder.gd").new()
		buildScript.setup(chunk)
		add_child(buildScript)
