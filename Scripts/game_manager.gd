class_name GameManager

extends Node2D

static var _inst : GameManager

@export var grid_manager : GridManager

var gas_network : GasNetworkManager
var frame_count = 0

func _init() -> void:
	if _inst:
		_inst.queue_free()
	_inst = self
	
	initilize()

func initilize():
	gas_network = GasNetworkManager.new()

func _process(delta: float) -> void:
	frame_count += 1
	
	if frame_count >= Utils.SIMULATION_TICK:
		simulation_tick()
		frame_count = 0

func simulation_tick():
	gas_network.on_simulation_tick()
	
	
