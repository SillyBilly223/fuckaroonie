class_name GasUtils

enum GAS_TYPE {
	EARTH,
	AIR,
	FIRE,
	WATER,
}

static var GAS_INFO : Dictionary[GAS_TYPE, Gas] = {
	GAS_TYPE.EARTH: Gas.new(),
	GAS_TYPE.AIR: Gas.new(),
	GAS_TYPE.FIRE: Gas.new(),
	GAS_TYPE.WATER: Gas.new(),
}

static func get_gas(type : GAS_TYPE) -> Gas:
	return GAS_INFO[type]
