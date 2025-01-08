extends Node
class_name WorldHelper

const chunk_size := 16
const chunk_builder_max_threads := 2
# Neighbor offsets for checking adjacent blocks
const NEIGHBOR_OFFSETS = [
	Vector3(1, 0, 0),  # Right
	Vector3(-1, 0, 0), # Left
	Vector3(0, 1, 0),  # Top
	Vector3(0, -1, 0), # Bottom
	Vector3(0, 0, 1),  # Front
	Vector3(0, 0, -1)  # Back
]
