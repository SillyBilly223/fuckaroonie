class_name GasPipe

extends BaseGasObject

var tile : Vector2i

var connections : int
var restric_connects : int

var contents : GasContent = null
var compacity : float = 100.0

var travel_direction : Utils.DIR_BIT
## would be a good idea to impliment this for flow smoothing
var general_flow : Utils.DIR_BIT

var stagnant : bool = false
var closed : bool = false

func can_move() -> bool:
	if travel_direction == Utils.DIR_BIT.NONE: return false
	
	if contents and connections & travel_direction:
		return true
		
	return false

func can_input() -> bool:
	return not closed and not is_full()

func can_push() -> bool:
	return not closed and contents

func can_branch() -> bool:
	if can_move(): return false
	
	var branches = connections
	
	branches &= ~travel_direction
	branches &= ~Utils.flip_bit_dir(travel_direction)
	
	return branches != 0

func accessible_to_tile(t : Vector2i) -> bool:
	var adj := Utils.get_adjacency_dir(tile, t)
	if adj == Utils.DIR_BIT.NONE: return false
	return not (restric_connects & adj)

func accessible_from_dir(dir : Utils.DIR_BIT) -> bool:
	return not (restric_connects & dir)

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

func create_content() -> GasContent:
	contents = GasContent.new(compacity)
	contents.travel_direction = travel_direction
	
	return contents

func set_travel_dir(dir : Utils.DIR_BIT):
	travel_direction = dir
	contents.travel_direction = dir

func inherit_travel_dir():
	travel_direction = contents.travel_direction

func remove_contents():
	contents = null
	travel_direction = Utils.DIR_BIT.NONE
	stagnant = false

func is_empty() -> bool:
	return contents == null or contents.is_empty()

func is_full() -> bool:
	return contents and contents.is_full()

static func sort_by_id(a : GasPipe, b : GasPipe):
	return a.network_id < b.network_id

static func sort_by_head(a : GasPipe, b : GasPipe):
	return Utils.is_ahead(a.travel_direction, a.tile, b.tile)
