class_name Simulate_PipeTransfer

static func simulate_network_pipes(network : GasNetwork):
	
	var groups := group_network_actives(network)
	var queue : Array[Array] = []
	
	queue.append(groups.pop_front())
	
	while !queue.is_empty():
		var group : Array[GasPipe] = queue.front()
		var head : GasPipe = group[0]
		
		if head.can_branch():
			var branches := get_branch_obstruction(network, groups, head)
			
			if !branches.is_empty():
				for branch_group : Array[GasPipe] in branches:
					queue.append(branch_group)
					groups.erase(branch_group)
				continue
			
		else:
			var forward : Array[GasPipe] = get_foward_obstruction(network, groups, head)
			
			if forward:
				queue.append(forward)
				groups.erase(forward)
				continue
			
			simulate_group(network, group)
		
		queue.erase(group)
		
		if !groups.is_empty():
			queue.append(groups.pop_front())

static func simulate_group(network : GasNetwork, group : Array[GasPipe]):
	
	for pipe in group:
		if pipe.travel_direction == Utils.DIR_BIT.NONE:
			continue
			
		var f_pipe := get_foward_pipe(network, pipe)
		
		if not f_pipe or f_pipe.closed:
			continue
		
		pipe_to_pipe_transfer(network, pipe, f_pipe)

static func simulate_branch_group(network : GasNetwork, group : Array[GasPipe]):
	simulate_branch_group_head(network, group[0])
	
	##skip head
	for i in range(1, group.size()):
		var pipe : GasPipe = group[i]
		
		if pipe.travel_direction == Utils.DIR_BIT.NONE:
			continue
			
		var f_pipe := get_foward_pipe(network, pipe)
		
		if not f_pipe or f_pipe.closed:
			continue
		
		pipe_to_pipe_transfer(network, pipe, f_pipe)

static func simulate_branch_group_head(network : GasNetwork, head : GasPipe):
	
	if head.travel_direction == Utils.DIR_BIT.NONE:
		return
	
	var left_b := progress_to_pipe(network, head, head.get_left_branch())
	var right_b := progress_to_pipe(network, head, head.get_right_branch())
	
	if left_b and not left_b.closed:
		pipe_to_pipe_transfer(network, head, left_b)
	if right_b and not right_b.closed:
		pipe_to_pipe_transfer(network, head, right_b)
	

static func pipe_to_pipe_transfer(network : GasNetwork, cur_pipe : GasPipe, tran_pipe):
	if tran_pipe.contents:
		if tran_pipe.travel_direction == cur_pipe.travel_direction:
			var f_pipe := get_foward_pipe(network, tran_pipe)
			
			if not f_pipe or f_pipe.closed:
				if transfer_pipe(cur_pipe, tran_pipe):
					network.active_pipes.erase(cur_pipe)
		else:
			tran_pipe.travel_direction = Utils.DIR_BIT.NONE
			cur_pipe.travel_direction = Utils.DIR_BIT.NONE
	else:
		if transfer_pipe(cur_pipe, tran_pipe):
			network.active_pipes.erase(cur_pipe)

static func transfer_pipe(input_p : GasPipe, cont_p : GasPipe) -> bool:
	if not input_p.contents: return true
	
	if cont_p.contents:
		cont_p.contents.add_container(input_p.contents)
		
		if input_p.contents.contents.is_empty():
			input_p.contents = null
		
		return input_p.contents == null
	else:
		cont_p.contents = input_p.contents
		input_p.contents = null
		return true

static func get_foward_pipe(network : GasNetwork, pipe : GasPipe) -> GasPipe:
	var travel_dir := Utils.bit_dir_to_tile_dir(pipe.travel_direction)
	return network.pipes.get(pipe.tile + travel_dir)

static func get_branch_obstruction(network : GasNetwork, 
groups : Array[Array], head : GasPipe) -> Array[Array]:
	var branches : Array[Array] = [] 
	
	var left_b := head.get_left_branch()
	var right_b := head.get_right_branch()
	
	if left_b != Utils.DIR_BIT.NONE:
		var left_pipe := progress_to_pipe(network, head, left_b)
		
		for group : Array[GasPipe] in groups:
			if group.has(left_pipe):
				branches.append(group)
	if right_b != Utils.DIR_BIT.NONE:
		var right_pipe := progress_to_pipe(network, head, right_b)
		
		for group : Array[GasPipe] in groups:
			if group.has(right_pipe):
				branches.append(group)
	
	return branches

static func get_foward_obstruction(network : GasNetwork, 
groups : Array[Array], head : GasPipe) -> Variant:
	var front_pipe := progress_to_pipe(network, head, head.travel_direction)
	
	if !front_pipe or !front_pipe.contents:
		return null
	
	for group : Array[GasPipe] in groups:
		if group.has(front_pipe):
			return group
	
	return null

static func group_network_actives(network : GasNetwork) -> Array[Array]:
	var groups : Array[Array] = []
	var cleared : Array[GasPipe]
	
	for pipe : GasPipe in network.active_pipes:
		if cleared.has(pipe): 
			continue
		
		var group := get_active_section(network, pipe)
		cleared.append_array(group)
		groups.append(group)
	
	return groups

static func get_active_section(network : GasNetwork, pipe : GasPipe) -> Array[GasPipe]:
	var head_pipe := get_head_of_flow(network, pipe)
	var travel_dir := Utils.flip_bit_dir(pipe.travel_direction)
	var tile_dir := Utils.bit_dir_to_tile_dir(travel_dir)
	
	var group : Array[GasPipe] = [head_pipe]
	var current_pipe := head_pipe
	
	while current_pipe.connections & travel_dir:
		var tile : Vector2i = current_pipe.tile + tile_dir
		var next_pipe : GasPipe = network.pipes.get(tile)
		
		if not next_pipe.contents:
			break
		
		if next_pipe.travel_direction == travel_dir:
			break
		
		group.append(next_pipe)
		current_pipe = next_pipe
	
	return group

static func get_head_of_flow(network : GasNetwork, pipe : GasPipe) -> GasPipe:
	var travel_dir := Utils.flip_bit_dir(pipe.travel_direction)
	var tile_dir := Utils.bit_dir_to_tile_dir(travel_dir)
	
	var current_pipe := pipe
	
	while current_pipe.connections & travel_dir:
		var tile : Vector2i = current_pipe.tile + tile_dir
		var next_pipe : GasPipe = network.pipes.get(tile)
		
		if not next_pipe.contents:
			break
		
		if next_pipe.travel_direction != travel_dir:
			break
		
		current_pipe = next_pipe
		
	
	return current_pipe

static func progress_to_pipe(network : GasNetwork, pipe : GasPipe, 
direction : Utils.DIR_BIT) -> GasPipe:
	var travel_dir := Utils.bit_dir_to_tile_dir(direction)
	return network.pipes.get(pipe.tile + travel_dir, null)
