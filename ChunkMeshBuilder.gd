extends MeshInstance3D

var chunk: Chunk
var chunk_size
# Mesh arrays
var vertices = PackedVector3Array()
var uvs = PackedVector2Array()
var normals = PackedVector3Array()
var indices = PackedInt32Array()
var material:StandardMaterial3D = preload("res://blockdev.tres")

func _ready():
	chunk_size = World.chunk_size

	vertices.clear()
	indices.clear()
	normals.clear()
	uvs.clear()
	
	var surface = []
	var arr_mesh = ArrayMesh.new()
	
	self.position = chunk.position
	
	for ay in range(chunk_size):
		if(chunk.y_slice_dict[ay] > 1):#skip slices that are empty
			for ax in range(chunk_size):
				for az in range(chunk_size):
					if chunk.chunk_data[ay][ax][az] == 1:  # Solid block
						add_block_mesh(Vector3(ax, ay, az))
	
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = vertices
	surface[Mesh.ARRAY_NORMAL] = normals
	surface[Mesh.ARRAY_INDEX] = indices
	surface[Mesh.ARRAY_TEX_UV] = uvs
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	self.mesh = arr_mesh
	self.material_override = material
	#print("new mesh node added at " + str(chunk.position))
	#self.mesh = BoxMesh.new()



# Add a block's visible faces to the mesh
#block pos is local coords ie 0-16
func add_block_mesh(block_pos):
	
	for i in range(6):  # 6 faces
		var neighbor_pos:Vector3 = block_pos + NEIGHBOR_OFFSETS[i]
		if is_face_visible(neighbor_pos):
			var face = FACE_DATA[i]
			var base_index = vertices.size()
			
			# Add face vertices
			for vertex in face["vertices"]:
				vertices.append(vertex + block_pos)
				normals.append(face["normal"])
				uvs.append(Vector2(face["vertices"][0].x, face["vertices"][0].z))  # UV for texture  # Basic UVs
			
			# Add face indices
			indices.append(base_index + 0)
			indices.append(base_index + 1)
			indices.append(base_index + 2)
			indices.append(base_index + 0)
			indices.append(base_index + 2)
			indices.append(base_index + 3)

# Check if a face is visible
# neighbor_pos is local coords ie 0-16
func is_face_visible(neighbor_pos: Vector3) -> bool:
	if  (neighbor_pos.x < 0 ):#side
		return true
	elif(neighbor_pos.x >= chunk_size):#side
		return true
	elif(neighbor_pos.y < 0):#top
		return true
	elif(neighbor_pos.y >= chunk_size):#bottom
		return true
	elif(neighbor_pos.z < 0):#front
		return true
	elif(neighbor_pos.z >= chunk_size):#back
		return true
	else:
		return chunk.chunk_data[neighbor_pos.y][neighbor_pos.x][neighbor_pos.z] == 0  # Only air blocks are considered visible


func setup(_pos, _chunk):
	self.position = _pos
	self.chunk = _chunk


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
