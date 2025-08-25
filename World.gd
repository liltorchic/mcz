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
	$Camera3D/devui/Button.pressed.connect(self._button_pressed)
	$Camera3D/devui/Button2.pressed.connect(self._button_pressed_2)
	
	
	
	randomize()
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.fractal_octaves = 8
	noise.frequency = 0.01
	
	for i in range(WorldHelper.chunk_builder_max_threads):
		var thread = Thread.new()
		thread_pool.append(thread)
		
	

		
func _process(delta):

	_threaded_chunk_process() #run chunk code on each new thread
	_update_chunk_queue()	#add chunks waiting to be generated
	call_deferred("_update_chunk_neighbours")#update chunk neighbour dictionary
	call_deferred("_regenerate_modified_chunk_mesh")
	_update_pos_text()
	var cs = WorldHelper.chunk_size
	var player_chunk := Vector3i(
		floor($Camera3D.position.x / cs),
		floor($Camera3D.position.y / cs),
		floor($Camera3D.position.z / cs)
	)
	_spiral_traversal_chunk_generation(player_chunk, 6)  # example radius

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
				counter = counter + 1 
		if(counter > 0):
			get_new_chunk_neighbours(world_loaded_chunks[chunk])
			
			
func _update_chunk_queue():			
	for pos in world_queued_chunks:
		var p:Vector3 = pos
		_add_chunk_a(p.x,p.y,p.z)	
		
func _regenerate_modified_chunk_mesh():
	for pos in world_loaded_chunks:	
		if(world_loaded_chunks[pos].get_modified() == true):
			world_loaded_chunks[pos].regenerate_mesh()
			#print("regenerating " + str(pos) + " : "+ str(world_loaded_chunks[pos]) + " isModified: " + str(world_loaded_chunks[pos].get_modified()))
			world_loaded_chunks[pos].set_modified(false)
			
func _get_available_thread():
	# Find the first unused thread from the pool
	for thread in thread_pool:
		if not thread.is_started():
			return thread
	return null  # No available threads

func _load_chunk_async(pos: Vector3i) -> Dictionary:
	var chunk_size = WorldHelper.chunk_size
	var x = pos.x
	var y = pos.y
	var z = pos.z
	var key = "%d,%d,%d" % [x, y, z]

	var chunk := Chunk.new(noise, x, y, z, chunk_size)
	chunk.position = Vector3(x * chunk_size, y * chunk_size, z * chunk_size)
	chunk.world_ref = self
	chunk.load_data()
	chunk.assign_chunk_neigbour_ref(get_new_chunk_neighbours(chunk))
	return {"position": key, "chunk": chunk}
	
	
func _on_thread_complete( _thread, chunk_tuple):
	var key = str(chunk_tuple.position)
	print("chunk ready:", key)
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
		var callable := Callable(self, "_load_chunk_async").bind(pos)
		var err = available_thread.start(callable)
		if err != OK:
			push_error("Thread start failed (%s) for %s" % [str(err), key])
			return
		working_chunks[key] = 1
		print("adding chunk: " + key)
	elif(!world_queued_chunks.has(pos)):
		world_queued_chunks.append(pos)	

#world space
func get_chunk(pos:Vector3i) -> Chunk:
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
					result[neighbor_pos].set_modified(true)											
					var neighbour_neighbours = result[neighbor_pos].get_chunk_neigbour_ref()
					if(neighbour_neighbours.has(chunk_pos)):
						neighbour_neighbours[chunk_pos] = chunk	
						neighbour_neighbours[chunk_pos].set_modified(true)					
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
		$Camera3D/devui/Label10.text = str(get_chunk(pos/chunk_size).get_modified())
	else:
		$Camera3D/devui/Label10.text = "null"

func _button_pressed():
	var chunk_size = WorldHelper.chunk_size
	var player_translation = $Camera3D.position
	var player_x = int(player_translation.x)
	var player_y = int(player_translation.y)
	var player_z = int(player_translation.z)
	var pos = Vector3i(player_x,player_y,player_z)
	if(get_chunk(pos/chunk_size) != null):
		get_chunk(pos/chunk_size).set_modified(true)
		
		
func _button_pressed_2():
	var chunk_size = WorldHelper.chunk_size
	var player_translation = $Camera3D.position
	var player_x = int(player_translation.x)
	var player_y = int(player_translation.y)
	var player_z = int(player_translation.z)
	var pos = Vector3i(player_x,player_y,player_z)
	if(get_chunk(pos/chunk_size) != null):
		get_new_chunk_neighbours(get_chunk(pos/chunk_size))
	
# returns true when the column is "resolved" (fullish or cutoff), false if still loading
func _column_chunk_gen_chunk_coords(chunk_coords: Vector3i) -> bool:
	var working_chunk: Vector3i = chunk_coords
	var min_chunk_y := -8

	while true:
		var c := get_chunk(working_chunk)
		if c == null:
			add_chunk(working_chunk)
			return false  # queued; try again next tick

		# empty → keep going down (but stop at cutoff)
		if c.is_empty():
			working_chunk.y -= 1
			if working_chunk.y <= min_chunk_y:
				return true
			continue

		# non-empty → stop if "fullish" else step down
		if c.is_full() or c.bottom_layer_is_solid():
			return true
		else:
			working_chunk.y -= 1
			if working_chunk.y <= min_chunk_y:
				return true
	return false
	
func _spiral_traversal_chunk_generation(player_chunk: Vector3i, max_radius: int) -> void:
	var dirs = [Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0), Vector2i(0,-1)]
	var ax = player_chunk.x
	var az = player_chunk.z
	var py = player_chunk.y
	var step = 1
	var d = 0

	# (optional) include center first
	_column_chunk_gen_chunk_coords(Vector3i(ax, py, az))

	while step <= max_radius:
		for _leg in range(2):
			var dir = dirs[d % 4]
			for _i in range(step):
				ax += dir.x
				az += dir.y
				_column_chunk_gen_chunk_coords(Vector3i(ax, py, az))
			d += 1
		step += 1
