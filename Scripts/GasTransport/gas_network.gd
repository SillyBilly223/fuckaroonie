class_name GasNetwork

extends RefCounted

var network_id : int

var pipes : Dictionary[Vector2i, GasPipe]

var object_input : Dictionary[Vector2i, GasObject]
var object_output : Dictionary[Vector2i, GasObject]

var active_pipes :  Array[GasPipe]

func _init(id : int) -> void:
	self.network_id = id

func is_active_network() -> bool:
	return active_pipes and object_input

func add_object(object : GasObject, tile : Vector2i, is_input : bool):
	if is_input:
		object_input[tile] = object
	else:
		object_output[tile] = object

func remove_object(tile : Vector2i, is_input : bool):
	if is_input:
		object_input.erase(tile)
	else:
		object_output.erase(tile)

func add_pipe(pipe : GasPipe):
	pipe.network_id = network_id
	pipes[pipe.tile] = pipe
	
	if pipe.contents:
		set_active_pipe(pipe)

func remove_pipe(pipe : GasPipe):
	pipe.network_id = network_id
	
	if pipes.has(pipe.tile):
		
		pipes.erase(pipe.tile)
		
		remove_active_pipe(pipe)

func set_active_pipe(pipe : GasPipe):
	if not active_pipes.has(pipe) and not pipe.is_empty(): active_pipes.append(pipe)

func remove_active_pipe(pipe : GasPipe):
	if active_pipes.has(pipe): active_pipes.erase(pipe)

func combine_network(a_network : GasNetwork):
	
	for pipe : GasPipe in a_network.pipes.values():
		pipe.network_id = network_id
	
	self.active_pipes + a_network.active_pipes
	
	self.pipes.merge(a_network.pipes)
	self.object_input.merge(a_network.object_input)
	self.object_output.merge(a_network.object_output)

func remove_network(a_network : GasNetwork):
	
	for pipe in a_network.pipes.keys():
		pipes.erase(pipe)

## Simulate

func simulate_objects():
	if object_input.is_empty() and object_output.is_empty(): return
	
	Simulate_PipeTransfer.simulate_network_objects(self)

func simulate_pipes():
	if active_pipes.is_empty(): return
	
	Simulate_PipeTransfer.simulate_network_pipes(self)

## Misc

static func sort_by_id(a : GasNetwork, b : GasNetwork):
	return a.network_id < b.network_id
