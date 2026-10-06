class_name GridLayer

extends RefCounted

var layer : GridUtils.Layer

var grid_tiles : Dictionary[Vector2i,int] = {}
var grid_objects : Dictionary[int,GridObject] = {}

var id_h : IDHolder = IDHolder.new()

func _init(_layer : GridUtils.Layer) -> void:
	self.layer = _layer

func is_tile_occupied(tile : Vector2i) -> bool:
	return grid_tiles.has(tile)

func add_grid_object(tile : Vector2i, obj : GridObject):
	var id : int = id_h.get_next_id()
	
	obj.grid_init(id, layer, tile)
	
	grid_objects[id] = obj
	set_object_to_tiles(obj)
	
	obj.set_to_tile(tile)

func remove_grid_object(obj : GridObject):
	obj.removed_from_tile()
	obj.grid_deinit()
	
	id_h.free_id(obj.id)
	
	grid_objects.erase(obj.id)
	remove_object_from_tiles(obj)

func set_object_to_tiles(obj : GridObject):
	for x in range(obj.size.x):
		for y in range(obj.size.y):
			var tile := obj.tile + Vector2i(x,y)
			grid_tiles[tile] = obj.id

func remove_object_from_tiles(obj : GridObject):
	for x in range(obj.size.x):
		for y in range(obj.size.y):
			var tile := obj.tile + Vector2i(x,y)
			grid_tiles.erase(tile)

func get_gobj_from_tile(tile : Vector2i) -> GridObject:
	var id : int = grid_tiles.get(tile, -1)
	return grid_objects.get(id, null)

func get_adj_objects(tile : Vector2i) -> Array[GridObject]:
	var objs : Array[GridObject] = []
	
	for dir : Vector2i in Utils.TILE_DIR:
		var d_tile := tile + dir
		if grid_tiles.has(d_tile):
			var id := grid_tiles[d_tile]
			objs.append(grid_objects[id])
	
	return objs
