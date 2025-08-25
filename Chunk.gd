extends Node3D

class_name Chunk

var noise: FastNoiseLite
var chunk_size: int
var chunk_data = []

var isEmpty: bool # True when no visible blocks are present
var isFull: bool # True when no air blocks are present
var y_slice_dict = {}

var neighbour_ref_dict = {}

var world_ref

var is_modified:bool

var mesh

func bottom_layer_is_solid() -> bool:
	# Bottom layer is cy == 0 in chunk-local coords
	if y_slice_dict.has(0):
		return y_slice_dict[0] == (chunk_size * chunk_size)
	# Fallback if dict not filled for some reason
	if not chunk_data.is_empty():
		var solid = 0
		for cx in range(chunk_size):
			for cz in range(chunk_size):
				if chunk_data[0][cx][cz] == 1:
					solid += 1
		return solid == (chunk_size * chunk_size)
	return false

func _init(_noise, _x, _y, _z, _chunk_size):
	self.noise = _noise
	self.position.x = _x
	self.position.y = _y
	self.position.z = _z
	self.chunk_size = _chunk_size
	self.isEmpty = true
	self.is_modified = false
	self.isFull = false


func load_data():
	var total_blocks := chunk_size * chunk_size * chunk_size
	y_slice_dict.clear()
	chunk_data.clear()

	# Compute this chunk's Y in CHUNK coordinates (position is in world blocks later)
	var chunk_y := int(floor(position.y / chunk_size))

	# ---- Failsafe: force deep chunks to be solid (<= -8 in CHUNK space)
	if chunk_y <= -8:
		chunk_data.resize(chunk_size)
		for cy in range(chunk_size):
			chunk_data[cy] = []
			chunk_data[cy].resize(chunk_size)
			for cx in range(chunk_size):
				chunk_data[cy][cx] = []
				chunk_data[cy][cx].resize(chunk_size)
				for cz in range(chunk_size):
					chunk_data[cy][cx][cz] = 1
			y_slice_dict[cy] = chunk_size * chunk_size
		isEmpty = false
		isFull = true
		is_modified = true
		return
	# ---- end failsafe

	var world_noise = []
	world_noise.resize(chunk_size)
	for cx in range(chunk_size):
		world_noise[cx] = []
		world_noise[cx].resize(chunk_size)
		var nx = (position.x + cx)
		for cz in range(chunk_size):
			var nz = (position.z + cz)
			world_noise[cx][cz] = (noise.get_noise_2d(nx, nz) + 1) / 2.0  # [0,1]

	var counter_all := 0
	chunk_data.resize(chunk_size)
	for cy in range(chunk_size):
		var y_index = (cy + position.y)  # world block Y
		var slice_count := 0
		chunk_data[cy] = []
		chunk_data[cy].resize(chunk_size)
		for cx in range(chunk_size):
			chunk_data[cy][cx] = []
			chunk_data[cy][cx].resize(chunk_size)
			for cz in range(chunk_size):
				var w = world_noise[cx][cz] * 32.0  # height scale
				if w > y_index:
					chunk_data[cy][cx][cz] = 1
					slice_count += 1
					counter_all += 1
				else:
					chunk_data[cy][cx][cz] = 0
		y_slice_dict[cy] = slice_count

	# --- FIX: set full BEFORE the "non-empty" branch, not as an elif that never runs
	if counter_all == total_blocks:
		self.isFull = true
		self.isEmpty = false
		self.is_modified = true
	elif counter_all > 0:
		self.isEmpty = false
		self.is_modified = true
	else:
		self.isEmpty = true
		self.isFull = false

func get_block(pos:Vector3i):
	if(!chunk_data.is_empty()):
		var result = self.chunk_data[pos.y][pos.x][pos.z]
		return result
	else:
		return null
		
func assign_chunk_neigbour_ref(dict:Dictionary):
	self.neighbour_ref_dict = dict
	
func get_chunk_neigbour_ref():
	return self.neighbour_ref_dict
	
func get_world():
	return self.world_ref
	
func regenerate_mesh():
	if(self.get_mesh() != null):
		self.get_mesh().generate()
	
func set_mesh(m:MeshInstance3D):
	self.mesh = m
	if(self.mesh != null):
		self.mesh.generate()
	
func get_mesh() -> MeshInstance3D: 
	return self.mesh
	
func set_modified(flag:bool):
	self.is_modified = flag
	
func get_modified():
	return self.is_modified
	
func is_empty():
	return self.isEmpty
	
func is_full():
	return self.isFull
