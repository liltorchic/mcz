extends Node3D
class_name World
#https://docs.godotengine.org/en/stable/tutorials/shaders/your_first_shader/your_first_3d_shader.html
const chunk_size := 16
var noise

var queued_chunks  = []
var loaded_chunks  = {}
var working_chunks = {}
var chunk_reference_count = {}
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

	var radius = 3

	for x in range(radius):
		for z in range(radius):
			for y in range(radius):	
				add_chunk(x-radius/2,y-radius/2,z-radius/2)

		

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
		print(position)

		
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
	var chunk:Chunk
	
		#print("generating new chunk at " + str(x)+ "," + str(y) + "," + str(z))
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
	
