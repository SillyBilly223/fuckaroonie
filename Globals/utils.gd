class_name Utils

const SIMULATION_TICK = 40

enum DIR_BIT {
	LEFT = 1<<0,
	UP = 1<<1,
	RIGHT = 1<<2,
	DOWN = 1<<3,
	NONE = 0
}

const TILE_DIR = [
	Vector2i.LEFT,
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN
]

static func get_adjacency(current: Vector2i, neighbor: Vector2i) -> Vector2i:
	return neighbor - current

static func get_adjacency_dir(a : Vector2i, b : Vector2i) -> DIR_BIT:
	var adj := get_adjacency(a,b)
	var index := -1
	for i in range(4):
		if TILE_DIR[i] == adj:
			index = i
			break
	
	if index == -1: return DIR_BIT.NONE
	return 1<<index as DIR_BIT

static func rotation_bit_dir_restrict(rotation : int) -> int:
	match rotation:
		1:
			return Utils.DIR_BIT.RIGHT | Utils.DIR_BIT.DOWN
		2:
			return Utils.DIR_BIT.DOWN | Utils.DIR_BIT.LEFT
		3:
			return Utils.DIR_BIT.LEFT | Utils.DIR_BIT.UP
		4:
			return Utils.DIR_BIT.UP | Utils.DIR_BIT.RIGHT
		_:
			return Utils.DIR_BIT.NONE

static func bit_dir_to_tile_dir(dir : DIR_BIT) -> Vector2i:
	match dir:
		DIR_BIT.LEFT:
			return Vector2i.LEFT
		DIR_BIT.UP:
			return Vector2i.UP
		DIR_BIT.RIGHT:
			return Vector2i.RIGHT
		DIR_BIT.DOWN:
			return Vector2i.DOWN
		_:
			return Vector2i.ZERO

static func flip_bit_dir(dir : DIR_BIT) -> DIR_BIT:
	match dir:
		DIR_BIT.LEFT:
			return DIR_BIT.RIGHT
		DIR_BIT.UP:
			return DIR_BIT.DOWN
		DIR_BIT.RIGHT:
			return DIR_BIT.LEFT
		DIR_BIT.DOWN:
			return DIR_BIT.UP
		_:
			return DIR_BIT.NONE

static func bit_dir_to_debug(dir : DIR_BIT) -> String:
	match dir:
		DIR_BIT.LEFT:
			return "<"
		DIR_BIT.UP:
			return "^"
		DIR_BIT.RIGHT:
			return ">"
		DIR_BIT.DOWN:
			return "V"
		_:
			return "x"
