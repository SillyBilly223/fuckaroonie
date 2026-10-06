class_name GridUtils

const GRID_TILE_SIZE := 48
const GRID_TILE_VEC := Vector2i(GRID_TILE_SIZE,GRID_TILE_SIZE)

enum Layer {
	Gas_Pipes,
	Gas_Object,
}

static func world_to_grid(pos : Vector2) -> Vector2i:
	return Vector2i(pos.x / GRID_TILE_SIZE, pos.y / GRID_TILE_SIZE)
