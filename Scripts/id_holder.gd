class_name IDHolder

extends RefCounted

var next_id := 0
var free_ids : Array[int] = []

func get_next_id() -> int:
	if !free_ids.is_empty():
		return free_ids.pop_front()
	
	var id := next_id
	next_id += 1 
	return id

func free_id(id : int):
	free_ids.append(id)
	free_ids.sort()
