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
]


## Returns whether props with the given item_id can support stacked objects.
static func is_stack_support(prop_id: String) -> bool:
	var clean_id: String = prop_id.strip_edges()
	for entry in PROP_CATALOG:
		if String(entry.get("item_id", "")) == clean_id:
			return bool(entry.get("can_support_stack", true))
	return true


## Returns the total number of objects to spawn for the given 1-based level:
## 1 + level * (level - 1) / 2 -> L1=1, L2=2, L3=4, L4=7, L5=11.
static func get_total_objects(level: int) -> int:
	var clamped_level: int = maxi(1, level)
	@warning_ignore("integer_division")
	var triangle: int = (clamped_level * (clamped_level - 1)) / 2
	return 1 + triangle


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
