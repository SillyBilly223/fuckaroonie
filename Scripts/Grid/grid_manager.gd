class_name GridManager
extends Node2D

var grid_layer : Dictionary[GridUtils.Layer, GridLayer] = {}

var grid_place_rot := 0
var debug_place := 0

func _init() -> void:
	for layer in GridUtils.Layer.values():
		grid_layer[layer] = GridLayer.new(layer)

func get_layer(layer : GridUtils.Layer) -> GridLayer:
	return grid_layer[layer]

func _draw() -> void:
	var grid := get_layer(GridUtils.Layer.Gas_Pipes)
	# grid object debug
	for tile : Vector2i in grid.grid_tiles.keys():
		var gsiz := GridUtils.GRID_TILE_VEC
		draw_rect(Rect2(tile * GridUtils.GRID_TILE_SIZE, gsiz), Color.WHITE, true)
	
	#grid mouse placement
	var mtile := GridUtils.world_to_grid(get_global_mouse_position())
	var mpos := mtile * GridUtils.GRID_TILE_SIZE
	var msize :=  GridUtils.GRID_TILE_VEC
	
	var color = Color.AQUA if debug_place == 0 else Color.YELLOW
	draw_rect(Rect2(mpos.x,mpos.y,GridUtils.GRID_TILE_SIZE,GridUtils.GRID_TILE_SIZE), color, true)
	
	_pipes_debug()

func _pipes_debug():
	var mtile := GridUtils.world_to_grid(get_global_mouse_position())
	var mpos := mtile * GridUtils.GRID_TILE_SIZE
	var msize :=  GridUtils.GRID_TILE_VEC
	
	#pipe network debug
	for pipe : GasPipe in GameManager._inst.gas_network.network_pipes.values():
		
		var gsiz := GridUtils.GRID_TILE_VEC * 0.7
		var pos := pipe.tile * GridUtils.GRID_TILE_SIZE
		pos.x += 7; pos.y += 7;
		
		var color = Color.BLUE if pipe.is_empty() else Color.ORANGE
		draw_rect(Rect2(pos, gsiz), color, true)
		
		for dir in Utils.DIR_BIT.values():
			if pipe.connections & dir:
				var pivot := Utils.bit_dir_to_tile_dir(dir)
				
				draw_rect(Rect2(pos + (pivot * 7), gsiz), color, true)
		
		var font : Font = ThemeDB.fallback_font
		var pipe_text = ""
		##pipe_text = '' if not pipe.current_contents else pipe.current_contents.total_contents()
		pipe_text = Utils.bit_dir_to_debug(pipe.travel_direction)
		pipe_text += "s" if pipe.stagnant else ''
		draw_string(font, Vector2i(pos.x + 0, pos.y + 28), 
		str(pipe_text), 0, -1, 32, Color.WHITE)
	
	if debug_place == 0:
		var psiz := GridUtils.GRID_TILE_VEC * 0.7
		var p_pos := mpos
		p_pos.x += 7; p_pos.y += 7;
		
		var no_connect := Utils.rotation_bit_dir_restrict(grid_place_rot)
		var adj := GameManager._inst.gas_network.get_adjacent_pipes_dir(mtile)
		
		draw_rect(Rect2(p_pos, psiz), Color.BLUE, true)
		
		for dir in Utils.DIR_BIT.values():
			if adj & dir and (dir & no_connect != 0) :
				var pivot := Utils.bit_dir_to_tile_dir(dir)
				
				draw_rect(Rect2(p_pos + (pivot * 7), psiz), Color.BLUE, true)

func _unhandled_input(event: InputEvent) -> void:
	var is_click : bool = event is InputEventMouseButton and event.pressed
	var is_drag := event is InputEventMouseMotion and (
		Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	)
	
	var grid := get_layer(GridUtils.Layer.Gas_Pipes)
	
	if is_click and debug_place == 0:
		var tile := GridUtils.world_to_grid(event.position)
		
		if debug_place == 0:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if !grid.is_tile_occupied(tile):
					var p_obj := GOBJ_GasPipe.new()
					p_obj.rotation = grid_place_rot
					grid.add_grid_object(tile, p_obj)
			else:
				if grid.is_tile_occupied(tile):
					grid.remove_grid_object(grid.get_gobj_from_tile(tile))
		
		elif debug_place == 1:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if grid.is_tile_occupied(tile):
					GameManager._inst.gas_network.debug_add_gas_to_pipe(tile)
	elif is_drag:
		var tile := GridUtils.world_to_grid(event.position)
		if debug_place == 0:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				if !grid.is_tile_occupied(tile):
					var p_obj := GOBJ_GasPipe.new()
					p_obj.rotation = grid_place_rot
					grid.add_grid_object(tile, p_obj)
			else:
				if grid.is_tile_occupied(tile):
					grid.remove_grid_object(grid.get_gobj_from_tile(tile))
		elif debug_place == 1:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				if grid.is_tile_occupied(tile):
					GameManager._inst.gas_network.debug_add_gas_to_pipe(tile)
	
	if event is InputEventKey and event.pressed:
		if Input.is_key_pressed(KEY_R):
			grid_place_rot += 1
			
			if grid_place_rot > 4:
				grid_place_rot = 0
		
		if Input.is_key_pressed(KEY_T):
			if debug_place == 1:
				debug_place = 0
			else:
				debug_place = 1

func _process(delta: float) -> void:
	queue_redraw()
