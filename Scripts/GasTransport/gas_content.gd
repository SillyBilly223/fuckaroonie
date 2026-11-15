class_name GasContent

extends RefCounted

var compacity : float = -1
var contents : Dictionary[GasUtils.GAS_TYPE, float] = {}
var separate_compacity = false

var contents_filter : Array[GasUtils.GAS_TYPE] = []
var filter_exclude := true

var travel_direction : Utils.DIR_BIT = Utils.DIR_BIT.NONE

func _init(_compacity : float, 
	_filter : Array[GasUtils.GAS_TYPE] = [], 
	_direction : Utils.DIR_BIT = Utils.DIR_BIT.NONE,
	_separate_compacity : bool = false, 
	_filter_exclude : bool = false) -> void:
	
	self.compacity = _compacity
	self.contents_filter = _filter
	
	self.travel_direction = _direction
	
	self.filter_exclude = _filter_exclude
	self.separate_compacity = _separate_compacity

func add_contents(type : GasUtils.GAS_TYPE, amount : float) -> void:
	if !can_add_gas(type): return
	amount = contents.get(type, 0.0) + amount
	amount = size_amount_to_compacity(amount)
	if amount <= 0: 
		return
	contents[type] = amount

func transfer_contents(cont : GasContent, type: GasUtils.GAS_TYPE, max : float) -> float:
	if !can_add_gas(type): return 0.0
	
	var current_amount = contents.get(type, 0.0)
	
	var take_amount = maxf(cont.get_gas_content(type), max)
	take_amount = size_amount_to_contents(take_amount, type)
	
	var amount : float = contents.get(type, 0.0) + cont.take_contents(type, take_amount)
	if amount <= 0.0: 
		return 0.0
	
	contents[type] = amount
	return take_amount

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

func transfer_container(cont : GasContent, max : float = -1, per_cont : bool = true) -> bool:
	for type in cont.contents.keys():
		if max < 0:
			transfer_contents(cont, type, cont.contents[type])
			continue
		
		var num = max
		if max < 0: num = cont.compacity
		num = transfer_contents(cont, type, num)
		if not per_cont: max -= num
	return is_empty()

func split_container(percentage : float = 0.50, dupe_deep := false) -> GasContent:
	percentage = clampf(percentage, 0.0, 1.0)
	var cont := duplicate_container(dupe_deep)

	for type in contents.keys():
		var moved : float = contents[type] * percentage
		contents[type] -= moved
		cont.contents[type] = moved

	return cont

func split_container_by_amount(amount : float, dupe_deep := false) -> GasContent:
	var cont := duplicate_container(dupe_deep)
	
	for type in contents.keys():
		var dif := contents[type]
		contents[type] = maxf(contents[type] - amount, 0)
		
		cont.contents[type] = dif - contents[type]
	
	return cont

func split_container_by_compacity(compacity : float, dupe_deep := false) -> GasContent:
	var cont := duplicate_container(dupe_deep)
	
	for type in contents.keys():
		var dif := contents[type]
		
		contents[type] = minf(contents[type], compacity)
		
		cont.contents[type] = dif - contents[type]
	
	return cont

func empty_container_to_new(dupe_deep := false) -> GasContent:
	var cont := duplicate_container(dupe_deep, true)
	contents.clear()
	
	return cont

func duplicate_container(dupe_deep : bool, dupe_conts := false) -> GasContent:
	var cont := GasContent.new(compacity)
	
	if not dupe_deep:
		cont.compacity = compacity
		cont.contents_filter = contents_filter.duplicate()
		cont.filter_exclude = filter_exclude
	
	if dupe_conts:
		cont.contents = self.contents.duplicate()
	
	return cont

func size_amount_to_compacity(amount : float) -> float:
	if compacity == -1: return amount
	
	var g_compacity := get_compacity()
	
	if amount < g_compacity: return amount
	var num := maxf(amount - g_compacity, 0)
	
	return amount - num

func size_amount_to_contents(amount : float, type : GasUtils.GAS_TYPE) -> float:
	if compacity == -1: return amount
	
	amount = size_amount_to_compacity(amount)
	
	var c_compacity = 0
	if separate_compacity:
		c_compacity = get_gas_content(type)
	else:
		c_compacity = total_contents()
	
	if amount < c_compacity: return amount
	var num := maxf(amount - c_compacity, 0)
	
	return amount - num

func get_compacity() -> float:
	if compacity == -1: return INF
	
	var cont_amount : float = 0
	for cont : float in contents.values():
		cont_amount += cont
	
	return maxf(compacity - cont_amount, 0)

func total_contents() -> int:
	var sum = 0
	for cont in contents.values(): sum += cont
	return sum

func is_full():
	return total_contents() >= compacity 

func can_add_gas(type : GasUtils.GAS_TYPE) -> bool:
	return contents_filter.has(type) == filter_exclude

func has_gas_content(type : GasUtils.GAS_TYPE) -> bool:
	return contents.has(type)

func get_gas_content(type : GasUtils.GAS_TYPE) -> float:
	return contents.get(type, 0.0)

func is_empty():
	for cont : float in contents.values():
		if cont > 0: return false
	return true
