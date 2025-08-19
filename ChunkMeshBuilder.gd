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
				if chunk.get_block(Vector3i(ax,ay,az)) > 0:  # Solid block
					_add_block_mesh(Vector3(ax, ay, az))
	
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = vertices
	surface[Mesh.ARRAY_NORMAL] = normals
	surface[Mesh.ARRAY_INDEX] = indices
	surface[Mesh.ARRAY_TEX_UV] = uvs
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	self.mesh = arr_mesh
	self.material_override = material
	
#if is_face_visible(block_pos, WorldHelper.NEIGHBOR_OFFSETS[faces]):
#n_chunk.get_block(_calc_chunk_pos_wrap(query_pos)) == 0

# Add a block's visible faces to the mesh
#block pos is local coords ie 0-16
func _add_block_mesh(block_pos: Vector3i):
	var my_chunk_neighbours: Dictionary = chunk.get_chunk_neigbour_ref()
	var query_pos: Vector3i
	
	# Are we at a chunk edge?
	if block_pos.x == 0 or block_pos.x == chunk_size - 1 \
	 or block_pos.y == 0 or block_pos.y == chunk_size - 1 \
	 or block_pos.z == 0 or block_pos.z == chunk_size - 1:
		
		for face in range(6): # 6 faces
			var face_pos: Vector3i = block_pos + Vector3i(WorldHelper.NEIGHBOR_OFFSETS[face])
			query_pos = _calc_chunk_pos_wrap(face_pos)

			# Figure out which neighbor chunk to ask (if any)
			var my_chunk_pos: Vector3i = Vector3i(self.position) / chunk_size
			var query_chunk_pos: Vector3i = my_chunk_pos

			if face_pos.x < 0:
				query_chunk_pos += Vector3i(-1, 0, 0)
			elif face_pos.x > chunk_size - 1:
				query_chunk_pos += Vector3i(1, 0, 0)
			elif face_pos.y < 0:
				query_chunk_pos += Vector3i(0, -1, 0)
			elif face_pos.y > chunk_size - 1:
				query_chunk_pos += Vector3i(0, 1, 0)
			elif face_pos.z < 0:
				query_chunk_pos += Vector3i(0, 0, -1)
			elif face_pos.z > chunk_size - 1:
				query_chunk_pos += Vector3i(0, 0, 1)

			# If still inside this chunk
			if query_chunk_pos == my_chunk_pos:
				if chunk.get_block(face_pos) == 0:
					_add_face(block_pos, face)
			else:
				# Look into neighbor
				if my_chunk_neighbours.has(query_chunk_pos):
					var neighbor: Chunk = my_chunk_neighbours[query_chunk_pos]
					if neighbor != null and neighbor.get_block(query_pos) == 0:
						_add_face(block_pos, face)
				else:
					# Neighbor chunk not loaded, assume visible
					_add_face(block_pos, face)
	else:
		# Not on edge → just check inside current chunk
		for face in range(6):
			query_pos = block_pos + Vector3i(WorldHelper.NEIGHBOR_OFFSETS[face])
			if chunk.get_block(query_pos) == 0:
				_add_face(block_pos, face)



func _add_face(_block_pos: Vector3i, _faces: int):
	var face = WorldHelper.FACE_DATA[_faces]
	var base_index = vertices.size()

	var uv_template = [
		Vector2(0, 0),
		Vector2(1, 0),
		Vector2(1, 1),
		Vector2(0, 1),
	]

	for i in range(4):
		vertices.append(face["vertices"][i] + Vector3(_block_pos))
		normals.append(face["normal"])
		uvs.append(uv_template[i])

	indices.append(base_index + 0)
	indices.append(base_index + 1)
	indices.append(base_index + 2)
	indices.append(base_index + 0)
	indices.append(base_index + 2)
	indices.append(base_index + 3)
	

#this might not be correct
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
		
