extends MeshInstance3D

var chunk: Chunk
var chunk_size
var world_ref:World 
# Mesh arrays
var vertices = PackedVector3Array()
var uvs = PackedVector2Array()
var normals = PackedVector3Array()
var indices = PackedInt32Array()
var material:StandardMaterial3D = preload("res://blockdev.tres")

var surface = []
var arr_mesh

func setup(_chunk):
	self.chunk = _chunk
	self.position = chunk.position
	self.chunk_size = WorldHelper.chunk_size
	chunk.set_mesh(self)


func generate():
	chunk.set_modified(false)
	#print("generating " + str(position) + " : "+ str(chunk))
	surface = []
	arr_mesh = ArrayMesh.new()
	vertices.clear()
	indices.clear()
	normals.clear()
	uvs.clear()
	
	if(chunk.isEmpty):
		return
	
	for ay in range(chunk_size):
		for ax in range(chunk_size):
			for az in range(chunk_size):
				if chunk.get_block(Vector3i(ax,ay,az)) == 1:  # Solid block
					add_block_mesh(Vector3(ax, ay, az))
	
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = vertices
	surface[Mesh.ARRAY_NORMAL] = normals
	surface[Mesh.ARRAY_INDEX] = indices
	surface[Mesh.ARRAY_TEX_UV] = uvs
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	self.mesh = arr_mesh
	self.material_override = material
	

# Add a block's visible faces to the mesh
#block pos is local coords ie 0-16
func add_block_mesh(block_pos):
	
	for faces in range(6):  # 6 faces
		if is_face_visible(block_pos, WorldHelper.NEIGHBOR_OFFSETS[faces]):
			var face = FACE_DATA[faces]
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
func is_face_visible(pos: Vector3, offset: Vector3) -> bool:
	var neighbouring_chunk_pos:Vector3i = self.position + offset
	var neighbours = chunk.get_chunk_neigbour_ref()
	var n_chunk = null
	var query_pos = pos + offset
	if(neighbours.has(neighbouring_chunk_pos)):
		n_chunk = neighbours[neighbouring_chunk_pos]

	#the face on the edge of the chunk
	if((query_pos.x < 0 or query_pos.x > chunk_size-1) or (query_pos.y < 0 or query_pos.y > chunk_size-1) or (query_pos.z < 0 or query_pos.z > chunk_size-1)):
		if(n_chunk != null):
			return n_chunk.get_block(_calc_chunk_pos_wrap(query_pos)) == 0
		else:
			return chunk.get_block(pos) == 1#this over rerders faces
			
	return chunk.get_block(query_pos) == 0
		

func _calc_chunk_pos_wrap(input :Vector3i)-> Vector3i:
		var cz = WorldHelper.chunk_size
		var result = input

		if(input.x < 0):
			result.x = cz-1
		elif(input.x > cz-1):
			result.x = 0
				
		if(input.y < 0):
			result.y = cz-1
		elif(input.y > cz-1):
				result.y = 0
				
		if(input.z < 0):
			result.z = cz-1
		elif(input.z > cz-1):
			result.z = 0	
			
		return result

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
