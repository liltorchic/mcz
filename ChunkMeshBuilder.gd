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
func _add_block_mesh(block_pos):
	
	var my_chunk_neighbours:Dictionary = chunk.get_chunk_neigbour_ref()
	var query_pos
	
	#if we are at the edge of the chunk omg
	if((block_pos.x == 0 or block_pos.x == chunk_size-1) or (block_pos.y == 0 or block_pos.y == chunk_size-1) or (block_pos.z == 0 or block_pos.z == chunk_size-1)):
		for faces in range(6):  # 6 faces
			var face_pos = block_pos + WorldHelper.NEIGHBOR_OFFSETS[faces]
			query_pos = _calc_chunk_pos_wrap(face_pos)
			
			#get chunk that face we are quering for is touching
				#get it by figuring out which direction to step
			var my_chunk_pos = Vector3i(self.position)
			var query_chunk_pos:Vector3i
				
			if(face_pos.x < 0):#we are on x = 0 looking x-1
				query_chunk_pos = my_chunk_pos + Vector3i(-1,0,0)
			elif(face_pos.x > 16):#we are on x = 16 looking x+1
				query_chunk_pos = my_chunk_pos + Vector3i(1,0,0) 
			elif(face_pos.y < 0):#we are on y = 0 looking y-1
				query_chunk_pos = my_chunk_pos + Vector3i(0,-1,0)
			elif(face_pos.y > 16):#we are on y = 16 looking y+1
				query_chunk_pos = my_chunk_pos + Vector3i(0,1,0)
			elif(face_pos.z < 0):#we are on z = 0 looking z-1
				query_chunk_pos = my_chunk_pos + Vector3i(0,0,-1)
			elif(face_pos.z > 16):#we are on z = 16 looking z+1
				query_chunk_pos = my_chunk_pos + Vector3i(1,0,1)
			else:#we arent on a chunk edge
				if(chunk.get_block(query_pos) == 0):
					_add_face(block_pos,faces)
					break
				
			if(query_chunk_pos != null):
				if(my_chunk_neighbours.has(query_chunk_pos)):
					if(my_chunk_neighbours[query_chunk_pos] != null):
						if(my_chunk_neighbours[query_chunk_pos].get_block(query_pos) == 0):
							_add_face(block_pos,faces)		
			elif((query_chunk_pos == null)):#if the chunk does not exist
				_add_face(block_pos,faces)
	
	#if we are NOT at the edge of the chunk								
	else:
		for faces in range(6):  # 6 faces
			query_pos = block_pos + WorldHelper.NEIGHBOR_OFFSETS[faces]
			if(chunk.get_block(query_pos) == 0):
				_add_face(block_pos,faces)



func _add_face(_block_pos, _faces):
	var face = WorldHelper.FACE_DATA[_faces]
	var base_index = vertices.size()
				
				# Add face vertices
	for vertex in face["vertices"]:
		vertices.append(vertex + _block_pos)
		normals.append(face["normal"])
		uvs.append(Vector2(face["vertices"][0].x, face["vertices"][0].z))  # UV for texture  # Basic UVs
				
	# Add face indices
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
		
