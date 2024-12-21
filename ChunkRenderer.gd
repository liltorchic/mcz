extends Node3D

var meshRenderScript 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.position = _os
	meshRenderScript = preload("res://ChunkMeshBuilder.gd").new()
	meshRenderScript.setup(x, y, z, chunk_data,slices,chunk_size) # Replace with function body.
	add_child(meshRenderScript)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
