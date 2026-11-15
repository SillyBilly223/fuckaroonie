class_name GasNetworkManager

extends RefCounted

var network_pipes : Dictionary[Vector2i, GasPipe] = {}
var network_objects : Dictionary[Vector2i, GasObject] = {}

var networks : Dictionary[int, GasNetwork] = {}
var id_h : IDHolder = IDHolder.new()

##networks

func create_network() -> GasNetwork:
	var network := GasNetwork.new(id_h.get_next_id())
	networks[network.network_id] = network
	return network

func remove_network(network : GasNetwork):
	id_h.free_id(network.network_id)
	networks.erase(network.network_id)

func insert_pipe_to_local_network(pipe : GasPipe):
	var adj_networks := get_adjacent_networks(pipe.tile)
	var tile_object : GasObject = network_objects.get(pipe.tile)
	
	match adj_networks.size():
		0:
			var network = create_network()
			network.add_pipe(pipe)
		1:
			adj_networks[0].add_pipe(pipe)
		_:
			adj_networks.sort_custom(GasNetwork.sort_by_id)
			var m_network = adj_networks[0]
			m_network.add_pipe(pipe)
			
			for i in range(1, adj_networks.size()):
				if adj_networks[i].network_id == m_network.network_id:
					continue
				remove_network(adj_networks[i])
				m_network.combine_network(adj_networks[i])
	
	if tile_object:
		networks[pipe.network_id].add_object(tile_object, pipe.tile, 
		tile_object.is_tile_input(pipe.tile))

func remove_pipe_from_network(pipe : GasPipe):
	var adj_pipes := get_adjacent_pipes(pipe.tile)
	var tile_object : GasObject = network_objects.get(pipe.tile)
	
	##remove_pipe may change pipe.network_id, so keep the original
	var net_id : int = pipe.network_id
	
	if tile_object:
		networks[net_id].remove_object(pipe.tile, 
		tile_object.is_tile_input(pipe.tile))
	
	match adj_pipes.size():
		0:
			remove_network(networks[net_id])
		1:
			networks[net_id].remove_pipe(pipe)
		_:
			adj_pipes.sort_custom(GasPipe.sort_by_id)
			var main : GasPipe = adj_pipes.pop_front()
			var main_net_id : int = main.network_id
			
			networks[net_id].remove_pipe(pipe)
			
			for c_pipe : GasPipe in adj_pipes:
				##already moved to a new network by an earlier disconnect
				if c_pipe.network_id != main_net_id:
					continue
				disconnect_network(main.tile, main_net_id, c_pipe)
	
	pipe.network_id = -1

func insert_object_to_local_network(obj : GasObject):
	
	for tile : Vector2i in obj.inputs.keys():
		var pipe : GasPipe = network_pipes.get(tile)
		if pipe:
			var network : GasNetwork = networks.get(pipe.network_id)
			network.add_object(obj, tile, true)
	
	for tile : Vector2i in obj.outputs.keys():
		var pipe : GasPipe = network_pipes.get(tile)
		if pipe:
			var network : GasNetwork = networks.get(pipe.network_id)
			network.add_object(obj, tile, false)

func remove_object_from_network(obj : GasObject):
	
	for tile : Vector2i in obj.inputs.keys():
		var pipe : GasPipe = network_pipes.get(tile)
		if pipe:
			var network : GasNetwork = networks.get(pipe.network_id)
			network.remove_object(tile, true)
	
	for tile : Vector2i in obj.outputs.keys():
		var pipe : GasPipe = network_pipes.get(tile)
		if pipe:
			var network : GasNetwork = networks.get(pipe.network_id)
			network.remove_object(tile, false)
	
	remove_gas_object_from_tiles(obj)

##TODO: pipes moved into a new network here keep their objects and active
##pipe entries in the old network. Check what GasNetwork.add_pipe and
##combine_network do, and migrate them the same way.
func disconnect_network(main : Vector2i, net_id : int, start : GasPipe):
	
	var search : Array[GasPipe] = [start]
	var seen : Dictionary = {start: true}
	var new_network : GasNetwork = null
	
	var i : int = 0
	while i < search.size():
		var path : GasPipe = search[i]
		i += 1
		
		for pipe : GasPipe in get_adjacent_pipes(path.tile):
			if seen.has(pipe): continue
			
			##still connected to main, nothing to split off
			if pipe.tile == main:
				return
			
			if pipe.network_id != net_id:
				new_network = networks[pipe.network_id]
				continue
			
			seen[pipe] = true
			search.append(pipe)
	
	if new_network == null:
		new_network = create_network()
	
	for pipe in search:
		new_network.add_pipe(pipe)

func get_adjacent_networks(tile : Vector2i) -> Array[GasNetwork]:
	var adj_networks : Array[GasNetwork] = []
	
	for dir : Vector2i in Utils.TILE_DIR:
		var pipe : GasPipe = network_pipes.get(tile + dir)
		if pipe:
			var p_network : GasNetwork = networks[pipe.network_id]
			##a network touching on two sides must only be listed once,
			##otherwise it gets merged and its id freed twice
			if not adj_networks.has(p_network):
				adj_networks.append(p_network)
	
	return adj_networks

##pipes

func add_pipe_to_tile(tile: Vector2i, rot : int, pipe : GasPipe):
	##replace cleanly instead of leaving the old pipe inside its network
	var existing : GasPipe = network_pipes.get(tile)
	if existing:
		remove_pipe_from_tile(existing)
	
	pipe.tile = tile
	pipe.restric_connects = Utils.rotation_bit_dir_restrict(rot)
	
	network_pipes[tile] = pipe
	
	set_pipe_connections(pipe)
	
	insert_pipe_to_local_network(pipe)

func remove_pipe_from_tile(pipe : GasPipe):
	remove_pipe_connections(pipe)
	
	if network_pipes.has(pipe.tile):
		network_pipes.erase(pipe.tile)
	
	remove_pipe_from_network(pipe)

func set_pipe_connections(pipe : GasPipe):
	
	for adj_pipe : GasPipe in get_adjacent_pipes(pipe.tile):
		var c_adj := Utils.get_adjacency_dir(adj_pipe.tile, pipe.tile)
		var c_pip := Utils.get_adjacency_dir(pipe.tile, adj_pipe.tile)
		
		##each pipe is tested against its own side
		if adj_pipe.restric_connects & c_adj or pipe.restric_connects & c_pip:
			continue
		
		adj_pipe.connections |= c_adj
		pipe.connections |= c_pip

func remove_pipe_connections(pipe : GasPipe):
	
	for adj_pipe : GasPipe in get_adjacent_pipes(pipe.tile):
		adj_pipe.connections &= ~Utils.get_adjacency_dir(adj_pipe.tile, pipe.tile)
		pipe.connections &= ~Utils.get_adjacency_dir(pipe.tile, adj_pipe.tile)

##Objects

func add_gas_object(tile: Vector2i, rot : int, object : GasObject):
	object.tile = tile
	object.rotation = rot
	
	set_gas_object_to_tiles(object)
	insert_object_to_local_network(object)

func set_gas_object_to_tiles(object : GasObject):
	for tile : Vector2i in object.inputs.keys():
		network_objects[tile] = object
	for tile : Vector2i in object.outputs.keys():
		network_objects[tile] = object

func remove_gas_object_from_tiles(object : GasObject):
	for tile : Vector2i in object.inputs.keys():
		if network_objects.get(tile) == object:
			network_objects.erase(tile)
	for tile : Vector2i in object.outputs.keys():
		if network_objects.get(tile) == object:
			network_objects.erase(tile)

##searching

func get_adjacent_pipes(tile : Vector2i) -> Array[GasPipe]:
	var pipes : Array[GasPipe] = []
	
	for dir : Vector2i in Utils.TILE_DIR:
		var pipe : GasPipe = network_pipes.get(tile + dir)
		if pipe:
			pipes.append(pipe)
	
	return pipes

func get_adjacent_pipes_dir(tile : Vector2i) -> int:
	var bit_dir : int = 0
	
	for dir : Vector2i in Utils.TILE_DIR:
		var pipe : GasPipe = network_pipes.get(tile + dir)
		if pipe:
			bit_dir |= Utils.get_adjacency_dir(tile, pipe.tile)
	
	return bit_dir

##debug

func debug_add_gas_to_pipe(tile : Vector2i):
	var pipe : GasPipe = network_pipes.get(tile)
	if not pipe: return
	
	for dir in Utils.DIR_BIT.values():
		if pipe.connections & dir:
			pipe.travel_direction = dir
	
	pipe.create_content()
	pipe.contents.add_contents(GasUtils.GAS_TYPE.EARTH,50)
	
	if pipe.network_id == -1: return
	var net := networks[pipe.network_id]
	net.set_active_pipe(pipe)

func on_simulation_tick():
	
	for network : GasNetwork in networks.values():
		network.simulate_objects()
		
	for network : GasNetwork in networks.values():
		network.simulate_pipes()
