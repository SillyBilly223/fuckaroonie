class_name Gas

extends RefCounted

var type : GasUtils.GAS_TYPE

func _init(type : GasUtils.GAS_TYPE) -> void:
	self.type = type
