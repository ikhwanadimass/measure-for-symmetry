class_name LevelProgression
extends RefCounted

## Shared progression rules and default prop catalog for Room 2 symmetry levels.

const DEFAULT_PROP_SCALE: Vector2 = Vector2(1.5227274, 1.2794117)

const PROP_CATALOG: Array[Dictionary] = [
	{
		"item_id": "stool_01",
		"texture_path": "res://asset/tileseet/CartoonRooms/separate images/chair_front.png",
		"shape_size": Vector2(14.0, 4.0),
		"shape_offset": Vector2(0.0, 2.0),
		"room1_pos": Vector2(-146.0, -12.0),
		"can_support_stack": false,
	},
	{
		"item_id": "lamp_01",
		"texture_path": "res://asset/tileseet/CartoonRooms/separate images/lamp_big.png",
		"shape_size": Vector2(4.0, 28.0),
		"shape_offset": Vector2.ZERO,
		"room1_pos": Vector2(-124.0, -14.0),
		"can_support_stack": false,
	},
	{
		"item_id": "plant_01",
		"texture_path": "res://asset/tileseet/CartoonRooms/separate images/tree_pot_1.png",
		"shape_size": Vector2(19.0, 28.0),
		"shape_offset": Vector2(0.5, 0.0),
		"room1_pos": Vector2(-85.0, -15.0),
		"can_support_stack": false,
	},
	{
		"item_id": "table_01",
		"texture_path": "res://asset/tileseet/CartoonRooms/separate images/table_small_1.png",
		"shape_size": Vector2(30.0, 16.0),
		"shape_offset": Vector2.ZERO,
		"room1_pos": Vector2(-50.0, -9.0),
		"can_support_stack": true,
	},
	{
		"item_id": "nightstand_01",
		"texture_path": "res://asset/tileseet/CartoonRooms/separate images/night_stand_1.png",
		"shape_size": Vector2(18.0, 13.0),
		"shape_offset": Vector2.ZERO,
		"room1_pos": Vector2(-181.0, -7.0),
		"can_support_stack": true,
	},
	{
		"item_id": "chair_side_01",
		"texture_path": "res://asset/tileseet/CartoonRooms/separate images/chair_side.png",
		"shape_size": Vector2(14.0, 4.0),
		"shape_offset": Vector2(0.0, 2.0),
		"room1_pos": Vector2(-164.0, -11.0),
		"can_support_stack": false,
	},
	{
		"item_id": "dresser_small_01",
		"texture_path": "res://asset/tileseet/CartoonRooms/separate images/dresser_small_1.png",
		"shape_size": Vector2(24.0, 15.0),
		"shape_offset": Vector2.ZERO,
		"room1_pos": Vector2(-152.0, -8.0),
		"can_support_stack": true,
	},
	{
		"item_id": "table_side_01",
		"texture_path": "res://asset/tileseet/CartoonRooms/separate images/table_side_1.png",
		"shape_size": Vector2(24.0, 16.0),
		"shape_offset": Vector2.ZERO,
		"room1_pos": Vector2(-121.0, -9.0),
		"can_support_stack": true,
	},
	{
		"item_id": "bookcase_small_01",
		"texture_path": "res://asset/tileseet/CartoonRooms/separate images/bookcase_small_1.png",
		"shape_size": Vector2(24.0, 26.0),
		"shape_offset": Vector2.ZERO,
		"room1_pos": Vector2(-89.0, -14.0),
		"can_support_stack": true,
	},
	{
		"item_id": "chair_back_01",
		"texture_path": "res://asset/tileseet/CartoonRooms/separate images/chair_back.png",
		"shape_size": Vector2(14.0, 4.0),
		"shape_offset": Vector2(0.0, 2.0),
		"room1_pos": Vector2(-24.0, -26.05),
		"can_support_stack": false,
	},
	{
		"item_id": "dresser_small_02",
		"texture_path": "res://asset/tileseet/CartoonRooms/separate images/dresser_small_2.png",
		"shape_size": Vector2(24.0, 15.0),
		"shape_offset": Vector2.ZERO,
		"room1_pos": Vector2(-24.0, -8.0),
		"can_support_stack": true,
	},
	{
		"item_id": "frame_01",
		"texture_path": "res://asset/tileseet/CartoonRooms/tileset_v1.png",
		"atlas_region": Rect2(37.0, 70.0, 14.0, 13.0),
		"shape_size": Vector2(21.0, 17.0),
		"shape_offset": Vector2.ZERO,
		"room1_pos": Vector2(-152.0, -59.0),
		"can_support_stack": false,
		"is_wall_mounted": true,
	},
	{
		"item_id": "frame_02",
		"texture_path": "res://asset/tileseet/CartoonRooms/tileset_v1.png",
		"atlas_region": Rect2(53.0, 70.0, 14.0, 10.0),
		"shape_size": Vector2(21.0, 13.0),
		"shape_offset": Vector2.ZERO,
		"room1_pos": Vector2(-110.0, -40.0),
		"can_support_stack": false,
		"is_wall_mounted": true,
	},
	{
		"item_id": "frame_03",
		"texture_path": "res://asset/tileseet/CartoonRooms/tileset_v1.png",
		"atlas_region": Rect2(69.0, 70.0, 10.0, 13.0),
		"shape_size": Vector2(15.0, 17.0),
		"shape_offset": Vector2.ZERO,
		"room1_pos": Vector2(-70.0, -63.0),
		"can_support_stack": false,
		"is_wall_mounted": true,
	},
	{
		"item_id": "frame_04",
		"texture_path": "res://asset/tileseet/CartoonRooms/tileset_v1.png",
		"atlas_region": Rect2(81.0, 70.0, 8.0, 13.0),
		"shape_size": Vector2(12.0, 17.0),
		"shape_offset": Vector2.ZERO,
		"room1_pos": Vector2(-36.0, -38.0),
		"can_support_stack": false,
		"is_wall_mounted": true,
	},
	{
		"item_id": "frame_05",
		"texture_path": "res://asset/tileseet/CartoonRooms/tileset_v1.png",
		"atlas_region": Rect2(37.0, 70.0, 14.0, 13.0),
		"shape_size": Vector2(21.0, 17.0),
		"shape_offset": Vector2.ZERO,
		"room1_pos": Vector2(-130.0, -54.0),
		"can_support_stack": false,
		"is_wall_mounted": true,
	},
]

const EXTRA_STACK_SUPPORTS: Dictionary[String, bool] = {
	"desk_01": true,
	"coffe_table_01": true,
	"bookcase_small_02": true,
	"dresser_01": true,
	"bookcase_01": true,
	"couch_01": false,
}


## Returns whether props with the given item_id can support stacked objects.
static func is_stack_support(prop_id: String) -> bool:
	var clean_id: String = prop_id.strip_edges()
	if EXTRA_STACK_SUPPORTS.has(clean_id):
		return EXTRA_STACK_SUPPORTS[clean_id]
	for entry in PROP_CATALOG:
		if String(entry.get("item_id", "")) == clean_id:
			return bool(entry.get("can_support_stack", true))
	return true


## Returns whether props with the given item_id are wall-mounted (no gravity).
static func is_wall_mounted(prop_id: String) -> bool:
	var clean_id: String = prop_id.strip_edges()
	for entry in PROP_CATALOG:
		if String(entry.get("item_id", "")) == clean_id:
			return bool(entry.get("is_wall_mounted", false))
	return clean_id.begins_with("frame_")


## Loads a prop's Texture2D, slicing an AtlasTexture if atlas_region is specified.
static func load_prop_texture(def: Dictionary) -> Texture2D:
	var tex_path: String = String(def.get("texture_path", ""))
	if tex_path == "":
		return null
	var base_tex := load(tex_path) as Texture2D
	if not base_tex:
		return null
	if def.has("atlas_region"):
		var atlas := AtlasTexture.new()
		atlas.atlas = base_tex
		atlas.region = def["atlas_region"] as Rect2
		return atlas
	return base_tex


## Returns the total number of objects to spawn for the given 1-based level:
## L1=1, L2=2, L3=4, L4=7, L5=11 (furniture only)
## L6=2 (1+1), L7=3 (+1), L8=5 (+2), L9=8 (+3), L10=12 (+4) (furniture + wall frame combinations)
static func get_total_objects(level: int) -> int:
	var clamped_level: int = maxi(1, level)
	if clamped_level <= 5:
		@warning_ignore("integer_division")
		var triangle: int = (clamped_level * (clamped_level - 1)) / 2
		return 1 + triangle
	var stage_level: int = clamped_level - 5
	@warning_ignore("integer_division")
	var stage_triangle: int = (stage_level * (stage_level - 1)) / 2
	return 2 + stage_triangle


## Returns { "furniture": int, "frames": int, "total": int } for the given 1-based level.
static func get_level_composition(level: int) -> Dictionary:
	var clamped_level: int = maxi(1, level)
	var total: int = get_total_objects(clamped_level)
	if clamped_level <= 5:
		return {"furniture": total, "frames": 0, "total": total}
	match clamped_level:
		6:
			return {"furniture": 1, "frames": 1, "total": 2}
		7:
			return {"furniture": 1, "frames": 2, "total": 3}
		8:
			return {"furniture": 3, "frames": 2, "total": 5}
		9:
			return {"furniture": 4, "frames": 4, "total": 8}
		10:
			return {"furniture": 7, "frames": 5, "total": 12}
		_:
			@warning_ignore("integer_division")
			var frames: int = mini(5, maxi(1, total / 3))
			return {"furniture": total - frames, "frames": frames, "total": total}


## Returns a prop descriptor dictionary for a 0-based slot in a specific 1-based level.
static func get_prop_definition_for_level(level: int, index: int) -> Dictionary:
	var comp: Dictionary = get_level_composition(level)
	var furn_count: int = int(comp["furniture"])
	var furn_pool: Array[Dictionary] = []
	var frame_pool: Array[Dictionary] = []
	for entry in PROP_CATALOG:
		if bool(entry.get("is_wall_mounted", false)):
			frame_pool.append(entry)
		else:
			furn_pool.append(entry)

	if index < furn_count:
		if furn_pool.is_empty():
			return get_prop_definition(index)
		var base_f: int = posmod(index, furn_pool.size())
		var f_entry: Dictionary = furn_pool[base_f].duplicate()
		if index >= furn_pool.size():
			f_entry["item_id"] = "prop_%02d" % (index + 1)
		return f_entry

	var frame_slot: int = index - furn_count
	if frame_pool.is_empty():
		return get_prop_definition(index)
	var base_w: int = posmod(frame_slot, frame_pool.size())
	var w_entry: Dictionary = frame_pool[base_w].duplicate()
	if frame_slot >= frame_pool.size():
		w_entry["item_id"] = "frame_%02d" % (frame_slot + 1)
	return w_entry


## Returns the minimum passing score (75% rounded down, minimum 1):
## L1=1/1, L2=1/2, L3=3/4, L4=5/7, L5=8/11.
static func get_min_pass_score(total_objects: int) -> int:
	if total_objects <= 0:
		return 1
	return maxi(1, int(floor(float(total_objects) * 0.75)))


## Evaluates whether correct_count meets or exceeds the level pass threshold.
static func is_level_passed(correct_count: int, total_objects: int) -> bool:
	return total_objects > 0 and correct_count >= get_min_pass_score(total_objects)


## Returns a prop descriptor dictionary for a 0-based object slot index.
static func get_prop_definition(index: int) -> Dictionary:
	if index >= 0 and index < PROP_CATALOG.size():
		return PROP_CATALOG[index].duplicate()

	var base_index: int = posmod(index, PROP_CATALOG.size())
	var entry: Dictionary = PROP_CATALOG[base_index].duplicate()
	entry["item_id"] = "prop_%02d" % (index + 1)
	return entry
