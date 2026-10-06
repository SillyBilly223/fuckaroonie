class_name GOBJ_GasPipe

extends GridObject

var pipe : GasPipe

func set_to_tile(tile : Vector2i):
	super.set_to_tile(tile)
	
	pipe = GasPipe.new()
	GameManager._inst.gas_network.add_pipe_to_tile(self.tile, rotation, pipe)

func removed_from_tile():
	GameManager._inst.gas_network.remove_pipe_from_tile(pipe)
