extends Node3D

class_name Chunk

var noise: FastNoiseLite
var chunk_size: int
var chunk_data = []

var isEmpty: bool # True when no visible blocks are present
var y_slice_dict = {}

var neighbour_ref_dict = {}

var world_ref

var is_modified:bool

var mesh

func _init(_noise, _x,_y, _z, _chunk_size):
	
	self.noise = _noise
	self.position.x = _x
	self.position.y = _y
	self.position.z = _z
	self.chunk_size = _chunk_size
	self.isEmpty = true
	self.is_modified = false

func load_data():
	var world_noise = []
	#generare noise
	world_noise.resize(chunk_size)
	for cx in range(chunk_size):
		world_noise[cx] = []
		world_noise[cx].resize(chunk_size)
		var nx = (position.x + cx)
		for cz in range(chunk_size):
			world_noise[cx][cz] = []
			world_noise[cx][cz].resize(chunk_size)
			var nz = (position.z + cz)
			world_noise[cx][cz] = (noise.get_noise_2d(nx, nz) + 1)/2 # noise in range [0,1]
	
	var counter1 = 0	
	#GENERATE DATA
	for cy in range(chunk_size):
		var y_index = (cy + position.y)
		var counter = 0
		chunk_data.resize(chunk_size)
		chunk_data[cy] = []
		chunk_data[cy].resize(chunk_size)
		for cx in range(chunk_size):
			chunk_data[cy][cx] = []
			chunk_data[cy][cx].resize(chunk_size)
			for cz in range(chunk_size):
				#world_noise[x][y] is 0 at lowest valley and 1 at highest peak
				var w = world_noise[cx][cz] * 32
				if(w > y_index):
					chunk_data[cy][cx][cz] = 1
					counter = counter + 1
					counter1 = counter1 + 1
					if(isEmpty):
						isEmpty = false
				else:
					chunk_data[cy][cx][cz] = 0		
		y_slice_dict[cy] = counter
		counter = 0
	if(counter1 > 0):
		isEmpty = false
		is_modified = true

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
	if(self.mesh == null):
		self.mesh.generate()
	
func get_mesh() -> MeshInstance3D: 
	return self.mesh
	
func set_modified(flag:bool):
	self.is_modified = flag
	
func get_modified():
	return self.is_modified
