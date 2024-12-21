extends Node3D

class_name Chunk

var noise: FastNoiseLite
var chunk_size: int
var chunk_data = []

var isEmpty
var y_slice_dict = {}

func _init(_noise, _x,_y, _z, _chunk_size):
	
	self.noise = _noise
	self.position.x = _x
	self.position.y = _y
	self.position.z = _z
	self.chunk_size = _chunk_size

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

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
				else:
					chunk_data[cy][cx][cz] = 0		
		y_slice_dict[cy] = counter
		counter = 0

func getBlock(localx, localy, localz):
	
		return self.chunk_data[localx][localy][localz]
