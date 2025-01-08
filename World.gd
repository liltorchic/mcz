extends Node3D
class_name World

var noise

var world_queued_chunks  = [] #chunks that were requested but not enough threads were available, so they are placed in here
var world_loaded_chunks  = {} #chunks that are currently loaded in the scene	
var working_chunks = {} #chunks that are being worked on
var world_chunk_reference_count = {} #tracks references to chunks to allow for culling

var load_threads = {}  # Keep track of active threads.
var thread_pool = []


var dir = DirAccess.open("user://")

# Signal to notify when a chunk is loaded
signal chunk_loaded(chunk: Chunk)

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.fractal_octaves = 8
	noise.frequency = 0.01
	
	for i in range(WorldHelper.chunk_builder_max_threads):
		var thread = Thread.new()
		thread_pool.append(thread)

	var radius = 10

	for ay in range(4):	
				_spiral_traversal_chunk_generation($Camera3D.position, radius, ay)
	#_generate_one_chunk()
		
func _process(delta):

	_threaded_chunk_process() #run chunk code on each new thread
	_update_chunk_queue()	#add chunks waiting to be generated
	call_deferred("_update_chunk_neighbours")#update chunk neighbour dictionary
	call_deferred("_regenerate_modified_chunk_mesh")
	_update_pos_text()
	
func _threaded_chunk_process():
	var finished_positions = []
	
	#run chunk code on each new thread
	for pos in load_threads.keys():
		var thread:Thread = load_threads[pos]
		if thread.is_started():
			var result = thread.wait_to_finish()  # Get result
			_on_thread_complete(thread, result)
			finished_positions.append(pos)
		
	#remove threads from pool
	for pos in finished_positions:
		load_threads.erase(pos)
		finished_positions.erase(pos)	
	
func _update_chunk_neighbours():
	for chunk in world_loaded_chunks:
		var counter = 0
		var ref = world_loaded_chunks[chunk].get_chunk_neigbour_ref()
		for pos in ref:
			if(ref[pos] == null):
				counter + counter + 1 
		if(counter > 0):
			get_new_chunk_neighbours(chunk)
			
			
func _update_chunk_queue():			
	for pos in world_queued_chunks:
		var p:Vector3 = pos
		_add_chunk_a(p.x,p.y,p.z)	
		
func _regenerate_modified_chunk_mesh():
	for pos in world_loaded_chunks:	
		if(world_loaded_chunks[pos].is_modified == true):
			world_loaded_chunks[pos].regenerate_mesh()
			#print("regenerating " + str(pos) + " : "+ str(world_loaded_chunks[pos]))
			
func _get_available_thread():
	# Find the first unused thread from the pool
	for thread in thread_pool:
		if not thread.is_started():
			return thread
	return null  # No available threads

func _load_chunk_async(arr):
	var chunk_size = WorldHelper.chunk_size
	var x = arr[0] 
	var y = arr[1] 
	var z = arr[2]
	var key = str(x)+ "," + str(y) + "," + str(z)
	var chunk: Chunk
	
	chunk = Chunk.new(noise, x, y, z, chunk_size)
	chunk.position = Vector3(x * chunk_size , y * chunk_size, z * chunk_size)
	chunk.world_ref = self
	chunk.load_data()
	chunk.assign_chunk_neigbour_ref(get_new_chunk_neighbours(chunk))
	

	return {"position": key, "chunk": chunk}
	
	
func _on_thread_complete( _thread, chunk_tuple):
	var key = str(chunk_tuple.position)
	world_loaded_chunks[key] = chunk_tuple.chunk
	world_chunk_reference_count[key] = 0
	working_chunks[key] = 0
	# Emit signal to notify that the chunk is loaded
	emit_signal("chunk_loaded", world_loaded_chunks[key])

func _add_chunk_a(x:int, y:int, z:int):
	add_chunk(Vector3i(x,y,z))

func add_chunk(pos:Vector3i):
	var key = str(pos.x)+ "," + str(pos.y) + "," + str(pos.z)
	#check if the chunk exists aleady on this thread or on another thread being proccessed
	if world_loaded_chunks.has(key) or load_threads.has(key):
		return  # Skip already loaded or in-progress chunks.
		
	var available_thread = _get_available_thread()
	
	if available_thread:
		if(world_queued_chunks.has(pos)):
			world_queued_chunks.erase(pos)
		world_chunk_reference_count[key] = 1
		load_threads[key] = available_thread
		available_thread.start(_load_chunk_async.bind(pos))
		working_chunks[key] = 1
	elif(!world_queued_chunks.has(pos)):
		world_queued_chunks.append(pos)	

#world space
func get_chunk(pos:Vector3i):
	var key = str(pos.x) + "," + str(pos.y) + "," + str(pos.z)
	if(!world_loaded_chunks.has(key)):
		return null# Chunk not loaded
	if (load_threads.has(key)):
		return  null# chunk currently being worked on in another thread
	else:	
		return world_loaded_chunks[key]
	
#chunk space		
func get_new_chunk_neighbours(chunk: Chunk) -> Dictionary:
	var result:Dictionary = {}
	
	if(chunk != null):
		var chunk_size = WorldHelper.chunk_size
		result = chunk.get_chunk_neigbour_ref()
		var chunk_pos:Vector3i = chunk.position/chunk_size
		for d in range(6):  # 6 faces
			var offset:Vector3i = (WorldHelper.NEIGHBOR_OFFSETS[d])
			var neighbor_pos:Vector3i = chunk_pos + offset
			
			#skip updating entries for chunks that have already been indexed
			if(!result.has(neighbor_pos)):
				var neighbor_chunk:Chunk = get_chunk(neighbor_pos)
				result[neighbor_pos] = neighbor_chunk
				if(result[neighbor_pos]  != null):
					result[neighbor_pos].is_modified = true												
					var neighbour_neighbours = result[neighbor_pos].get_chunk_neigbour_ref()
					if(neighbour_neighbours.has(chunk_pos)):
						neighbour_neighbours[chunk_pos] = chunk	
						neighbour_neighbours[chunk_pos].is_modified = true					
	return result	

		
func get_current_chunk_neighbours(chunk: Chunk):
	if(chunk != null):
		return chunk.get_chunk_neigbour_ref()
	else:
		return null	
		
func _update_pos_text():
	var chunk_size = WorldHelper.chunk_size
	var player_translation = $Camera3D.position
	var player_x = int(player_translation.x)
	var player_y = int(player_translation.y)
	var player_z = int(player_translation.z)
	var pos = Vector3i(player_x,player_y,player_z)
	$Camera3D/devui/Label2.text = "x:" + str(player_x)  + " y:" + str(player_y)+ " z:" + str(player_z)
	$Camera3D/devui/Label3.text = "x:" + str(player_x/chunk_size)  + " y:" + str(player_y/chunk_size)+ " z:" + str(player_z/chunk_size)
	$Camera3D/devui/Label5.text = str(get_current_chunk_neighbours(get_chunk(pos/chunk_size)))
	$Camera3D/devui/Label7.text = "x:" + str(player_x - player_x/chunk_size*chunk_size)  + " y:" + str(player_y - player_y/chunk_size*chunk_size)+ " z:" + str(player_z - player_z/chunk_size*chunk_size)
	$Camera3D/devui/Label8.text = str(get_chunk(pos/chunk_size))
	if(get_chunk(pos/chunk_size) != null):
		$Camera3D/devui/Label10.text = str(get_chunk(pos/chunk_size).is_modified)
	else:
		$Camera3D/devui/Label10.text = "null"
	
	
func _generate_one_chunk():
	_add_chunk_a(0,0,0)
	_add_chunk_a(1,0,0)
	_add_chunk_a(0,0,1)
	_add_chunk_a(1,0,1)
	
	_add_chunk_a(0,1,0)
	_add_chunk_a(1,1,0)
	_add_chunk_a(0,1,1)
	_add_chunk_a(1,1,1)
	
	
	
func _spiral_traversal_chunk_generation(player_position, max_radius, y_level):
	"""
	Traverse chunks in a spiral pattern outward from the player's position.
	
	:param player_position: Tuple (px, py) of the player's position in chunk coordinates.
	:param max_radius: Maximum distance in chunks to render outward.
	:param z_level: Fixed z-coordinate for the chunks (default is 0).
	"""
	var directions = []
	var px = player_position.x
	var pz = player_position.z
	directions = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]

	var ax = px
	var az = pz

	var step_size = 1
	var sign = -1
	while step_size < max_radius+1:
		if(step_size % 2):
			#if step is even( should be pos)
			sign = -1
		else:
			sign = 1
			
		_add_chunk_a(ax,y_level,az)
		
		for sx in step_size:
			ax = ax + (1 * sign)
			_add_chunk_a(ax,y_level,az)
		for sz in step_size:
			az = az + (1 * sign)
			_add_chunk_a(ax,y_level,az)
		step_size = step_size + 1
