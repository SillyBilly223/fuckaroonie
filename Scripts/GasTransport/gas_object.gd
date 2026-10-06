class_name GasObject

extends BaseGasObject

var tile := Vector2i.ZERO
var size := Vector2i.ONE

var rotation : int

var inputs : Dictionary[Vector2i,GasContent]
var outputs : Array[Vector2i]

var has_input: bool :
	get: return inputs.size() > 0

func set_to_network(tile : Vector2i, size : Vector2i, rot : int):
	self.tile = tile
	self.size = size
	self.rotation = rot

func try_input_gas_at_tile(cont : GasContent, tile : Vector2i):
	if !inputs.has(tile): return false

func is_tile_input(tile : Vector2i):
	return inputs.has(tile)
