extends Node3D
class_name World
const chunk_size := 16
var noise

var queued_chunks  = [] #chunks that were requested but not enough threads were available, so they are placed in here
var loaded_chunks  = {} #chunks that are currently loaded in the scene	
var working_chunks = {} #chunks that are being worked on
var chunk_reference_count = {} #tracks references to chunks to allow for culling
var load_threads = {}  # Keep track of active threads.
var thread_pool = []
const max_threads := 4
var dir = DirAccess.open("user://")

# Signal to notify when a chunk is loaded
signal chunk_loaded(position: Vector3, chunk: Chunk)

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.fractal_octaves = 8
	noise.frequency = 0.01
	
	for i in range(max_threads):
		var thread = Thread.new()
		thread_pool.append(thread)

	var radius = 25


	for ay in range(2):	
				spiral_traversal($Camera3D.position, radius, ay)

		

func _process(delta):
	var finished_positions = []
	
	#run chunk code on each new thread
	for position in load_threads.keys():
		var thread:Thread = load_threads[position]
		if thread.is_started():
			var result = thread.wait_to_finish()  # Get result
		#var result1 = await chunk_loaded
			_on_thread_complete(thread, result)
			finished_positions.append(position)
		#load_threads.erase(position)
		
	#remove threads from pool
	for position in finished_positions:
		load_threads.erase(position)
		finished_positions.erase(position)
		
	for position in queued_chunks:
		var p:Vector3 = position
		add_chunk(p.x,p.y,p.z)
		
	
	update_pos_text()
		

		
func add_chunk(x,y, z):
	var key = str(x)+ "," + str(y) + "," + str(z)
	var pos:Vector3i = Vector3i(x,y,z)
	#check if the chunk exists aleady on this thread or on another thread being proccessed
	if loaded_chunks.has(key) or load_threads.has(key):
		return  # Skip already loaded or in-progress chunks.
		
	var available_thread = _get_available_thread()
	
	if available_thread:
		if(queued_chunks.has(pos)):
			queued_chunks.erase(pos)
		chunk_reference_count[key] = 1
		load_threads[key] = available_thread
		available_thread.start(_load_chunk_async.bind([x, y, z]))
		working_chunks[key] = 1
	elif(!queued_chunks.has(pos)):
		queued_chunks.append(pos)
	

func _get_available_thread():
	# Find the first unused thread from the pool
	for thread in thread_pool:
		if not thread.is_started():
			return thread
	return null  # No available threads

func _load_chunk_async(arr):
	
	var x = arr[0] 
	var y = arr[1] 
	var z = arr[2]
	var key = str(x)+ "," + str(y) + "," + str(z)
	var chunk: Chunk
	
	chunk = Chunk.new(noise, x * chunk_size, y * chunk_size,z * chunk_size, chunk_size)
	chunk.position = Vector3(x * chunk_size , y * chunk_size, z * chunk_size)
	chunk.load_data()

	return {"position": key, "chunk": chunk}
	
	
func _on_thread_complete( _thread, chunk_tuple):
	var key = str(chunk_tuple.position)
	loaded_chunks[key] = chunk_tuple.chunk
	chunk_reference_count[key] = 0
	working_chunks[key] = 0
	# Emit signal to notify that the chunk is loaded
	emit_signal("chunk_loaded", position, loaded_chunks[key])
	
func get_chunk(x, y, z):
	var key = str(x)+ "," + str(y) + "," + str(z)
	if(!loaded_chunks.has(key)):
		return null# Chunk not loaded
	if (load_threads.has(key)):
		return  null# chunk currently being worked on in another thread
		
	return loaded_chunks[key]
	
func update_pos_text():
	var player_translation = $Camera3D.position
	var player_x = int(player_translation.x)
	var player_y = int(player_translation.y)
	var player_z = int(player_translation.z)
	$Camera3D/Label2.text = "x:" + str(player_x) + " z:" + str(player_z) + " y:" + str(player_y)
	$Camera3D/Label3.text = "x:" + str(player_x/chunk_size) + " z:" + str(player_z/chunk_size) + " y:" + str(player_y/chunk_size)
	
func spiral_traversal(player_position, max_radius, y_level):
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
			
		add_chunk(ax,y_level,az)
		
		for sx in step_size:
			ax = ax + (1 * sign)
			add_chunk(ax,y_level,az)
		for sz in step_size:
			az = az + (1 * sign)
			add_chunk(ax,y_level,az)
		step_size = step_size + 1
				
		


	
