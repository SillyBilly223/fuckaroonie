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
	
	if tile_object:
		networks[pipe.network_id].remove_object(pipe.tile, 
		tile_object.is_tile_input(pipe.tile))
	
	match adj_pipes.size():
		0:
			remove_network(networks[pipe.network_id])
		1:
			networks[pipe.network_id].remove_pipe(pipe)
		_:
			adj_pipes.sort_custom(GasPipe.sort_by_id)
			var main : GasPipe = adj_pipes.pop_front()
			
			networks[pipe.network_id].remove_pipe(pipe)
			
			for c_pipe : GasPipe in adj_pipes:
				disconnect_network(main.tile, main.network_id, c_pipe)

func insert_object_to_local_network(obj : GasObject):
	
	for tile : Vector2i in obj.inputs.keys():
		var pipe : GasPipe = network_pipes.get(tile)
		if pipe:
			var network : GasNetwork = networks.get(pipe.network_id)
			network.add_object(obj, tile, true)
	
	for tile : Vector2i in obj.outputs:
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
	
	for tile : Vector2i in obj.outputs:
		var pipe : GasPipe = network_pipes.get(tile)
		if pipe:
			var network : GasNetwork = networks.get(pipe.network_id)
			network.remove_object(tile, false)

func disconnect_network(main : Vector2i, net_id : int, start : GasPipe):
	
	var paths : Array[GasPipe] = [start]
	var search : Array[GasPipe] = [start]
	
	var found_main : bool = false
	var new_network : GasNetwork = null
	
	while !paths.is_empty():
		var path : GasPipe = paths.pop_front()
		
		var adj_pipes := get_adjacent_pipes(path.tile)
		for pipe : GasPipe in adj_pipes:
			if search.has(pipe): continue
			
			if pipe.tile == main: 
				found_main = true
				break
			elif pipe.network_id != net_id:
				new_network = networks[pipe.network_id]
				continue
			
			search.append(pipe)
			paths.append(pipe)
	
	if found_main:
		return
	
	if new_network == null:
		new_network = create_network()
	
	for pipe in search:
		new_network.add_pipe(pipe)

func get_adjacent_networks(tile : Vector2i) -> Array[GasNetwork]:
	var adj_networks : Array[GasNetwork] = []
	
	for dir : Vector2i in Utils.TILE_DIR:
		var pipe : GasPipe = network_pipes.get(tile + dir)
		if pipe:
			var p_network = networks[pipe.network_id]
			adj_networks.append(p_network)
	
	return adj_networks

##pipes

func add_pipe_to_tile(tile: Vector2i, rot : int, pipe : GasPipe):
	pipe.tile = tile
	pipe.restric_connects = Utils.rotation_bit_dir_restrict(rot)
	
	network_pipes[tile] = pipe
	
	set_pipe_connections(pipe)
	
	insert_pipe_to_local_network(pipe)
	
	var test := "connections: "
	for dir in Utils.DIR_BIT.values():
		if pipe.connections & dir:
			test += " " + Utils.bit_dir_to_debug(dir)
	if test ==  "connections: ": return

func remove_pipe_from_tile(pipe : GasPipe):
	remove_pipe_connections(pipe)
	
	if network_pipes.has(pipe.tile):
		network_pipes.erase(pipe.tile)
	
	remove_pipe_from_network(pipe)

func set_pipe_connections(pipe : GasPipe):
	
	for adj_pipe : GasPipe in get_adjacent_pipes(pipe.tile):
		var c_adj := Utils.get_adjacency_dir(adj_pipe.tile, pipe.tile)
		var c_pip := Utils.get_adjacency_dir(pipe.tile, adj_pipe.tile)
		
		if adj_pipe.restric_connects & c_pip or pipe.restric_connects & c_adj:
			continue
		
		adj_pipe.connections |= Utils.get_adjacency_dir(adj_pipe.tile, pipe.tile)
		pipe.connections |= Utils.get_adjacency_dir(pipe.tile, adj_pipe.tile)

func remove_pipe_connections(pipe : GasPipe):
	
	for adj_pipe : GasPipe in get_adjacent_pipes(pipe.tile):
		adj_pipe.connections &= ~Utils.get_adjacency_dir(adj_pipe.tile, pipe.tile)
		pipe.connections &= ~Utils.get_adjacency_dir(pipe.tile, adj_pipe.tile)

##Objects

func add_gas_object(tile: Vector2i, rot : int, object : GasObject):
	object.tile = tile
	object.rotation = rot
	
	insert_object_to_local_network(object)

func set_gas_object_to_tiles(object : GasObject):
	pass

func remove_gas_object_from_tiles(object : GasObject):
	pass

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

func on_simulation_tick():
	for network : GasNetwork in networks.values():
		if network.active_pipes.is_empty(): continue
		
