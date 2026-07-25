class_name SanatoriumLayout
extends RefCounted

const MAP_SIZE := Vector2(2304.0, 1440.0)


static func rooms() -> Array[Dictionary]:
	return [
		{"id": "entrance", "name": "入口大厅", "rect": Rect2(96, 160, 320, 320)},
		{"id": "patient_wing", "name": "病房区", "rect": Rect2(480, 128, 416, 352)},
		{"id": "nurse_station", "name": "护理站", "rect": Rect2(992, 288, 384, 384)},
		{"id": "archive", "name": "实验档案室", "rect": Rect2(1696, 128, 480, 320)},
		{"id": "maintenance", "name": "地下维护区", "rect": Rect2(1504, 960, 576, 320)},
		{"id": "extraction", "name": "撤离区", "rect": Rect2(96, 1024, 352, 256)},
	]
