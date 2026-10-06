class_name GridObject
extends RefCounted

var id := -1
var layer : GridUtils.Layer = GridUtils.Layer.Gas_Pipes

var tile := Vector2i.ZERO
var size := Vector2i.ONE

var rotation : int

func grid_init(id : int, layer : GridUtils.Layer, tile : Vector2i):
	self.id = id
	self.layer = layer
	self.tile = tile

func grid_deinit():
	pass

func set_to_tile(tile : Vector2i):
	self.tile = tile

func removed_from_tile():
	pass
