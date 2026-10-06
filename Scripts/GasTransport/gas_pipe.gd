class_name GasPipe

extends BaseGasObject

var tile : Vector2i

var connections : int
var restric_connects : int

var contents : GasContent

var travel_direction : Utils.DIR_BIT
var closed : bool = false

func can_move() -> bool:
	if travel_direction == Utils.DIR_BIT.NONE: return false
	
	if contents and connections & travel_direction:
		return true
		
	return false

func can_branch() -> bool:
	if can_move(): return false
	
	var branches = connections
	
	branches &= ~travel_direction
	branches &= ~Utils.flip_bit_dir(travel_direction)
	
	return branches != 0

func get_left_branch() -> Utils.DIR_BIT:
	var dir := Utils.DIR_BIT.NONE
	
	match travel_direction:
		Utils.DIR_BIT.UP:
			dir = Utils.DIR_BIT.LEFT
		Utils.DIR_BIT.DOWN:
			dir = Utils.DIR_BIT.RIGHT
		Utils.DIR_BIT.LEFT:
			dir = Utils.DIR_BIT.DOWN
		Utils.DIR_BIT.RIGHT:
			dir = Utils.DIR_BIT.UP
	
	if not connections & dir:
		dir = Utils.DIR_BIT.NONE
	
	return dir

func get_right_branch() -> Utils.DIR_BIT:
	var dir := Utils.DIR_BIT.NONE
	
	match travel_direction:
		Utils.DIR_BIT.DOWN:
			dir = Utils.DIR_BIT.LEFT
		Utils.DIR_BIT.UP:
			dir = Utils.DIR_BIT.RIGHT
		Utils.DIR_BIT.RIGHT:
			dir = Utils.DIR_BIT.DOWN
		Utils.DIR_BIT.LEFT:
			dir = Utils.DIR_BIT.UP
	
	if not connections & dir:
		dir = Utils.DIR_BIT.NONE
	
	return dir

func transfer_contents(pipe : GasPipe):
	pass

static func sort_by_id(a : GasPipe, b : GasPipe):
	return a.network_id < b.network_id
