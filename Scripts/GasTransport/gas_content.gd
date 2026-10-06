class_name GasContent

extends RefCounted

var compacity : float = -1
var contents : Dictionary[GasUtils.GAS_TYPE, float] = {}

var travel_direction : Utils.DIR_BIT

func add_contents(type : GasUtils.GAS_TYPE, amount : float) -> void:
	amount = contents.get(type, 0.0) + amount
	amount = size_amount_to_compacity(amount)
	if amount <= 0: 
		return
	contents[type] = amount

func remove_contents(type: GasUtils.GAS_TYPE, amount: float) -> void:
	if !contents.has(type):
		return
	
	contents[type] -= amount
	
	if contents[type] <= 0.0:
		contents.erase(type)

func take_contents(type: GasUtils.GAS_TYPE, amount: float) -> float:
	if !contents.has(type):
		return 0
	
	var taken := minf(contents[type], amount)
	contents[type] -= taken
	
	if contents[type] <= 0.0:
		contents.erase(type)
	
	return taken

func add_container(cont : GasContent) -> void:
	for type in cont.contents.keys():
		add_contents(type, cont.contents[type])

func split_container(percentage : float = 0.50) -> GasContent:
	var cont := GasContent.new()
	cont.compacity = compacity
	
	for type in contents.keys():
		contents[type] = lerp(0.0, contents[type], percentage) 
	
	cont.contents = self.contents.duplicate()
	return cont

func transfer_container(cont : GasContent, type: GasUtils.GAS_TYPE, max : float):
	var amount : float = contents.get(type, 0.0) + cont.take_contents(type, max)
	amount = size_amount_to_compacity(amount)
	if amount <= 0.0: 
		return
	contents[type] = amount

func size_amount_to_compacity(amount : float) -> float:
	if compacity == -1: return amount
	
	var compacity := get_compacity()
	
	if amount < compacity: return amount
	var num = maxf(amount - compacity, 0)
	
	return amount - num

func get_compacity() -> float:
	if compacity == -1: return INF
	
	var cont_amount : float = 0
	for cont : float in contents.values():
		cont_amount += cont
	
	return maxf(compacity - cont_amount, 0)

func has_gas_content(type : GasUtils.GAS_TYPE) -> bool:
	return contents.has(type)

func get_gas_content(type : GasUtils.GAS_TYPE) -> float:
	return contents.get(type, 0.0)
