extends Node2D


const BLOCKING_CELL: int = -1
var grid_width: int = 30
var grid_height: int = 20
var cell_size: int = 64
var grid: Array = []
var actions: Array = []
var cell_capacity: int = 8


func _ready() -> void:
	grid = init_arr2d(30, 20)


func init_arr2d(x: int, y: int) -> Array:
	var arr : Array = []
	for i in x:
		var tmp : Array = []
		for j in y:
			tmp.append(0)
		arr.append(tmp)
	return arr


func get_cell(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= grid_width or y >= grid_height:
		return BLOCKING_CELL
	return grid[x][y]


func _process(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var pos: Vector2 = _world_to_grid(get_viewport().get_mouse_position())
		if is_valid_pos(int(pos.x), int(pos.y)):
			grid[int(pos.x)][int(pos.y)] = cell_capacity
	tick()


func tick() -> void:
	for x in grid_width:
		for y in grid_height:
			var cell: int = grid[x][y]
			
			if cell > 0: # when cell has water
				var ncell_down: int = get_cell(x, y + 1) # go down first
				if ncell_down >= 0 and ncell_down < cell_capacity: # when down is not full
					actions.append([x, y, -1])
					actions.append([x, y + 1, 1])
					cell -= 1
					continue
				
				var ncell_left: int = get_cell(x - 1, y) # go side second
				var ncell_right: int = get_cell(x + 1, y) # go side second
				if ncell_left == -1 and ncell_right == -1: # cannot go side either
					continue

				var could_evaporate: bool = false
				if ncell_left == BLOCKING_CELL:
					if cell - ncell_right == 1:
						could_evaporate = true
				elif ncell_right == BLOCKING_CELL:
					if cell - ncell_left == 1:
						could_evaporate = true
				else:
					if cell - ncell_left == 1 or cell - ncell_right == 1:
						could_evaporate = true
				if could_evaporate and randi() % 50 == 0: # why doing this? surface vibrate
					actions.append([x, y, BLOCKING_CELL])
					continue
					
				var dx: int = 0
				if ncell_left < 0: 
					dx = 1 # go right
				elif ncell_right < 0: 
					dx = -1 # go left
				elif ncell_left == ncell_right:
					if randi() % 2 == 0:
						dx = 1
					else:
						dx = -1
				elif ncell_left > ncell_right:
					dx = 1
				else:
					dx = -1
				
				var ncell: int = get_cell(x + dx, y)
				if ncell >= cell or ncell == BLOCKING_CELL:
					continue
				
				actions.append([x, y, -1])
				actions.append([x + dx, y, 1])
				cell -= 1
				if cell <= 0:
					continue	

	for a in actions:
		var x: int = a[0]
		var y: int = a[1]
		var d: int = a[2]
		var cell_value: int = grid[x][y]
		cell_value += d
		grid[x][y] = cell_value
	
	actions.clear()
	queue_redraw()


func _world_to_grid(pos: Vector2) -> Vector2:
	return pos / float(cell_size)


func is_valid_pos(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < grid_width and y < grid_height


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			print(event.position)
			var pos: Vector2 = _world_to_grid(event.position)
			var grid_x: int = int(pos.x)
			var grid_y: int = int(pos.y)
			
			if not is_valid_pos(grid_x, grid_y):
				return
			
			if event.button_index == MOUSE_BUTTON_RIGHT:
				var v: int = BLOCKING_CELL
				if event.is_ctrl_pressed(): 
					v = 0
				grid[grid_x][grid_y] = v
			queue_redraw()
	
	elif event is InputEventKey:
		if event.is_pressed():
			tick()


func _draw() -> void:
	for x in grid_width:
		for y in grid_height:
			var cell: int = grid[x][y]
			if cell == -1:
				draw_rect(Rect2(x * cell_size, y * cell_size, cell_size, cell_size), Color("c665cfff"))
			elif cell > 0:
				var f: float = float(cell) / cell_capacity
				var col: Color = Color("4285f4ff")
				if f > 1.0:
					col.r += f - 1.0
				f = clampf(f, 0.0, 1.0)
				
				if get_cell(x, y - 1) > 0:
					f = 1.0
				
				var r: Rect2 = Rect2(x * cell_size, (float(y) + 1.0 - f) * cell_size, float(cell_size), float(cell_size) * f)
				draw_rect(r, col)
