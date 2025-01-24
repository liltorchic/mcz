extends Node
class_name WorldHelper

const chunk_size := 16
const chunk_builder_max_threads := 1
# Neighbor offsets for checking adjacent blocks
const NEIGHBOR_OFFSETS = [
	Vector3(1, 0, 0),  # Right
	Vector3(-1, 0, 0), # Left
	Vector3(0, 1, 0),  # Top
	Vector3(0, -1, 0), # Bottom
	Vector3(0, 0, 1),  # Front
	Vector3(0, 0, -1)  # Back
]

const FACE_DATA = [
	# Right face
	{ "vertices": [Vector3(0.5, -0.5, -0.5), Vector3(0.5, -0.5, 0.5), Vector3(0.5, 0.5, 0.5), Vector3(0.5, 0.5, -0.5)],
	  "normal": Vector3(1, 0, 0) },
	# Left face
	{ "vertices": [Vector3(-0.5, -0.5, 0.5), Vector3(-0.5, -0.5, -0.5), Vector3(-0.5, 0.5, -0.5), Vector3(-0.5, 0.5, 0.5)],
	  "normal": Vector3(-1, 0, 0) },
	# Top face
	{ "vertices": [Vector3(-0.5, 0.5, -0.5), Vector3(0.5, 0.5, -0.5), Vector3(0.5, 0.5, 0.5), Vector3(-0.5, 0.5, 0.5)],
	  "normal": Vector3(0, 1, 0) },
	# Bottom face
	{ "vertices": [Vector3(-0.5, -0.5, 0.5), Vector3(0.5, -0.5, 0.5), Vector3(0.5, -0.5, -0.5), Vector3(-0.5, -0.5, -0.5)],
	  "normal": Vector3(0, -1, 0) },
	# Front face
	{ "vertices": [Vector3(0.5, -0.5, 0.5), Vector3(-0.5, -0.5, 0.5), Vector3(-0.5, 0.5, 0.5),Vector3(0.5, 0.5, 0.5)],
	  "normal": Vector3(0, 0, 1) },
	# Back face
	{ "vertices": [ Vector3(-0.5, -0.5, -0.5),Vector3(0.5, -0.5, -0.5), Vector3(0.5, 0.5, -0.5), Vector3(-0.5, 0.5, -0.5)],
	  "normal": Vector3(0, 0, -1) }
]
