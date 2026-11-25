class_name Simulate_PipeTransfer

static func simulate_network_objects(network : GasNetwork):
	
	for input_pos : Vector2i in network.object_input.keys():
		var cur_pipe : GasPipe = network.pipes.get(input_pos)
		if not cur_pipe or not cur_pipe.contents:
			continue
		
		var input_object : GasObject = network.object_input[input_pos]
		var input_container : GasContent = input_object.inputs[input_pos]
		
		if cur_pipe and cur_pipe.contents:
			if pipe_to_container_transfer(cur_pipe, input_container):
				network.remove_active_pipe(cur_pipe)
	
	for output_pos : Vector2i in network.object_output.keys():
		var cur_pipe : GasPipe = network.pipes.get(output_pos)
		if not cur_pipe:
			continue
		
		var output_object : GasObject = network.object_output[output_pos]
		var output_container : GasContent = output_object.outputs.get(output_pos)
		if not output_container:
			continue
		
		var transfer_conts := output_container.split_container_by_amount(
			minf(output_object.transfer_amount, cur_pipe.compacity))
		
		if not transfer_conts or transfer_conts.is_empty():
			continue
		
		if not cur_pipe.contents:
			cur_pipe.contents = transfer_conts
		else:
			cur_pipe.contents.add_container(transfer_conts)
			
			if not transfer_conts.is_empty():
				output_container.add_container(transfer_conts)
		
		network.set_active_pipe(cur_pipe)

static func simulate_network_pipes(network : GasNetwork):
	var groups := group_network_actives(network)
	
	while not groups.is_empty():
		var stack : Array[Array] = [groups.pop_front()]
		
		while not stack.is_empty():
			var group : Array[GasPipe] = stack.back()
			var head : GasPipe = group[0]
			
			var blockers : Array[Array] = []
			if head.can_branch():
				blockers = get_branch_obstruction(network, groups, head)
			else:
				var forward = get_foward_obstruction(network, groups, head)
				if forward:
					blockers.append(forward)
			
			var pushed := false
			for blocker : Array[GasPipe] in blockers:
				if groups.has(blocker):
					groups.erase(blocker)
					stack.append(blocker)
					pushed = true
			if pushed:
				continue
			
			if head.can_branch():
				simulate_branch_group(network, group)
			else:
				simulate_group(network, group)
			stack.pop_back()

static func simulate_group(network : GasNetwork, group : Array[GasPipe]):
	for pipe in group:
		simulate_pipe(network, pipe)

static func simulate_branch_group(network : GasNetwork, group : Array[GasPipe]):
	simulate_branch_group_head(network, group[0])
	
	for i in range(1, group.size()):
		simulate_pipe(network, group[i])

static func simulate_branch_group_head(network : GasNetwork, head : GasPipe):
	
	if head.travel_direction == Utils.DIR_BIT.NONE:
		return
	
	var cur_cont := head.contents
	if not cur_cont:
		return
	
	var left_b := progress_to_pipe(network, head, head.get_left_branch())
	var right_b := progress_to_pipe(network, head, head.get_right_branch())
	
	var has_split = left_b and right_b
	
	if has_split:
		var split_cont := cur_cont.split_container(0.5, true)
		
		if left_b:
			simulate_split_pipe(network, head, split_cont, left_b)
		
		if not split_cont.is_empty():
			cur_cont.add_container(split_cont)
		
		if right_b:
			simulate_split_pipe(network, head, cur_cont, right_b)
	else:
		if left_b:
			simulate_split_pipe(network, head, cur_cont, left_b)
		elif right_b:
			simulate_split_pipe(network, head, cur_cont, right_b)
		else:
			head.stagnant = true
	
	if head.is_empty():
		head.remove_contents()
		network.remove_active_pipe(head)

static func simulate_pipe(network : GasNetwork, pipe : GasPipe):
	if pipe.travel_direction == Utils.DIR_BIT.NONE:
		return
	
	var f_pipe := get_foward_pipe(network, pipe)
	if not f_pipe:
		pipe.stagnant = true
		return
	
	var travel_dir = pipe.travel_direction
	
	if not f_pipe.can_input():
		if pipe.travel_direction == f_pipe.travel_direction:
			pipe.stagnant = true
			return
		
		if not Utils.is_opposing_dir(travel_dir, f_pipe.travel_direction):
			travel_dir = split_progress_path(pipe, f_pipe)
	
	pipe.stagnant = false
	pipe_to_pipe_transfer(network, pipe, f_pipe, travel_dir)

static func simulate_split_pipe(network : GasNetwork, head : GasPipe, 
head_conts : GasContent, split : GasPipe):
	var set_split_dir = split_progress_path(head, split)
	if Utils.is_pushing(split.travel_direction, split.tile, head.tile):
		set_split_dir = pipe_to_pipe_push(network, head, split, set_split_dir)
	
	container_to_pipe_transfer(head_conts, split, set_split_dir)
	network.set_active_pipe(split)
	head.stagnant = false

static func pipe_to_pipe_transfer(network : GasNetwork, cur_pipe : GasPipe, tran_pipe : GasPipe,
force_dir : Utils.DIR_BIT):
	var travel_dir = cur_pipe.travel_direction
	if tran_pipe.contents:
		travel_dir = pipe_to_pipe_push(network, cur_pipe, tran_pipe, force_dir)
	
	if transfer_pipe(cur_pipe, tran_pipe, travel_dir):
		network.remove_active_pipe(cur_pipe)
	network.set_active_pipe(tran_pipe)

static func pipe_to_pipe_push(network : GasNetwork, force_pipe : GasPipe, react_pipe : GasPipe,
force_dir : Utils.DIR_BIT) -> Utils.DIR_BIT:
	if force_dir != react_pipe.travel_direction:
		## figure out whos weight (total contents of all tailing pipes) outpowers the other
		##force takes priority if both are equal
		var f_weight = pipe_total_section_weight(network, force_pipe)
		var r_weight = pipe_total_section_weight(network, react_pipe)
		var force_priority = f_weight >= r_weight
		## reactivate stagnant pipes if is a non stagnant
		if react_pipe.stagnant and not force_pipe.stagnant:
			if Utils.is_opposing_dir(force_dir, react_pipe.travel_direction) and not force_priority:
				return react_pipe.travel_direction
			return force_dir 
		elif force_pipe.stagnant and not react_pipe.stagnant:
			if Utils.is_opposing_dir(force_dir, react_pipe.travel_direction) and force_priority:
				return force_dir
			return react_pipe.travel_direction 
		
		## if the force and react pipe are opposing, they will crash into eachother
		## if not the force will feed into the react
		if Utils.is_pushing(react_pipe.travel_direction, react_pipe.tile, force_pipe.tile):
			if force_priority:
				return force_dir
			else:
				return react_pipe.travel_direction 
		else:
			return react_pipe.travel_direction 
	else:
		return force_dir

static func pipe_to_container_transfer(input_p : GasPipe, cont : GasContent) -> bool:
	if not input_p.contents: return true
	if input_p.contents.is_empty(): return true
	
	cont.transfer_container(input_p.contents, -1)
	
	if input_p.is_empty():
		input_p.remove_contents()
	
	return input_p.is_empty()

static func container_to_pipe_transfer(input_cont : GasContent, tran_pipe : GasPipe,
travel_dir : Utils.DIR_BIT) -> bool:
	if input_cont.is_empty(): 
		return true
	
	if tran_pipe.contents:
		tran_pipe.contents.transfer_container(input_cont)
	else:
		var new_cont = input_cont.empty_container_to_new()
		tran_pipe.contents = new_cont
	
	tran_pipe.set_travel_dir(travel_dir)
	
	return input_cont.is_empty()

static func transfer_pipe(input_pipe : GasPipe, tran_cont : GasPipe,
travel_dir : Utils.DIR_BIT) -> bool:
	if not input_pipe.contents: return true
	
	if tran_cont.contents:
		var is_empty = pipe_to_container_transfer(input_pipe, tran_cont.contents)
		tran_cont.set_travel_dir(travel_dir)
		
		return is_empty
	else:
		tran_cont.contents = input_pipe.contents
		tran_cont.set_travel_dir(travel_dir)
		
		input_pipe.remove_contents()
		return true

static func get_foward_pipe(network : GasNetwork, pipe : GasPipe) -> GasPipe:
	var travel_dir := Utils.b_dir_to_t_dir(pipe.travel_direction)
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
	var tile_dir := Utils.b_dir_to_t_dir(travel_dir)
	
	var group : Array[GasPipe] = [head_pipe]
	var current_pipe := head_pipe
	
	var check_pipe : GasPipe = progress_to_pipe(network, head_pipe, head_pipe.travel_direction)
	if not check_pipe or not check_pipe.can_input():
		head_pipe.stagnant = true
	
	while current_pipe.connections & travel_dir:
		var tile : Vector2i = current_pipe.tile + tile_dir
		var next_pipe : GasPipe = network.pipes.get(tile)
		
		if not next_pipe or not next_pipe.contents:
			break
		if next_pipe.travel_direction != pipe.travel_direction:
			break
		if group.has(next_pipe):
			break
		
		if not current_pipe.can_input():
			next_pipe.stagnant = true
		
		group.append(next_pipe)
		current_pipe = next_pipe
	
	return group

## gets the total content of the pipe and its followers
static func pipe_total_section_weight(network : GasNetwork, head_pipe : GasPipe) -> int:
	if not head_pipe.contents: return 0
	
	var travel_dir := Utils.flip_bit_dir(head_pipe.travel_direction)
	var tile_dir := Utils.b_dir_to_t_dir(travel_dir)
	
	var visited : Array[GasPipe] = [head_pipe]
	var current_pipe := head_pipe
	
	var total := head_pipe.contents.total_contents()
	
	while current_pipe.connections & travel_dir:
		var tile : Vector2i = current_pipe.tile + tile_dir
		var next_pipe : GasPipe = network.pipes.get(tile)
		
		if not next_pipe or not next_pipe.contents:
			break
		if next_pipe.travel_direction != head_pipe.travel_direction:
			break
		if visited.has(next_pipe):
			break
		
		total += next_pipe.contents.total_contents()
		visited.append(next_pipe)
		current_pipe = next_pipe
	
	return total

static func get_head_of_flow(network : GasNetwork, pipe : GasPipe) -> GasPipe:
	var tile_dir := Utils.b_dir_to_t_dir(pipe.travel_direction)
	var current_pipe := pipe
	var visited : Array[GasPipe] = [pipe]
	
	while current_pipe.connections & pipe.travel_direction:
		var next_pipe : GasPipe = network.pipes.get(current_pipe.tile + tile_dir)
		
		if not next_pipe or not next_pipe.contents:
			break
		if next_pipe.travel_direction != pipe.travel_direction:
			break
		if visited.has(next_pipe):
			break
		
		visited.append(next_pipe)
		current_pipe = next_pipe
	
	return current_pipe

static func progress_to_pipe(network : GasNetwork, pipe : GasPipe, 
direction : Utils.DIR_BIT) -> GasPipe:
	
	if direction == Utils.DIR_BIT.NONE:
		return null
	
	var travel_dir := Utils.b_dir_to_t_dir(direction)
	return network.pipes.get(pipe.tile + travel_dir, null)

static func split_progress_path(org_pipe : GasPipe, spl_pipe : GasPipe):
	
	var temp_dir = spl_pipe.travel_direction
	var dir = Utils.get_adjacency_dir(org_pipe.tile, spl_pipe.tile)
	
	spl_pipe.travel_direction = dir
	
	if spl_pipe.connections & dir:
		spl_pipe.travel_direction = temp_dir
		return dir
	
	var l_dir = spl_pipe.get_left_branch()
	if l_dir != Utils.DIR_BIT.NONE:
		spl_pipe.travel_direction = temp_dir
		return l_dir
	
	var r_dir = spl_pipe.get_right_branch()
	if r_dir != Utils.DIR_BIT.NONE:
		spl_pipe.travel_direction = temp_dir
		return r_dir
	
	return temp_dir
