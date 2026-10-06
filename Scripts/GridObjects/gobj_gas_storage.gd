class_name GOBJ_GasStorage

extends GridObject

var gas_object : GasObject 

func set_to_tile(tile : Vector2i):
	super.set_to_tile(tile)
	
	gas_object = GasObject.new()
	GameManager._inst.gas_network.add_pipe_to_tile(self.tile, rotation, pipe)

func removed_from_tile():
	GameManager._inst.gas_network.remove_pipe_from_tile(pipe)
