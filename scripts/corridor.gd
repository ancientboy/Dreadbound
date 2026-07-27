extends Control

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChineseFull.otf")
const CORRIDOR_FLOOR_TILE: Texture2D = preload("res://assets/art/worlds/corridor/corridor_floor_tile.png")
const CORRIDOR_TILESET: Texture2D = preload("res://assets/art/worlds/corridor/corridor_tileset.png")
const CORRIDOR_PROPS: Texture2D = preload("res://assets/art/worlds/corridor/corridor_props.png")
const CORRIDOR_HUB_ATLAS: Texture2D = preload("res://assets/art/worlds/corridor/corridor_hub_atlas.png")
const HUB_SECTION_ICONS: Texture2D = preload("res://assets/art/ui/hub_section_icons.png")
const PROGRESSION_STATUS_ICONS: Texture2D = preload("res://assets/art/ui/progression_status_icons.png")
const STORY_NPC_PORTRAITS: Texture2D = preload("res://assets/art/characters/npcs/story_npc_portraits.png")
const ARCHIVE_ILLUSTRATIONS: Texture2D = preload("res://assets/art/narrative/archive_illustrations.png")
const MILESTONE_FEEDBACK: Texture2D = preload("res://assets/art/vfx/milestone_feedback.png")
const DRIFTER_SPRITESHEET: Texture2D = preload("res://assets/art/characters/drifter/drifter_spritesheet.png")
const HIGHRES_DRIFTER_SPRITESHEET: Texture2D = preload("res://assets/art/characters/drifter/drifter_highres_spritesheet.png")
const STEADFAST_SPRITESHEET: Texture2D = preload("res://assets/art/characters/professions/steadfast_spritesheet.png")
const ARMORER_SPRITESHEET: Texture2D = preload("res://assets/art/characters/professions/armorer_spritesheet.png")
const RESONANT_SPRITESHEET: Texture2D = preload("res://assets/art/characters/professions/resonant_spritesheet.png")
const COMBAT_STYLE_SPRITESHEETS := {
	"barrier_counter": preload("res://assets/art/characters/professions/styles/barrier_counter_spritesheet.png"),
	"last_stand": preload("res://assets/art/characters/professions/styles/last_stand_spritesheet.png"),
	"sacrifice_medic": preload("res://assets/art/characters/professions/styles/sacrifice_medic_spritesheet.png"),
	"choke_control": preload("res://assets/art/characters/professions/styles/choke_control_spritesheet.png"),
	"weakpoint_sniper": preload("res://assets/art/characters/professions/styles/weakpoint_sniper_spritesheet.png"),
	"heavy_suppression": preload("res://assets/art/characters/professions/styles/heavy_suppression_spritesheet.png"),
	"demolition_traps": preload("res://assets/art/characters/professions/styles/demolition_traps_spritesheet.png"),
	"relic_engineer": preload("res://assets/art/characters/professions/styles/relic_engineer_spritesheet.png"),
	"psychic_sense": preload("res://assets/art/characters/professions/styles/psychic_sense_spritesheet.png"),
	"anomaly_ingestion": preload("res://assets/art/characters/professions/styles/anomaly_ingestion_spritesheet.png"),
	"echo_summoner": preload("res://assets/art/characters/professions/styles/echo_summoner_spritesheet.png"),
	"aberrant_form": preload("res://assets/art/characters/professions/styles/aberrant_form_spritesheet.png"),
}
const THRESHOLD_CURATOR_SPRITESHEET: Texture2D = preload("res://assets/art/characters/corridor/threshold_curator_spritesheet.png")
const EQUIPMENT_ICONS := {
	"service_crowbar": preload("res://assets/art/icons/equipment/service_crowbar.png"),
	"balanced_pistol": preload("res://assets/art/icons/equipment/balanced_pistol.png"),
	"breach_shotgun": preload("res://assets/art/icons/equipment/breach_shotgun.png"),
	"echo_edge": preload("res://assets/art/icons/equipment/echo_edge.png"),
	"medical_tag": preload("res://assets/art/icons/equipment/medical_tag.png"),
	"calming_coil": preload("res://assets/art/icons/equipment/calming_coil.png"),
	"ward_echo": preload("res://assets/art/icons/equipment/ward_echo.png"),
	"cyan_mark": preload("res://assets/art/icons/equipment/cyan_mark.png"),
	"waterproof_pulse": preload("res://assets/art/icons/equipment/waterproof_pulse.png"),
	"station_whistle": preload("res://assets/art/icons/equipment/station_whistle.png"),
	"insulated_crowbar": preload("res://assets/art/icons/equipment/insulated_crowbar.png"),
	"last_ticket": preload("res://assets/art/icons/equipment/last_ticket.png"),
	"nullpoint_sidearm": preload("res://assets/art/icons/equipment/nullpoint_sidearm.png"),
	"siege_core": preload("res://assets/art/icons/equipment/siege_core.png"),
	"volatile_edge": preload("res://assets/art/icons/equipment/volatile_edge.png"),
	"archive_lens": preload("res://assets/art/icons/equipment/archive_lens.png"),
	"linye_pass": preload("res://assets/art/icons/unique/linye_pass.png"),
	"director_reaper": preload("res://assets/art/icons/unique/director_reaper.png"),
	"conductor_railgun": preload("res://assets/art/icons/unique/conductor_railgun.png"),
}
const MATERIAL_ICONS := {
	"tissue_sample": preload("res://assets/art/icons/materials/tissue_sample.png"),
	"medical_record": preload("res://assets/art/icons/materials/medical_record.png"),
	"stitch_core": preload("res://assets/art/icons/materials/stitch_core.png"),
	"flooded_circuit": preload("res://assets/art/icons/materials/flooded_circuit.png"),
	"ticket_stub": preload("res://assets/art/icons/materials/ticket_stub.png"),
	"conductor_coil": preload("res://assets/art/icons/materials/conductor_coil.png"),
}
const UNKNOWN_EQUIPMENT_ICON: Texture2D = preload("res://assets/art/icons/ui/unknown_equipment.png")
const UNKNOWN_MATERIAL_ICON: Texture2D = preload("res://assets/art/icons/ui/unknown_material.png")

const UPGRADE_INFO := {
	"vitality": ["耐受训练", "生命上限 +10"],
	"mobility": ["神经校准", "移动速度 +8"],
	"weapons": ["武器适配", "近战 +4 / 手枪 +3"],
	"recovery": ["应急处理", "绷带恢复 +7"],
}
const PATH_BUTTONS := {
	"steadfast_guard": "SteadfastGuard", "steadfast_mender": "SteadfastMender",
	"steadfast_barrier": "SteadfastBarrier",
	"armorer_calibration": "ArmorerCalibration", "armorer_mobility": "ArmorerMobility",
	"armorer_alternation": "ArmorerAlternation",
	"resonant_sense": "ResonantSense", "resonant_bargain": "ResonantBargain",
	"resonant_ingestion": "ResonantIngestion",
}

@onready var currency: Label = $Margin/Layout/Header/Currency
@onready var report: Label = $Margin/Layout/Columns/Archive/Report
@onready var stats: Label = $Margin/Layout/Columns/Profile/Stats
@onready var feedback: Label = $Margin/Layout/Feedback
@onready var deploy_button: Button = $Margin/Layout/Actions/Deploy
@onready var world_button: Button = $Margin/Layout/Actions/SelectMetro
var warehouse_panel: ColorRect
var warehouse_scroll: ScrollContainer
var warehouse_list: GridContainer
var warehouse_status: Label
var warehouse_preview: TextureRect
var warehouse_detail_scroll: ScrollContainer
var warehouse_detail: Label
var equip_button: Button
var salvage_button: Button
var progress_button: Button
var selected_equipment_id := ""
var salvage_reward_panel: ColorRect
var salvage_reward_detail: Label
var run_archive_panel: ColorRect
var run_archive_scroll: ScrollContainer
var run_archive_detail: Label
var mirror_panel: ColorRect
var mirror_content: VBoxContainer
var open_mirror_button: Button
var walker_position := Vector2(640, 585)
var walker_velocity := Vector2.ZERO
var walker_facing := Vector2.RIGHT
var walk_phase := 0.0
var _move_touch := -1
var _touch_origin := Vector2.ZERO
var _touch_direction := Vector2.ZERO
var _hub_action_touch := -1
var mobile_terminal_panel: ColorRect
var curator_offer_box: VBoxContainer
var curator_contract_panel: ColorRect
var curator_contract_content: VBoxContainer
var audio_settings_button: Button
var audio_settings_panel: DreadboundAudioSettingsPanel
var style_buttons := {}
var hub_navigation: GridContainer
var section_panel: ColorRect
var section_title: Label
var section_content: VBoxContainer
var material_detail_icon: TextureRect
var material_detail: Label
var narrative_catalog := ContentCatalog.new()
const WALK_SPEED := 330.0
const TERMINAL_POSITION := Vector2(640, 285)
const CURATOR_POSITION := Vector2(640, 416)
const SANATORIUM_GATE_POSITION := Vector2(250, 372)
const METRO_GATE_POSITION := Vector2(1030, 372)
const INTERACTION_RANGE := 118.0
var active_gate_world := "sanatorium"
var milestone_feedback: TextureRect
var milestone_caption: Label
var _shown_heart_id := ""


func _ready() -> void:
	(get_node("/root/AudioDirector") as DreadboundAudioDirector).set_world("corridor")
	get_viewport().size_changed.connect(_apply_responsive_ui)
	GameState.progress_changed.connect(_refresh)
	for upgrade_id in UPGRADE_INFO:
		var button := get_node("Margin/Layout/Columns/Upgrades/%s" % upgrade_id.capitalize()) as Button
		button.pressed.connect(_purchase.bind(upgrade_id))
	for loadout_id in GameProgress.LOADOUTS:
		var button := get_node("Margin/Layout/Columns/Profile/Loadouts/%s" % loadout_id.capitalize()) as Button
		button.pressed.connect(_select_loadout.bind(loadout_id))
	for node_id in GameProgress.PATH_NODES:
		var button := get_node("Margin/Layout/Columns/Paths/%s" % PATH_BUTTONS[node_id]) as Button
		button.pressed.connect(_unlock_path_node.bind(node_id))
	deploy_button.pressed.connect(_deploy)
	$HubActions/Deploy.pressed.connect(_deploy_selected_gate)
	$HubActions/OpenTerminal.pressed.connect(_open_terminal)
	$Margin/Layout/Actions/CloseTerminal.pressed.connect(_close_terminal)
	$Margin/Layout/Actions/Reset.pressed.connect(_reset_progress)
	$Margin/Layout/Actions/Warehouse.pressed.connect(_open_warehouse)
	$OpenArchive.pressed.connect(_open_run_archive)
	# World selection lives at the physical legendary gates, never inside the terminal.
	world_button.visible = false
	deploy_button.visible = false
	_create_warehouse_panel()
	_create_salvage_reward_panel()
	_create_run_archive_panel()
	_create_human_mirror_panel()
	_create_mobile_terminal_panel()
	_create_curator_contract_panel()
	_create_curator_controls()
	_create_respec_control()
	_create_style_controls()
	_create_difficulty_control()
	_create_hub_navigation()
	_create_section_panel()
	_create_milestone_feedback()
	_create_audio_settings()
	_refresh()
	if GameState.pathway_migration_refund > 0:
		feedback.text = "已修复旧档中的跨职业节点，并全额返还 %d 回响碎片。当前仅保留%s路线。" % [GameState.pathway_migration_refund, GameState.get_pathway_name()]
	if not GameState.corridor_intro_seen:
		GameState.corridor_intro_seen = true
		GameState.save_progress()
		feedback.text = "终末回廊已解锁：在此查看属性、强化身体、选择整备并再次投送。"
	$HubActions.visible = false
	_apply_responsive_ui()
	if not GameState.last_run.is_empty():
		call_deferred("_open_run_archive")
	queue_redraw()


func _apply_responsive_ui(override_size := Vector2.ZERO) -> void:
	var viewport_size: Vector2 = override_size if override_size != Vector2.ZERO else get_viewport_rect().size
	var margin := $Margin as MarginContainer
	var inset := clampf(viewport_size.x * 0.025, 20.0, 42.0)
	margin.offset_left = inset
	margin.offset_right = -inset
	margin.offset_top = 20.0
	margin.offset_bottom = -20.0
	# The terminal must never become wider than its canvas.  The previous action
	# row alone requested 1232 px and caused every column to be centred offscreen.
	var compact := viewport_size.x < 1180.0
	$Margin/Layout.add_theme_constant_override("separation", 10 if compact else 18)
	$Margin/Layout/Columns.add_theme_constant_override("separation", 10 if compact else 18)
	$Margin/Layout/Actions.add_theme_constant_override("separation", 6 if compact else 18)
	var compact_column_widths := [180.0, 180.0, 210.0, 210.0]
	var columns := $Margin/Layout/Columns
	for index in range(columns.get_child_count()):
		var column := columns.get_child(index) as Control
		if column:
			var column_width: float = compact_column_widths[index] if compact else [220.0, 220.0, 280.0, 260.0][index]
			column.custom_minimum_size = Vector2(column_width, column.custom_minimum_size.y)
	for child in $Margin/Layout/Columns/Paths.get_children():
		if child is Button:
			child.custom_minimum_size.y = 40.0 if compact else 44.0
			child.add_theme_font_size_override("font_size", 12 if compact else 13)
	var compact_action_widths := [110.0, 150.0, 160.0, 190.0, 110.0]
	var normal_action_widths := [140.0, 180.0, 190.0, 260.0, 140.0]
	var actions := $Margin/Layout/Actions
	for index in range(actions.get_child_count()):
		var action := actions.get_child(index) as Button
		var action_width: float = compact_action_widths[index] if compact else normal_action_widths[index]
		action.custom_minimum_size = Vector2(action_width, action.custom_minimum_size.y)
		action.add_theme_font_size_override("font_size", 14 if compact else (20 if action.name == "Deploy" else 16))
	$Margin/Layout/Header/Title.add_theme_font_size_override("font_size", 24 if compact else 30)
	$Margin/Layout/Header/Currency.add_theme_font_size_override("font_size", 15 if compact else 18)
	$HubTitle.position = Vector2(inset, 24)
	$HubTitle.size = Vector2(maxf(260.0, viewport_size.x - inset * 2.0 - 224.0), 48)
	$OpenArchive.position = Vector2(viewport_size.x - inset - 202.0, 24)
	$OpenArchive.size = Vector2(202, 48)
	if audio_settings_button:
		audio_settings_button.position = Vector2(viewport_size.x - inset - 518.0, 24)
		audio_settings_button.size = Vector2(92, 48)
	if open_mirror_button:
		open_mirror_button.position = Vector2(viewport_size.x - inset - 414.0, 24)
		open_mirror_button.size = Vector2(202, 48)
	if mirror_panel:
		var panel_size := Vector2(minf(980.0, viewport_size.x - 32.0), minf(650.0, viewport_size.y - 32.0))
		mirror_panel.size = panel_size
		mirror_panel.position = (viewport_size - panel_size) * 0.5
		var scroll := mirror_panel.get_node("Scroll") as ScrollContainer
		scroll.position = Vector2(28, 82)
		scroll.size = Vector2(panel_size.x - 56, panel_size.y - 150)
		mirror_content.custom_minimum_size.x = panel_size.x - 84
		var close := mirror_panel.get_node("Close") as Button
		close.position = Vector2(panel_size.x - 150, panel_size.y - 56)
	_layout_warehouse(viewport_size)
	_layout_salvage_reward(viewport_size)
	_layout_run_archive(viewport_size)
	_layout_curator_contract_panel(viewport_size)
	_layout_hub_navigation(viewport_size)
	_layout_section_panel(viewport_size)
	queue_redraw()


func _layout_hub_navigation(viewport_size: Vector2) -> void:
	if hub_navigation == null:
		return
	var portrait := viewport_size.x < 720.0
	hub_navigation.columns = 4 if portrait else 8
	hub_navigation.position = Vector2(12, viewport_size.y - (104 if portrait else 58))
	hub_navigation.size = Vector2(viewport_size.x - 24, 92 if portrait else 48)
	for button in hub_navigation.get_children():
		if button is Button:
			button.custom_minimum_size = Vector2(0, 42)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _layout_section_panel(viewport_size: Vector2) -> void:
	if section_panel == null:
		return
	var panel_size := Vector2(minf(920.0, viewport_size.x - 28.0), minf(620.0, viewport_size.y - 126.0))
	section_panel.size = panel_size
	section_panel.position = Vector2((viewport_size.x - panel_size.x) * 0.5, maxf(18.0, (viewport_size.y - panel_size.y) * 0.42))
	section_title.position = Vector2(24, 18)
	section_title.size = Vector2(panel_size.x - 48, 42)
	var scroll := section_panel.get_node("Scroll") as ScrollContainer
	scroll.position = Vector2(24, 70)
	scroll.size = Vector2(panel_size.x - 48, panel_size.y - 138)
	section_content.custom_minimum_size = Vector2(panel_size.x - 76, 0)
	var close := section_panel.get_node("Close") as Button
	close.position = Vector2((panel_size.x - 220) * 0.5, panel_size.y - 58)
	close.size = Vector2(220, 44)


func _layout_warehouse(viewport_size: Vector2) -> void:
	if warehouse_panel == null:
		return
	var panel_width := minf(1050.0, viewport_size.x - 48.0)
	var panel_height := minf(590.0, viewport_size.y - 32.0)
	warehouse_panel.position = Vector2((viewport_size.x - panel_width) * 0.5, (viewport_size.y - panel_height) * 0.5)
	warehouse_panel.size = Vector2(panel_width, panel_height)
	var title := warehouse_panel.get_child(0) as Label
	title.position = Vector2(24, 18)
	title.size = Vector2(panel_width - 48, 48)
	var list_width := minf(590.0, panel_width * 0.58)
	warehouse_status.position = Vector2(28, 70)
	warehouse_status.size = Vector2(list_width, 42)
	var scroll := warehouse_scroll
	scroll.position = Vector2(28, 112)
	scroll.size = Vector2(list_width, warehouse_panel.size.y - 192)
	var card_width := 112.0
	warehouse_list.columns = maxi(2, floori((list_width - 22.0) / card_width))
	warehouse_list.custom_minimum_size = Vector2(list_width - 20, 0)
	var detail_x := 52 + list_width
	var detail_width := panel_width - detail_x - 26
	warehouse_preview.position = Vector2(detail_x, 88)
	warehouse_preview.size = Vector2(112, 112)
	warehouse_detail_scroll.position = Vector2(detail_x, 212)
	warehouse_detail_scroll.size = Vector2(detail_width, maxf(54.0, panel_height - 366.0))
	warehouse_detail.custom_minimum_size = Vector2(maxf(80.0, detail_width - 18.0), 0)
	warehouse_detail.size = Vector2(maxf(80.0, detail_width - 18.0), 0)
	equip_button.position = Vector2(detail_x, warehouse_panel.size.y - 138)
	equip_button.size = Vector2((detail_width - 20) / 3.0, 52)
	progress_button.position = Vector2(detail_x + equip_button.size.x + 10, warehouse_panel.size.y - 138)
	progress_button.size = equip_button.size
	salvage_button.position = Vector2(detail_x + (equip_button.size.x + 10) * 2.0, warehouse_panel.size.y - 138)
	salvage_button.size = equip_button.size
	var close := warehouse_panel.get_node("ReturnWarehouse") as Button
	close.position = Vector2((panel_width - 250) * 0.5, warehouse_panel.size.y - 72)
	close.size = Vector2(250, 52)


func _layout_salvage_reward(viewport_size: Vector2) -> void:
	if salvage_reward_panel == null:
		return
	var panel_width := minf(560.0, viewport_size.x - 48.0)
	var panel_height := minf(370.0, viewport_size.y - 72.0)
	salvage_reward_panel.position = Vector2((viewport_size.x - panel_width) * 0.5, (viewport_size.y - panel_height) * 0.5)
	salvage_reward_panel.size = Vector2(panel_width, panel_height)
	var title := salvage_reward_panel.get_child(0) as Label
	title.position = Vector2(28, 26)
	title.size = Vector2(panel_width - 56, 42)
	salvage_reward_detail.position = Vector2(42, 98)
	salvage_reward_detail.size = Vector2(panel_width - 84, panel_height - 190)
	var close := salvage_reward_panel.get_child(salvage_reward_panel.get_child_count() - 1) as Button
	close.position = Vector2((panel_width - 230) * 0.5, panel_height - 76)
	close.size = Vector2(230, 48)


func _layout_run_archive(viewport_size: Vector2) -> void:
	if run_archive_panel == null:
		return
	var panel_width := minf(820.0, viewport_size.x - 32.0)
	var panel_height := minf(650.0, viewport_size.y - 36.0)
	run_archive_panel.position = Vector2((viewport_size.x - panel_width) * 0.5, (viewport_size.y - panel_height) * 0.5)
	run_archive_panel.size = Vector2(panel_width, panel_height)
	var title := run_archive_panel.get_node("Title") as Label
	title.position = Vector2(24, 18)
	title.size = Vector2(panel_width - 48, 44)
	run_archive_scroll.position = Vector2(28, 76)
	run_archive_scroll.size = Vector2(panel_width - 56, panel_height - 154)
	run_archive_detail.custom_minimum_size = Vector2(panel_width - 82, 0)
	var close := run_archive_panel.get_node("Close") as Button
	close.position = Vector2((panel_width - 230) * 0.5, panel_height - 66)
	close.size = Vector2(230, 48)


func _layout_curator_contract_panel(viewport_size: Vector2) -> void:
	if curator_contract_panel == null:
		return
	# This panel is opened from the Curator, not from the terminal.  Reserve a
	# clear bottom inset even if a caller forgets to hide navigation.
	var panel_size := Vector2(minf(680.0, viewport_size.x - 32.0), minf(540.0, viewport_size.y - 64.0))
	curator_contract_panel.size = panel_size
	curator_contract_panel.position = Vector2((viewport_size.x - panel_size.x) * 0.5, maxf(20.0, (viewport_size.y - panel_size.y) * 0.42))
	var title := curator_contract_panel.get_node("Title") as Label
	title.position = Vector2(24, 18)
	title.size = Vector2(panel_size.x - 48, 40)
	var hint := curator_contract_panel.get_node("Hint") as Label
	hint.position = Vector2(28, 62)
	hint.size = Vector2(panel_size.x - 56, 40)
	var scroll := curator_contract_panel.get_node("Scroll") as ScrollContainer
	scroll.position = Vector2(24, 108)
	scroll.size = Vector2(panel_size.x - 48, panel_size.y - 174)
	curator_contract_content.custom_minimum_size = Vector2(panel_size.x - 76, 0)
	var close := curator_contract_panel.get_node("Close") as Button
	close.position = Vector2((panel_size.x - 220) * 0.5, panel_size.y - 56)
	close.size = Vector2(220, 42)


func _process(delta: float) -> void:
	if _terminal_is_open() or warehouse_panel.visible or run_archive_panel.visible or (mirror_panel and mirror_panel.visible) or (section_panel and section_panel.visible) or (curator_contract_panel and curator_contract_panel.visible):
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _move_touch != -1:
		direction = _touch_direction
	walker_velocity = direction * WALK_SPEED
	if direction.length() > 0.08:
		walker_position += walker_velocity * delta
		walker_position.x = clampf(walker_position.x, 115.0, size.x - 115.0)
		walker_position.y = clampf(walker_position.y, 165.0, size.y - 95.0)
		walker_facing = direction.normalized()
		walk_phase += delta * 13.0
		queue_redraw()
	var target := _nearby_target()
	_update_hub_actions(target)
	if Input.is_action_just_pressed("interact") and not target.is_empty():
		_activate_target(target.id)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _close_top_surface():
			get_viewport().set_input_as_handled()
			return
	if _terminal_is_open() or (warehouse_panel and warehouse_panel.visible) or (run_archive_panel and run_archive_panel.visible) or (mirror_panel and mirror_panel.visible) or (section_panel and section_panel.visible) or (curator_contract_panel and curator_contract_panel.visible):
		return
	if event is InputEventScreenTouch:
		if event.pressed and event.position.distance_to(_hub_action_center()) <= 76.0:
			_hub_action_touch = event.index
			var target := _nearby_target()
			if not target.is_empty():
				_activate_target(target.id)
			queue_redraw()
		elif event.pressed and event.position.x < size.x * 0.55:
			_move_touch = event.index
			_touch_origin = event.position
			_touch_direction = Vector2.ZERO
		elif not event.pressed and event.index == _move_touch:
			_move_touch = -1
			_touch_direction = Vector2.ZERO
			queue_redraw()
		elif not event.pressed and event.index == _hub_action_touch:
			_hub_action_touch = -1
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == _move_touch:
		_touch_direction = (event.position - _touch_origin).limit_length(92.0) / 92.0
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var target := _nearby_target()
		if not target.is_empty() and event.position.distance_to(walker_position) < 170.0:
			_activate_target(target.id)


func _nearby_target() -> Dictionary:
	var targets := [
		{"id": "curator", "position": CURATOR_POSITION, "prompt": "与阈值司仪同步行动档案"},
		{"id": "terminal", "position": TERMINAL_POSITION, "prompt": "接入行者整备终端"},
		{"id": "sanatorium_gate", "position": SANATORIUM_GATE_POSITION, "prompt": "进入废弃疗养院", "world": "sanatorium"},
		{"id": "metro_gate", "position": METRO_GATE_POSITION, "prompt": "进入潮没末班线", "world": "metro"},
	]
	for target in targets:
		if walker_position.distance_to(target.position) <= INTERACTION_RANGE:
			return target
	return {}


func _activate_target(id: String) -> void:
	match id:
		"curator":
			_open_curator_contract_panel()
		"terminal": _open_terminal()
		"sanatorium_gate": _deploy_world("sanatorium")
		"metro_gate": _deploy_world("metro")


func _update_hub_actions(target: Dictionary) -> void:
	var has_target: bool = not target.is_empty() and target.id != "curator"
	$HubActions.visible = has_target
	if not has_target:
		return
	var is_gate := str(target.id).ends_with("_gate")
	$HubActions/OpenTerminal.visible = not is_gate
	$HubActions/Deploy.visible = is_gate
	if is_gate:
		active_gate_world = str(target.world)
		$HubActions/Deploy.text = str(target.prompt)


func _refresh() -> void:
	currency.text = "回响 %d · 因果 %d · 合成余烬 %d" % [GameState.echo_shards, GameState.causality_fragments, GameState.synthesis_embers]
	var values := GameState.get_player_stats()
	stats.text = "生命上限       %d\n移动速度       %d\n近战伤害       %d\n手枪伤害       %d\n绷带恢复       %d" % [values.max_health, int(values.movement_speed), values.melee_damage, values.ranged_damage, values.bandage_heal]
	for upgrade_id in UPGRADE_INFO:
		var button := get_node("Margin/Layout/Columns/Upgrades/%s" % upgrade_id.capitalize()) as Button
		var level := int(GameState.upgrades[upgrade_id])
		var cost := GameState.get_upgrade_cost(upgrade_id)
		var maximum := GameState.get_upgrade_max_level(upgrade_id)
		button.text = "%s  Lv.%d/%d\n%s%s" % [UPGRADE_INFO[upgrade_id][0], level, maximum, UPGRADE_INFO[upgrade_id][1], "  ·  %d 碎片" % cost if cost > 0 else "  ·  已满级"]
		button.disabled = cost == 0 or GameState.echo_shards < cost
	for loadout_id in GameProgress.LOADOUTS:
		var loadout: Dictionary = GameProgress.LOADOUTS[loadout_id]
		var button := get_node("Margin/Layout/Columns/Profile/Loadouts/%s" % loadout_id.capitalize()) as Button
		button.text = "%s%s\n%s" % ["▶ " if GameState.selected_loadout == loadout_id else "", loadout.name, loadout.description]
	for node_id in GameProgress.PATH_NODES:
		var node: Dictionary = GameProgress.PATH_NODES[node_id]
		var path_name: String = GameProgress.PATHWAY_NAMES.get(str(node.path), "未知途径")
		var button := get_node("Margin/Layout/Columns/Paths/%s" % PATH_BUTTONS[node_id]) as Button
		var unlocked := GameState.unlocked_path_nodes.has(node_id)
		var anchor_needed := GameState.selected_pathway.is_empty()
		var locked_path := not GameState.selected_pathway.is_empty() and GameState.selected_pathway != str(node.path)
		var missing_requirement := not str(node.get("requires", "")).is_empty() and not GameState.unlocked_path_nodes.has(str(node.requires))
		button.visible = (str(node.get("requires", "")).is_empty() if GameState.selected_pathway.is_empty() else str(node.path) == GameState.selected_pathway)
		var anchor_text := "锚定 %s：%d 碎片 + %d 因果残片\n" % [path_name, int(GameProgress.PATHWAY_ANCHOR_COST.echo_shards), int(GameProgress.PATHWAY_ANCHOR_COST.causality_fragments)] if anchor_needed else ""
		button.text = "%s%s\n%s" % ["✓ " if unlocked else "%s · " % path_name, str(node.name), "已锚定" if unlocked else anchor_text + ("前置节点未锚定" if missing_requirement else ("已选择%s" % GameState.get_pathway_name() if locked_path else "%s · %d 碎片" % [str(node.description), int(node.cost)]))]
		button.disabled = unlocked or locked_path or missing_requirement or GameState.echo_shards < int(node.cost) + (int(GameProgress.PATHWAY_ANCHOR_COST.echo_shards) if anchor_needed else 0) or GameState.causality_fragments < int(node.get("fragment_cost", 0)) + (int(GameProgress.PATHWAY_ANCHOR_COST.causality_fragments) if anchor_needed else 0)
	for style_id in style_buttons:
		var style: Dictionary = ExchangeEvolution.COMBAT_STYLES[style_id]
		var style_button: Button = style_buttons[style_id]
		var available_path := str(style.path) == GameState.selected_pathway
		style_button.visible = available_path
		if available_path:
			var unlocked := GameState.unlocked_combat_styles.has(style_id)
			style_button.text = "%s%s\n%s" % ["▶ " if GameState.active_combat_style == style_id else ("✓ " if unlocked else ""), str(style.name), "点击切换流派" if unlocked else "%s · 5 回响" % str(style.description)]
			style_button.disabled = not unlocked and (not GameState.has_path_node(str(style.requires)) or GameState.echo_shards < 5)
	var respec := get_node_or_null("Margin/Layout/Columns/Paths/RespecPathway") as Button
	if respec:
		respec.text = "重构职业 · 1 因果残片（可无限次）"
		respec.disabled = GameState.selected_pathway.is_empty()
	var difficulty_button := get_node_or_null("Margin/Layout/Columns/Profile/DifficultySelector") as Button
	if difficulty_button:
		var difficulty := GameState.get_difficulty()
		difficulty_button.text = "副本难度：%s\n%s" % [str(difficulty.name), str(difficulty.description)]
	world_button.text = "传说门选择副本"
	deploy_button.text = "请在回廊进入传说门"
	$HubActions/Deploy.text = "进入%s" % _world_name()
	_refresh_curator_offers()
	if GameState.last_run.is_empty():
		report.text = "尚无行动记录。\n疗养院连接等待校准。"
	else:
		var run: Dictionary = GameState.last_run
		var gear_count: int = run.get("equipment_rewards", []).size()
		var dynamic: Dictionary = run.get("dynamic_run", {})
		var milestones: Array = run.get("milestone_rewards", [])
		var milestone_text := ""
		for reward in milestones:
			milestone_text += "\n因果里程碑  +%d %s" % [int(reward.get("causality_fragments", 0)), str(reward.get("title", ""))]
		for reward in run.get("trial_rewards", []):
			milestone_text += "\n司仪试炼  +%d 因果残片 · %s" % [int(reward.get("causality_fragments", 0)), str(reward.get("title", ""))]
		report.text = "%s\n行动代码  %s\n任务契约  %s\n目标完成  %d\n风险事件  %d/2\n现场碎片  %d\n装备回收  %d\n清除威胁  %d%s\n\n司仪观察：%s\n%s" % ["撤离成功" if run.success else "行动失败", dynamic.get("action_code", "旧版行动"), dynamic.get("mission", "档案回收"), run.records, run.get("events_resolved", 0), run.carried_shards, gear_count, run.enemies_defeated, milestone_text, str(GameState.player_profile.get("last_observation", "尚无足够行动数据。")), _humanity_summary()]
	queue_redraw()
	if mobile_terminal_panel and mobile_terminal_panel.visible:
		_refresh_mobile_terminal()
	var heart_id := str(GameState.heart_aspect.get("id", ""))
	if not heart_id.is_empty() and heart_id != _shown_heart_id:
		_shown_heart_id = heart_id
		call_deferred("_show_milestone", 3, str(GameState.heart_aspect.get("name", "心相形成")))


func _purchase(upgrade_id: String) -> void:
	feedback.text = "%s已完成，下一次投送生效。" % UPGRADE_INFO[upgrade_id][0] if GameState.purchase_upgrade(upgrade_id) else "资源不足或该强化已达到上限。"


func _select_loadout(loadout_id: String) -> void:
	if GameState.select_loadout(loadout_id):
		feedback.text = "已选择%s，下一次投送携带该配置。" % GameProgress.LOADOUTS[loadout_id].name


func _unlock_path_node(node_id: String) -> void:
	var node: Dictionary = GameProgress.PATH_NODES[node_id]
	var first_anchor := GameState.selected_pathway.is_empty()
	var success := GameState.unlock_path_node(node_id)
	feedback.text = "%s已锚定：%s" % [str(node.name), str(node.description)] if success else "无法锚定：需先选择该职业、满足前置节点，并支付回响碎片与首次锚定的因果残片。"
	if success and first_anchor:
		_show_milestone(1, "%s已锚定" % GameState.get_pathway_name())


func _create_style_controls() -> void:
	var parent := $Margin/Layout/Columns/Paths as VBoxContainer
	var title := Label.new()
	title.text = "战斗流派 · 12"
	title.add_theme_color_override("font_color", Color("6cd7c0"))
	parent.add_child(title)
	for style_id in ExchangeEvolution.COMBAT_STYLES:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 48)
		button.visible = false
		button.pressed.connect(_toggle_combat_style.bind(style_id))
		parent.add_child(button)
		style_buttons[style_id] = button


func _toggle_combat_style(style_id: String) -> void:
	var newly_unlocked := not GameState.unlocked_combat_styles.has(style_id)
	var success := GameState.select_combat_style(style_id) if GameState.unlocked_combat_styles.has(style_id) else GameState.unlock_combat_style(style_id)
	feedback.text = "当前流派：%s。" % str(ExchangeEvolution.COMBAT_STYLES[style_id].name) if success else "无法启用流派：需完成职业核心节点并支付 5 回响。"
	if success and newly_unlocked:
		_show_milestone(2, "流派解锁 · %s" % str(ExchangeEvolution.COMBAT_STYLES[style_id].name))
	_refresh()


func _deploy() -> void:
	_deploy_world(GameState.selected_world)


func _deploy_selected_gate() -> void:
	_deploy_world(active_gate_world)


func _deploy_world(world: String) -> void:
	GameState.selected_world = world
	GameState.save_progress()
	deploy_button.disabled = true
	feedback.text = "正在建立%s连接……" % _world_name()
	GameState.begin_run()
	get_tree().change_scene_to_file("res://scenes/metro.tscn" if GameState.selected_world == "metro" else "res://scenes/main.tscn")


func _toggle_world() -> void:
	# Kept as a safe no-op for old saves. Legendary gates own world selection now.
	feedback.text = "请返回回廊，靠近对应传说门进入副本。"


func _world_name() -> String:
	return "潮没末班线" if GameState.selected_world == "metro" else "废弃疗养院"


func _reset_progress() -> void:
	GameState.reset_progress()
	feedback.text = "局外进度已清除。"


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("071311"))
	draw_texture_rect(CORRIDOR_FLOOR_TILE, Rect2(0, 112, size.x, size.y - 112), true, Color(0.42, 0.55, 0.52, 0.34))
	# Build the chamber from atlas modules. The old polygon-and-line graybox is
	# retained only as a dark underlay so every visible architectural edge now
	# comes from the corridor art set.
	if CORRIDOR_TILESET != null and CORRIDOR_TILESET.get_size() == Vector2(256, 256):
		for x in range(0, int(size.x) + 32, 32):
			var tile_column := floori(float(x) / 32.0) % 8
			draw_texture_rect_region(
				CORRIDOR_TILESET,
				Rect2(x, 112, 32, 32),
				Rect2(tile_column * 32, 0, 32, 32),
				Color(0.72, 0.78, 0.76, 1.0)
			)
	for y in range(196, int(size.y) - 80, 124):
		for x in range(116, int(size.x) - 80, 124):
			_draw_hub_asset(0, Vector2(x, y), 132.0, Color(0.58, 0.67, 0.64, 0.5))
	for x in range(128, int(size.x), 230):
		_draw_hub_asset(1, Vector2(x, 164), 192.0, Color(0.76, 0.81, 0.78, 0.92))
	_draw_hub_asset(3, Vector2(size.x - 150, size.y - 192), 192.0, Color(0.72, 0.82, 0.78, 0.9))
	_draw_hub_asset(4, Vector2(150, size.y - 192), 192.0, Color(0.72, 0.82, 0.78, 0.9))
	_draw_hub_asset(5, Vector2(160, 270), 128.0)
	_draw_hub_asset(11, Vector2(size.x - 156, 270), 128.0)
	_draw_hub_asset(6, Vector2(size.x * 0.5, size.y - 126), 128.0, Color(0.64, 0.72, 0.69, 0.74))
	# Archive terminal and Curator dais.
	draw_circle(TERMINAL_POSITION, 88, Color(0.08, 0.34, 0.29, 0.2))
	_draw_hub_asset(10, TERMINAL_POSITION, 150.0)
	draw_circle(CURATOR_POSITION, 56, Color(0.23, 0.77, 0.67, 0.14))
	_draw_hub_asset(7, CURATOR_POSITION + Vector2(0, 24), 142.0, Color(0.88, 0.93, 0.9, 0.96))
	_draw_threshold_curator()
	# Each unlocked disaster world has a permanent, visible legendary gate.
	_draw_legend_gate(SANATORIUM_GATE_POSITION, Color("5ce8cf"), "废弃疗养院", "医疗异化 · 供电撤离", 8)
	_draw_legend_gate(METRO_GATE_POSITION, Color("6098f5"), "潮没末班线", "涨潮迷失 · 末班撤离", 9)
	# The same O1 review slice is used in the hub and mission.
	var bob := sin(walk_phase) * 3.0 if walker_velocity.length() > 2.0 else sin(Time.get_ticks_msec() * 0.002) * 1.2
	var walker_row := 0
	if absf(walker_facing.x) > absf(walker_facing.y):
		walker_row = 2 if walker_facing.x > 0.0 else 1
	elif walker_facing.y < 0.0:
		walker_row = 3
	var walker_frame := int(walk_phase / TAU * 6.0) % 6 if walker_velocity.length() > 2.0 else 0
	var walker_spritesheet := _walker_body_texture()
	if walker_spritesheet != null and walker_spritesheet.get_size() == Vector2(1536, 1024):
		# Keep the feet pinned to the same hub position as the legacy 48×64 sprite.
		# The larger destination rect preserves the high-detail silhouette instead
		# of downsampling it into a pseudo-pixel character.
		draw_texture_rect_region(
			walker_spritesheet,
			Rect2(walker_position + Vector2(-70, -132 + bob), Vector2(140, 140)),
			Rect2(walker_frame * 256, walker_row * 256, 256, 256)
		)
	elif walker_spritesheet != null and walker_spritesheet.get_size() == Vector2(288, 256):
		draw_texture_rect_region(
			walker_spritesheet,
			Rect2(walker_position + Vector2(-24, -58 + bob), Vector2(48, 64)),
			Rect2(walker_frame * 48, walker_row * 64, 48, 64)
		)
	else:
		_draw_walker_fallback(walker_position + Vector2(0, bob))
	for y in range(10, int(size.y), 8):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.4, 0.8, 0.7, 0.012), 1.0)
	if _terminal_is_open():
		draw_rect(Rect2(30, 112, 330, size.y - 220), Color(0.015, 0.055, 0.049, 0.88))
		draw_rect(Rect2(378, 112, 330, size.y - 220), Color(0.015, 0.055, 0.049, 0.88))
		draw_rect(Rect2(726, 112, size.x - 756, size.y - 220), Color(0.015, 0.055, 0.049, 0.88))
	else:
		_draw_mobile_hub_controls()


# The hub follows the same appearance rule as the playable character: an active
# combat style takes precedence, then the profession, then the original drifter.
func _walker_body_texture() -> Texture2D:
	var style_texture: Texture2D = COMBAT_STYLE_SPRITESHEETS.get(GameState.active_combat_style)
	if style_texture != null:
		return style_texture
	match GameState.selected_pathway:
		"steadfast":
			return STEADFAST_SPRITESHEET
		"armorer":
			return ARMORER_SPRITESHEET
		"resonant":
			return RESONANT_SPRITESHEET
	return DRIFTER_SPRITESHEET


func _draw_legend_gate(position: Vector2, color: Color, title: String, subtitle: String, asset_index: int) -> void:
	var is_near := walker_position.distance_to(position) <= INTERACTION_RANGE
	draw_circle(position, 116, Color(color, 0.17 if is_near else 0.09))
	_draw_hub_asset(asset_index, position + Vector2(0, -10), 190.0, Color(color, 1.0))
	draw_arc(position, 104, -2.12, 2.12, 48, Color(color, 0.8), 5.0 if is_near else 2.0)
	draw_line(position + Vector2(-83, 92), position + Vector2(83, 92), Color(color, 0.62), 2.0)
	draw_string(UI_FONT, position + Vector2(-112, 138), title, HORIZONTAL_ALIGNMENT_CENTER, 224, 24, Color("d6f6ed"))
	draw_string(UI_FONT, position + Vector2(-130, 166), subtitle, HORIZONTAL_ALIGNMENT_CENTER, 260, 15, Color(color, 0.88))


func _draw_hub_asset(index: int, center: Vector2, draw_size: float, modulate := Color.WHITE) -> void:
	if CORRIDOR_HUB_ATLAS == null or CORRIDOR_HUB_ATLAS.get_size() != Vector2(512, 512):
		_draw_corridor_prop(index % 6, center, draw_size, modulate)
		return
	var column := index % 4
	var row := floori(float(index) / 4.0)
	draw_texture_rect_region(
		CORRIDOR_HUB_ATLAS,
		Rect2(center - Vector2.ONE * draw_size * 0.5, Vector2.ONE * draw_size),
		Rect2(column * 128, row * 128, 128, 128),
		modulate
	)


func _draw_corridor_prop(index: int, center: Vector2, draw_size: float, modulate := Color.WHITE) -> void:
	if CORRIDOR_PROPS == null or CORRIDOR_PROPS.get_size() != Vector2(384, 256):
		draw_rect(Rect2(center - Vector2.ONE * draw_size * 0.5, Vector2.ONE * draw_size), Color("182129"))
		return
	var column := index % 3
	var row := floori(float(index) / 3.0)
	draw_texture_rect_region(
		CORRIDOR_PROPS,
		Rect2(center - Vector2.ONE * draw_size * 0.5, Vector2.ONE * draw_size),
		Rect2(column * 128, row * 128, 128, 128),
		modulate
	)


func _draw_threshold_curator() -> void:
	var bob := sin(Time.get_ticks_msec() * 0.0016) * 2.0
	if THRESHOLD_CURATOR_SPRITESHEET == null or THRESHOLD_CURATOR_SPRITESHEET.get_size() != Vector2(576, 384):
		draw_circle(CURATOR_POSITION + Vector2(0, -37 + bob), 18, Color("b3dbd0"))
		draw_colored_polygon(PackedVector2Array([
			CURATOR_POSITION + Vector2(-42, 20),
			CURATOR_POSITION + Vector2(42, 20),
			CURATOR_POSITION + Vector2(28, -52 + bob),
			CURATOR_POSITION + Vector2(-28, -52 + bob),
		]), Color("355f57"))
		return
	var frame := floori(Time.get_ticks_msec() / 240.0) % 6
	# Draw at 128 px—twice the walker's visual height—while retaining the
	# locked 96×96 source frame used by boss-scale characters.
	draw_texture_rect_region(
		THRESHOLD_CURATOR_SPRITESHEET,
		Rect2(CURATOR_POSITION + Vector2(-64, -116 + bob), Vector2(128, 128)),
		Rect2(frame * 96, 0, 96, 96),
		Color(0.9, 0.98, 0.95, 1.0)
	)
	draw_circle(CURATOR_POSITION + Vector2(0, -48 + bob), 34, Color(0.2, 0.94, 0.84, 0.055))


func _draw_walker_fallback(position: Vector2) -> void:
	draw_circle(position + Vector2(0, -42), 9.0, Color("c9c2ae"))
	draw_rect(Rect2(position + Vector2(-13, -34), Vector2(26, 34)), Color("7d9b76"))
	draw_line(position + Vector2(-8, -2), position + Vector2(-11, 8), Color("2b343b"), 7.0)
	draw_line(position + Vector2(8, -2), position + Vector2(11, 8), Color("2b343b"), 7.0)
	draw_circle(position + Vector2(-12, -25), 3.0, Color("59e1e6"))


func _create_audio_settings() -> void:
	audio_settings_button = Button.new()
	audio_settings_button.name = "OpenCorridorAudioSettings"
	audio_settings_button.text = "声音"
	audio_settings_button.tooltip_text = "音乐与音效设置"
	audio_settings_button.add_theme_font_override("font", UI_FONT)
	audio_settings_button.add_theme_font_size_override("font_size", 16)
	audio_settings_button.pressed.connect(func(): audio_settings_panel.toggle())
	add_child(audio_settings_button)
	audio_settings_panel = DreadboundAudioSettingsPanel.new()
	add_child(audio_settings_panel)
	audio_settings_panel.configure(UI_FONT)


func _open_terminal() -> void:
	$Background.color = Color(0.004, 0.024, 0.021, 0.985)
	$Margin.visible = not _is_portrait()
	if _is_portrait():
		_refresh_mobile_terminal()
		mobile_terminal_panel.visible = true
		if hub_navigation:
			hub_navigation.visible = false
	$HubTitle.visible = false
	$HubActions.visible = false
	if audio_settings_button:
		audio_settings_button.visible = false
	queue_redraw()


func _close_terminal() -> void:
	$Margin.visible = false
	$Background.color = Color(0.015, 0.032, 0.031, 0)
	if mobile_terminal_panel:
		mobile_terminal_panel.visible = false
	if hub_navigation:
		hub_navigation.visible = true
	$HubTitle.visible = true
	$HubActions.visible = false
	if audio_settings_button:
		audio_settings_button.visible = true
	queue_redraw()


func _create_warehouse_panel() -> void:
	warehouse_panel = ColorRect.new()
	warehouse_panel.position = Vector2(115, 65)
	warehouse_panel.size = Vector2(1050, 590)
	warehouse_panel.color = Color(0.008, 0.035, 0.032, 0.985)
	warehouse_panel.visible = false
	# The warehouse is opened from inside the terminal.  It must sit above both
	# terminal variants (desktop Margin and the mobile terminal at z=140),
	# otherwise its controls are visible but unreachable on phone canvases.
	warehouse_panel.z_index = 200
	add_child(warehouse_panel)
	var title := Label.new()
	title.position = Vector2(30, 22)
	title.size = Vector2(990, 48)
	title.text = "异常装备回收仓库"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("62dec6"))
	warehouse_panel.add_child(title)
	warehouse_status = Label.new()
	warehouse_status.add_theme_font_size_override("font_size", 15)
	warehouse_status.add_theme_color_override("font_color", Color("8fc8bb"))
	warehouse_panel.add_child(warehouse_status)
	var scroll := ScrollContainer.new()
	warehouse_panel.add_child(scroll)
	warehouse_scroll = scroll
	warehouse_list = GridContainer.new()
	warehouse_list.columns = 4
	warehouse_list.custom_minimum_size = Vector2(560, 0)
	warehouse_list.add_theme_constant_override("h_separation", 8)
	warehouse_list.add_theme_constant_override("v_separation", 8)
	scroll.add_child(warehouse_list)
	warehouse_preview = TextureRect.new()
	warehouse_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	warehouse_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	warehouse_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	warehouse_preview.texture = UNKNOWN_EQUIPMENT_ICON
	warehouse_panel.add_child(warehouse_preview)
	warehouse_detail = Label.new()
	warehouse_detail.text = "点击左侧装备格查看大图、评级、属性与成长路线。"
	warehouse_detail.add_theme_font_size_override("font_size", 16)
	warehouse_detail.add_theme_color_override("font_color", Color("a7bbb4"))
	warehouse_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warehouse_detail_scroll = ScrollContainer.new()
	warehouse_detail_scroll.name = "EquipmentDetailScroll"
	warehouse_detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	warehouse_detail_scroll.clip_contents = true
	warehouse_panel.add_child(warehouse_detail_scroll)
	warehouse_detail_scroll.add_child(warehouse_detail)
	equip_button = Button.new()
	equip_button.text = "装备"
	equip_button.pressed.connect(_equip_selected)
	warehouse_panel.add_child(equip_button)
	salvage_button = Button.new()
	salvage_button.text = "拆解"
	salvage_button.pressed.connect(_salvage_selected)
	warehouse_panel.add_child(salvage_button)
	progress_button = Button.new()
	progress_button.text = "升级 / 进化"
	progress_button.pressed.connect(_progress_selected)
	warehouse_panel.add_child(progress_button)
	var close := Button.new()
	close.name = "ReturnWarehouse"
	close.position = Vector2(390, 515)
	close.size = Vector2(270, 55)
	close.text = "返回回廊"
	close.pressed.connect(func(): warehouse_panel.visible = false)
	warehouse_panel.add_child(close)


func _create_salvage_reward_panel() -> void:
	salvage_reward_panel = ColorRect.new()
	salvage_reward_panel.name = "SalvageReward"
	salvage_reward_panel.color = Color(0.008, 0.04, 0.035, 0.995)
	salvage_reward_panel.visible = false
	# This is the final feedback surface: it must sit above the warehouse and
	# the terminal on both desktop and mobile, so a successful dismantle is never
	# mistaken for a silent loss of equipment.
	salvage_reward_panel.z_index = 260
	add_child(salvage_reward_panel)
	var title := Label.new()
	title.text = "回收结算完成"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("79ead2"))
	salvage_reward_panel.add_child(title)
	salvage_reward_detail = Label.new()
	salvage_reward_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	salvage_reward_detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	salvage_reward_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	salvage_reward_detail.add_theme_font_size_override("font_size", 20)
	salvage_reward_detail.add_theme_color_override("font_color", Color("d5f4ea"))
	salvage_reward_panel.add_child(salvage_reward_detail)
	var close := Button.new()
	close.text = "确认收取"
	close.add_theme_font_size_override("font_size", 18)
	close.pressed.connect(func(): salvage_reward_panel.visible = false)
	salvage_reward_panel.add_child(close)


func _create_run_archive_panel() -> void:
	run_archive_panel = ColorRect.new()
	run_archive_panel.name = "RunArchive"
	run_archive_panel.color = Color(0.007, 0.032, 0.029, 0.995)
	run_archive_panel.visible = false
	run_archive_panel.z_index = 280
	add_child(run_archive_panel)
	var title := Label.new()
	title.name = "Title"
	title.text = "行动结算与人性档案"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("79ead2"))
	run_archive_panel.add_child(title)
	run_archive_scroll = ScrollContainer.new()
	run_archive_panel.add_child(run_archive_scroll)
	run_archive_detail = Label.new()
	run_archive_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	run_archive_detail.add_theme_font_size_override("font_size", 17)
	run_archive_detail.add_theme_color_override("font_color", Color("c5ded6"))
	run_archive_scroll.add_child(run_archive_detail)
	var close := Button.new()
	close.name = "Close"
	close.text = "确认并返回回廊"
	close.add_theme_font_size_override("font_size", 17)
	close.pressed.connect(func(): run_archive_panel.visible = false)
	run_archive_panel.add_child(close)


func _create_human_mirror_panel() -> void:
	open_mirror_button = Button.new()
	open_mirror_button.name = "OpenHumanMirror"
	open_mirror_button.text = "人性镜鉴"
	open_mirror_button.add_theme_font_size_override("font_size", 18)
	open_mirror_button.pressed.connect(_open_human_mirror)
	add_child(open_mirror_button)
	mirror_panel = ColorRect.new()
	mirror_panel.name = "HumanMirror"
	mirror_panel.color = Color(0.006, 0.026, 0.034, 0.995)
	mirror_panel.visible = false
	mirror_panel.z_index = 300
	add_child(mirror_panel)
	var title := Label.new()
	title.name = "Title"
	title.position = Vector2(28, 20)
	title.size = Vector2(700, 46)
	title.text = "人性镜鉴"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("7ddcf2"))
	mirror_panel.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	mirror_panel.add_child(scroll)
	mirror_content = VBoxContainer.new()
	mirror_content.name = "Content"
	mirror_content.add_theme_constant_override("separation", 10)
	scroll.add_child(mirror_content)
	var close := Button.new()
	close.name = "Close"
	close.text = "返回终末回廊"
	close.size = Vector2(122, 42)
	close.pressed.connect(func(): mirror_panel.visible = false)
	mirror_panel.add_child(close)


func _open_human_mirror() -> void:
	_refresh_human_mirror()
	mirror_panel.visible = true
	$HubActions.visible = false
	_apply_responsive_ui()


func _refresh_human_mirror() -> void:
	for child in mirror_content.get_children():
		child.queue_free()
	var assessment := GameState.humanity_reflection()
	var profile: Dictionary = assessment.get("profile", {})
	var intro := Label.new()
	intro.text = "%s\n这里记录的是游戏高压情境中的可反驳推断，不是现实人格或心理诊断。" % str(profile.get("disclaimer", ""))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_color", Color("b8d5dc"))
	mirror_content.add_child(intro)
	var contract: Dictionary = GameState.active_counter_contract
	if not contract.is_empty():
		var contract_label := Label.new()
		contract_label.text = "当前反证契约：%s\n%s · 目标行为 %s · 完成奖励 %d 因果残片" % [
			str(contract.get("title", "")), str(contract.get("method", "")),
			str(contract.get("success_event", "")), int(contract.get("reward", 0)),
		]
		contract_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		contract_label.add_theme_color_override("font_color", Color("efc66d"))
		mirror_content.add_child(contract_label)
	var dimensions: Dictionary = profile.get("dimensions", {})
	for dimension_id in HumanityProfile.DIMENSIONS:
		var result: Dictionary = dimensions.get(dimension_id, {})
		var poles: Dictionary = HumanityProfile.DIMENSIONS[dimension_id]
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		mirror_content.add_child(box)
		var heading := Label.new()
		heading.text = "%s ↔ %s：%s · 置信度 %d%% · 样本 %d" % [
			str(poles.negative), str(poles.positive), str(result.get("pole", "尚未形成")),
			int(round(float(result.get("confidence", 0.0)) * 100.0)), int(result.get("sample_size", 0)),
		]
		heading.add_theme_font_size_override("font_size", 19)
		heading.add_theme_color_override("font_color", Color("7ddcf2"))
		box.add_child(heading)
		var evidence := Label.new()
		evidence.text = "%s\n支持证据 %d 条 · 相反证据 %d 条\n方法：%s" % [
			str(result.get("interpretation", "样本不足，暂不判断。")),
			result.get("evidence", []).size(), result.get("counter_evidence", []).size(),
			str(result.get("method", "等待更多跨情境行为")),
		]
		evidence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		evidence.add_theme_color_override("font_color", Color("b8cbc8"))
		box.add_child(evidence)
		var dispute := Button.new()
		dispute.name = "Dispute_%s" % dimension_id
		var disputed: Dictionary = GameState.reflection_disputes.get(dimension_id, {})
		dispute.text = "已提出异议：等待用行动反证" if not disputed.is_empty() and not bool(disputed.get("resolved", false)) else ("反证已被记录" if bool(disputed.get("resolved", false)) else "我不同意这个解释 · 生成反证契约")
		dispute.disabled = int(result.get("sample_size", 0)) <= 0 or (not GameState.active_counter_contract.is_empty() and str(GameState.active_counter_contract.get("dimension", "")) != dimension_id)
		dispute.pressed.connect(_dispute_dimension.bind(str(dimension_id)))
		box.add_child(dispute)
	var timeline_title := Label.new()
	timeline_title.text = "跨局变化时间线"
	timeline_title.add_theme_font_size_override("font_size", 22)
	timeline_title.add_theme_color_override("font_color", Color("efc66d"))
	mirror_content.add_child(timeline_title)
	var timeline := GameState.reflection_timeline()
	if timeline.is_empty():
		var empty := Label.new()
		empty.text = "完成一次副本后，这里会显示六维倾向、置信度与司仪预测如何变化。"
		mirror_content.add_child(empty)
	for snapshot in timeline:
		var line := Label.new()
		var changed: Array[String] = []
		for dimension_id in snapshot.get("dimensions", {}):
			var result: Dictionary = snapshot.dimensions[dimension_id]
			if int(result.get("sample_size", 0)) > 0:
				changed.append("%s %s %d%%" % [dimension_id, str(result.get("pole", "")), int(round(float(result.get("confidence", 0.0)) * 100.0))])
		line.text = "%s · %s · %s\n%s" % [
			str(snapshot.get("action_code", "")),
			"潮没末班线" if str(snapshot.get("world_id", "")) == "metro" else "废弃疗养院",
			"撤离" if bool(snapshot.get("success", false)) else "失联",
			"；".join(changed) if not changed.is_empty() else "本局未形成有效维度变化",
		]
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mirror_content.add_child(line)


func _dispute_dimension(dimension_id: String) -> void:
	var contract := GameState.dispute_reflection(dimension_id)
	feedback.text = "已生成反证契约：下一局可用真实行动推翻旧解释。" if not contract.is_empty() else "该维度样本不足，暂时无法生成反证契约。"
	_refresh_human_mirror()


func _open_run_archive() -> void:
	if GameState.last_run.is_empty():
		feedback.text = "行动档案尚未形成；完成一次副本后，结算、收获与人性洞察会保存在这里。"
		return
	run_archive_detail.text = _build_run_archive_text(GameState.last_run)
	run_archive_scroll.scroll_vertical = 0
	run_archive_panel.visible = true
	$HubActions.visible = false
	_layout_run_archive(get_viewport_rect().size)


func _build_run_archive_text(run: Dictionary) -> String:
	var dynamic: Dictionary = run.get("dynamic_run", {})
	var lines: Array[String] = []
	lines.append("【%s】  %s" % ["撤离成功" if bool(run.get("success", false)) else "行动失败", str(dynamic.get("mission", "未知契约"))])
	lines.append("行动代码  %s  ·  世界  %s  ·  难度  %s" % [
		str(dynamic.get("action_code", "旧版行动")),
		"潮没末班线" if str(dynamic.get("world", "")) == "metro" else "废弃疗养院",
		str(GameProgress.DIFFICULTIES.get(str(run.get("difficulty", "standard")), GameProgress.DIFFICULTIES.standard).name),
	])
	lines.append("")
	lines.append("【本次收获】")
	lines.append("现场碎片  %d  +  任务奖励  %d  =  入库碎片  %d" % [
		int(run.get("carried_shards", 0)), int(run.get("mission_reward", 0)), int(run.get("banked_shards", 0)),
	])
	lines.append("目标完成  %d  ·  风险事件  %d/2  ·  清除威胁  %d" % [
		int(run.get("records", 0)), int(run.get("events_resolved", 0)), int(run.get("enemies_defeated", 0)),
	])
	var equipment_names: Array[String] = []
	for item_id in run.get("equipment_rewards", []):
		equipment_names.append(str(EquipmentDatabase.get_item(str(item_id)).get("name", item_id)))
	lines.append("装备入库  %s" % ("、".join(equipment_names) if not equipment_names.is_empty() else "无"))
	if int(run.get("overflow_shards", 0)) > 0:
		lines.append("仓库溢出自动转化  +%d 回响碎片" % int(run.get("overflow_shards", 0)))
	for reward in run.get("milestone_rewards", []):
		lines.append("因果里程碑  %s  ·  +%d 因果残片" % [str(reward.get("title", "")), int(reward.get("causality_fragments", 0))])
	for reward in run.get("trial_rewards", []):
		lines.append("司仪试炼  %s  ·  +%d 因果残片" % [str(reward.get("title", "")), int(reward.get("causality_fragments", 0))])
	var relic: Dictionary = run.get("relic_growth", {})
	if not relic.is_empty():
		lines.append("Boss 遗物成长  %s  ·  Lv.%d" % [str(relic.get("name", "未知遗物")), int(relic.get("level", 0))])
		lines.append("新形态效果  %s" % EquipmentDatabase.relic_growth_description(str(relic.get("item_id", "")), int(relic.get("level", 0))))
	lines.append("")
	lines.append("【人性洞察】")
	var assessment: Dictionary = run.get("humanity_reflection", {})
	if assessment.is_empty():
		assessment = GameState.humanity_reflection()
	lines.append(_format_humanity_archive(assessment))
	lines.append("")
	lines.append("【世界留下的变化】")
	var consequences: Array = run.get("world_consequences", [])
	if consequences.is_empty():
		lines.append("本次行动未形成可确认的长期世界变化。")
	else:
		for consequence in consequences:
			lines.append("· %s" % _world_change_text(consequence))
	var faction_turn: Dictionary = run.get("faction_turn", {})
	for change in faction_turn.get("changes", []):
		lines.append("· %s" % _world_change_text(change))
	var dungeon_memory: Dictionary = run.get("dungeon_memory", {})
	if not dungeon_memory.is_empty():
		lines.append("")
		lines.append("【副本记忆】")
		lines.append("第 %d 次进入 · 已完成 %d 次 · 当前章节 %s" % [
			int(dungeon_memory.get("visits", 0)),
			int(dungeon_memory.get("completed_runs", 0)),
			str(dungeon_memory.get("chapter", "未知")),
		])
		var dungeon_history: Array = run.get("dungeon_history", [])
		for memory in dungeon_history:
			var choice := str(memory.get("choice", ""))
			if choice in ["extracted", "lost"]:
				continue
			lines.append("· 第 %d 次：%s" % [int(memory.get("visit", 0)), str(memory.get("summary", ""))])
		if GameState.dungeon_hidden_open(str(dungeon_memory.get("world_id", "")), "lost_passenger_level"):
			lines.append("· 隐藏区域：失踪乘客维护层已永久显现")
	var trailer := str(assessment.get("trailer", ""))
	if not trailer.is_empty():
		lines.append("")
		lines.append("【下一集预告】")
		lines.append(trailer)
	return "\n".join(lines)


func _format_humanity_archive(assessment: Dictionary) -> String:
	var profile: Dictionary = assessment.get("profile", {})
	var echo: Dictionary = assessment.get("echo", {})
	if str(echo.get("id", "")) == "unformed_echo":
		return "人性回声尚未成形：有效选择样本不足，系统不会据此判断人格。\n继续经历不同情境后，这里会显示证据、相反证据与置信度。"
	var lines: Array[String] = []
	lines.append("人性回声  %s" % str(echo.get("name", "未成形的回声")))
	var dimensions: Dictionary = profile.get("dimensions", {})
	for dimension_id in HumanityProfile.DIMENSIONS:
		var result: Dictionary = dimensions.get(dimension_id, {})
		if int(result.get("sample_size", 0)) <= 0:
			continue
		var positive_score := int(result.get("score", 0)) > 0
		var evidence: Array = result.get("evidence", []) if positive_score else result.get("counter_evidence", [])
		var contrary: Array = result.get("counter_evidence", []) if positive_score else result.get("evidence", [])
		var evidence_text := "暂无可展示证据"
		if not evidence.is_empty():
			evidence_text = "%s / %s" % [str(evidence[-1].get("event_type", "")), str(evidence[-1].get("world_id", ""))]
		var contrary_text := "尚未观察到"
		if not contrary.is_empty():
			contrary_text = "%s / %s" % [str(contrary[-1].get("event_type", "")), str(contrary[-1].get("world_id", ""))]
		var knowledge: Array = result.get("knowledge", [])
		var knowledge_text := "知识条目待补充"
		if not knowledge.is_empty():
			knowledge_text = "%s（%s）" % [str(knowledge[0].get("title", "")), str(knowledge[0].get("source", ""))]
		var poles: Dictionary = HumanityProfile.DIMENSIONS[dimension_id]
		lines.append("· %s ↔ %s：%s（置信度 %d%%）" % [
			str(poles.negative), str(poles.positive), str(result.get("interpretation", "样本不足")),
			int(round(float(result.get("confidence", 0.0)) * 100.0)),
		])
		lines.append("  行为依据：%s" % evidence_text)
		lines.append("  相反证据：%s" % contrary_text)
		lines.append("  知识依据：%s" % knowledge_text)
	lines.append("仅反映游戏高压情境中的选择模式，不是现实人格或心理健康诊断。")
	return "\n".join(lines)


func _world_change_text(change: Dictionary) -> String:
	var names := {
		"sanatorium": "废弃疗养院", "metro": "潮没末班线",
		"order_authority": "秩序署", "sunken_cult": "沉潮教团",
		"resonance": "共鸣体", "drifters": "漂泊者",
		"safety": "安全度", "corruption": "污染度", "resources": "资源",
		"influence": "势力", "supplies": "补给", "player_trust": "信任",
	}
	var target := str(change.get("target", change.get("region_id", change.get("faction_id", "世界"))))
	var field := str(change.get("field", "状态"))
	if field == "controller":
		return "%s 控制权：%s → %s" % [
			str(names.get(target, target)),
			str(names.get(str(change.get("from", "")), change.get("from", ""))),
			str(names.get(str(change.get("to", "")), change.get("to", ""))),
		]
	return "%s · %s %s%d" % [
		str(names.get(target, target)), str(names.get(field, field)),
		"+" if int(change.get("amount", 0)) >= 0 else "", int(change.get("amount", 0)),
	]


func _is_portrait() -> bool:
	# Mobile browser chrome often leaves a nearly-square game canvas even while
	# the physical device is landscape. Use the scrollable terminal there too.
	return size.y > size.x * 0.72 or size.x < 1180.0


func _terminal_is_open() -> bool:
	return $Margin.visible or (mobile_terminal_panel and mobile_terminal_panel.visible)


func _mobile_panel_width() -> float:
	return minf(size.x - 28.0, 760.0)


func _create_mobile_terminal_panel() -> void:
	mobile_terminal_panel = ColorRect.new()
	mobile_terminal_panel.name = "MobileTerminal"
	mobile_terminal_panel.color = Color(0.006, 0.028, 0.025, 0.995)
	mobile_terminal_panel.visible = false
	mobile_terminal_panel.z_index = 140
	add_child(mobile_terminal_panel)


func _create_curator_contract_panel() -> void:
	curator_contract_panel = ColorRect.new()
	curator_contract_panel.name = "CuratorContractPanel"
	curator_contract_panel.color = Color(0.006, 0.032, 0.029, 0.995)
	curator_contract_panel.visible = false
	curator_contract_panel.z_index = 320
	add_child(curator_contract_panel)
	var title := Label.new()
	title.name = "Title"
	title.text = "阈值司仪 · 本次契约"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("79ead2"))
	curator_contract_panel.add_child(title)
	var hint := Label.new()
	hint.name = "Hint"
	hint.text = "仅选择本次投送的规则与奖励；装备、职业和档案请使用底部独立入口。"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color("9cc6bb"))
	curator_contract_panel.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.clip_contents = true
	curator_contract_panel.add_child(scroll)
	curator_contract_content = VBoxContainer.new()
	curator_contract_content.name = "Content"
	curator_contract_content.add_theme_constant_override("separation", 10)
	scroll.add_child(curator_contract_content)
	var close := Button.new()
	close.name = "Close"
	close.text = "返回回廊"
	close.pressed.connect(_close_curator_contract_panel)
	curator_contract_panel.add_child(close)


func _open_curator_contract_panel() -> void:
	_close_hub_surfaces()
	_refresh_curator_contract_panel()
	curator_contract_panel.visible = true
	if hub_navigation:
		hub_navigation.visible = false
	$HubTitle.visible = false
	$HubActions.visible = false
	if audio_settings_button:
		audio_settings_button.visible = false
	_layout_curator_contract_panel(get_viewport_rect().size)


func _close_curator_contract_panel() -> void:
	if curator_contract_panel:
		curator_contract_panel.visible = false
	if hub_navigation:
		hub_navigation.visible = true
	$HubTitle.visible = true
	$HubActions.visible = false
	if audio_settings_button:
		audio_settings_button.visible = true


func _refresh_curator_contract_panel() -> void:
	if curator_contract_content == null:
		return
	for child in curator_contract_content.get_children():
		child.queue_free()
	var active := GameState.get_curator_trial()
	if not active.is_empty():
		var active_label := Label.new()
		active_label.text = "已采纳\n%s\n规则：%s\n奖励：%s" % [str(active.title), str(active.get("rule_text", "")), str(active.reward_text)]
		active_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		active_label.add_theme_font_size_override("font_size", 18)
		active_label.add_theme_color_override("font_color", Color("b8eee0"))
		curator_contract_content.add_child(active_label)
		var defer := Button.new()
		defer.custom_minimum_size = Vector2(0, 52)
		defer.text = "暂缓当前契约"
		defer.pressed.connect(_dismiss_trial)
		curator_contract_content.add_child(defer)
		return
	for offer in GameState.get_curator_contract_offers():
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 82)
		button.text = "%s  ·  %s\n%s\n规则：%s" % [str(offer.title), str(offer.reward_text), str(offer.description), str(offer.get("rule_text", ""))]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_choose_curator_contract.bind(str(offer.id)))
		curator_contract_content.add_child(button)


func _create_curator_controls() -> void:
	var archive := $Margin/Layout/Columns/Archive as VBoxContainer
	curator_offer_box = VBoxContainer.new()
	curator_offer_box.name = "CuratorOffers"
	curator_offer_box.add_theme_constant_override("separation", 6)
	archive.add_child(curator_offer_box)
	var reset := Button.new()
	reset.name = "ResetCurator"
	reset.custom_minimum_size = Vector2(0, 42)
	reset.text = "重置司仪观察"
	reset.pressed.connect(_reset_curator_profile)
	archive.add_child(reset)


func _create_respec_control() -> void:
	var button := Button.new()
	button.name = "RespecPathway"
	button.custom_minimum_size = Vector2(0, 44)
	button.text = "重构职业 · 1 因果残片（可无限次）"
	button.disabled = GameState.selected_pathway.is_empty()
	button.pressed.connect(_respec_pathway)
	$Margin/Layout/Columns/Paths.add_child(button)


func _create_difficulty_control() -> void:
	var button := Button.new()
	button.name = "DifficultySelector"
	button.custom_minimum_size = Vector2(0, 58)
	button.pressed.connect(_cycle_difficulty)
	$Margin/Layout/Columns/Profile.add_child(button)


func _cycle_difficulty() -> void:
	var ids := ["standard", "hazard", "nightmare"]
	var index := (ids.find(GameState.selected_difficulty) + 1) % ids.size()
	GameState.set_difficulty(ids[index])
	feedback.text = "副本难度已设为%s：会同步改变敌人、掉落和首领遗物概率。" % GameState.get_difficulty().name
	_refresh()


func _scroll_warehouse(amount: int) -> void:
	if warehouse_scroll:
		warehouse_scroll.scroll_vertical = maxi(warehouse_scroll.scroll_vertical + amount, 0)


func _refresh_curator_offers() -> void:
	if curator_offer_box == null:
		return
	for child in curator_offer_box.get_children():
		child.queue_free()
	var active := GameState.get_curator_trial()
	if not active.is_empty():
		var active_label := Label.new()
		active_label.text = "已采纳：%s\n%s\n规则：%s · 奖励 %s" % [str(active.title), str(active.description), str(active.get("rule_text", "")), str(active.reward_text)]
		active_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		active_label.add_theme_color_override("font_color", Color("8ce8d6"))
		curator_offer_box.add_child(active_label)
		var defer := Button.new()
		defer.custom_minimum_size = Vector2(0, 42)
		defer.text = "暂缓当前契约"
		defer.pressed.connect(_dismiss_trial)
		curator_offer_box.add_child(defer)
		return
	var heading := Label.new()
	heading.text = "阈值司仪 · 本次可选契约（仅可采纳一项）"
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_color_override("font_color", Color("6cd7c0"))
	curator_offer_box.add_child(heading)
	for offer in GameState.get_curator_contract_offers():
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 68)
		button.text = "%s · %s\n%s\n规则：%s · %s" % [str(offer.title), str(offer.reward_text), str(offer.description), str(offer.get("rule_text", "")), "世界专属" if str(offer.kind) == "world" else ("行为契约" if str(offer.kind) == "behavior" else "高风险")]
		button.pressed.connect(_choose_curator_contract.bind(str(offer.id)))
		curator_offer_box.add_child(button)


func _choose_curator_contract(trial_id: String) -> void:
	feedback.text = "阈值司仪：契约已写入本次投送。规则、代价与奖励均可在行动前查看。" if GameState.choose_curator_contract(trial_id) else "该契约已失效；请重新查看司仪档案。"
	_refresh()
	if curator_contract_panel and curator_contract_panel.visible:
		_refresh_curator_contract_panel()


func _refresh_mobile_terminal() -> void:
	if mobile_terminal_panel == null:
		return
	for child in mobile_terminal_panel.get_children():
		child.queue_free()
	var panel_width := _mobile_panel_width()
	mobile_terminal_panel.position = Vector2((size.x - panel_width) * 0.5, 12.0)
	mobile_terminal_panel.size = Vector2(panel_width, size.y - 24.0)
	var header := Label.new()
	header.position = Vector2(18, 16)
	header.size = Vector2(panel_width - 36, 34)
	header.text = "行者整备终端"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", Color("62dec6"))
	mobile_terminal_panel.add_child(header)
	var currency_label := Label.new()
	currency_label.position = Vector2(18, 52)
	currency_label.size = Vector2(panel_width - 36, 27)
	currency_label.text = "回响 %d · 因果 %d · 余烬 %d" % [GameState.echo_shards, GameState.causality_fragments, GameState.synthesis_embers]
	currency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	currency_label.add_theme_font_size_override("font_size", 16)
	mobile_terminal_panel.add_child(currency_label)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(14, 88)
	scroll.size = Vector2(panel_width - 28, maxf(64.0, mobile_terminal_panel.size.y - 176))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.clip_contents = true
	mobile_terminal_panel.add_child(scroll)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(panel_width - 50, 0)
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	_mobile_terminal_section(content, "漂泊者档案", stats.text)
	_mobile_terminal_section(content, "上次行动", report.text)
	_mobile_terminal_section(content, "阈值司仪 · 行动档案", _curator_profile_text())
	var mirror := Button.new()
	mirror.name = "MobileOpenHumanMirror"
	mirror.custom_minimum_size = Vector2(0, 56)
	mirror.text = "打开人性镜鉴 · 时间线 / 证据 / 反证契约"
	mirror.pressed.connect(func():
		mobile_terminal_panel.visible = false
		_open_human_mirror()
	)
	content.add_child(mirror)
	var trial := GameState.get_curator_trial()
	if trial.is_empty():
		_mobile_terminal_section(content, "本次可选契约（仅可采纳一项）", "司仪会提供副本专属、行为导向与高风险契约；所有规则在进入副本前公开。")
		for offer in GameState.get_curator_contract_offers():
			var offer_button := Button.new()
			offer_button.custom_minimum_size = Vector2(0, 78)
			offer_button.text = "%s · %s\n%s\n%s" % [str(offer.title), str(offer.reward_text), str(offer.description), str(offer.get("rule_text", ""))]
			offer_button.pressed.connect(_choose_curator_contract.bind(str(offer.id)))
			content.add_child(offer_button)
	else:
		_mobile_terminal_section(content, "已采纳契约", "%s\n%s\n规则：%s · 奖励 %s" % [str(trial.title), str(trial.description), str(trial.get("rule_text", "")), str(trial.reward_text)])
		var trial_action := Button.new()
		trial_action.custom_minimum_size = Vector2(0, 54)
		trial_action.text = "暂缓当前契约"
		trial_action.pressed.connect(_dismiss_trial)
		content.add_child(trial_action)
	var reset_profile := Button.new()
	reset_profile.custom_minimum_size = Vector2(0, 48)
	reset_profile.text = "重置司仪观察（不影响装备与成长）"
	reset_profile.pressed.connect(_reset_curator_profile)
	content.add_child(reset_profile)
	_mobile_terminal_section(content, "出发整备", "在这里调整配置；副本入口请返回回廊使用对应传说门。")
	var mobile_difficulty := Button.new()
	var difficulty := GameState.get_difficulty()
	mobile_difficulty.custom_minimum_size = Vector2(0, 62)
	mobile_difficulty.text = "副本难度：%s\n%s（点击切换）" % [str(difficulty.name), str(difficulty.description)]
	mobile_difficulty.pressed.connect(_cycle_difficulty)
	content.add_child(mobile_difficulty)
	for loadout_id in GameProgress.LOADOUTS:
		var loadout: Dictionary = GameProgress.LOADOUTS[loadout_id]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 56)
		button.text = "%s%s\n%s" % ["▶ " if GameState.selected_loadout == loadout_id else "", loadout.name, loadout.description]
		button.pressed.connect(_select_loadout.bind(loadout_id))
		content.add_child(button)
	_mobile_terminal_section(content, "永久强化", "选择强化，下一次投送生效。")
	for upgrade_id in UPGRADE_INFO:
		var level := int(GameState.upgrades[upgrade_id])
		var cost := GameState.get_upgrade_cost(upgrade_id)
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 60)
		button.text = "%s  Lv.%d/%d\n%s" % [UPGRADE_INFO[upgrade_id][0], level, GameState.get_upgrade_max_level(upgrade_id), "%s · %d 碎片" % [UPGRADE_INFO[upgrade_id][1], cost] if cost > 0 else "已满级"]
		button.disabled = cost == 0 or GameState.echo_shards < cost
		button.pressed.connect(_purchase.bind(upgrade_id))
		content.add_child(button)
	_mobile_terminal_section(content, "阈值途径 · 职业成长", "首次锚定消耗 8 回响碎片 + 1 因果残片，并选定一条职业路线；该职业会开放两项基础强化的 Lv.4–6。因果残片可通过分解回响/异常装备获得。")
	for node_id in GameProgress.PATH_NODES:
		var node: Dictionary = GameProgress.PATH_NODES[node_id]
		if (GameState.selected_pathway.is_empty() and not str(node.get("requires", "")).is_empty()) or (not GameState.selected_pathway.is_empty() and str(node.path) != GameState.selected_pathway):
			continue
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 60)
		var unlocked := GameState.unlocked_path_nodes.has(node_id)
		var anchor_needed := GameState.selected_pathway.is_empty()
		var locked_path := not GameState.selected_pathway.is_empty() and GameState.selected_pathway != str(node.path)
		var missing_requirement := not str(node.get("requires", "")).is_empty() and not GameState.unlocked_path_nodes.has(str(node.requires))
		var cost_text := "%s · %d 碎片" % [str(node.description), int(node.cost)]
		if int(node.get("fragment_cost", 0)) > 0:
			cost_text += " + %d 因果残片" % int(node.fragment_cost)
		if anchor_needed:
			cost_text = "锚定%s：8 碎片 + 1 因果残片\n%s" % [GameProgress.PATHWAY_NAMES[str(node.path)], cost_text]
		elif locked_path:
			cost_text = "已选择%s职业" % GameState.get_pathway_name()
		elif missing_requirement:
			cost_text = "需先锚定前置节点"
		button.text = "%s%s\n%s" % ["✓ " if unlocked else "", str(node.name), "已锚定" if unlocked else cost_text]
		button.disabled = unlocked or locked_path or missing_requirement or GameState.echo_shards < int(node.cost) + (8 if anchor_needed else 0) or GameState.causality_fragments < int(node.get("fragment_cost", 0)) + (1 if anchor_needed else 0)
		button.pressed.connect(_unlock_path_node.bind(node_id))
		content.add_child(button)
	if not GameState.selected_pathway.is_empty():
		_mobile_terminal_section(content, "战斗流派 · 四选一", "职业决定身份，流派决定实际打法。解锁后可随时切换已拥有流派。")
		for style_id in ExchangeEvolution.COMBAT_STYLES:
			var style: Dictionary = ExchangeEvolution.COMBAT_STYLES[style_id]
			if str(style.path) != GameState.selected_pathway:
				continue
			var style_button := Button.new()
			var unlocked_style := GameState.unlocked_combat_styles.has(style_id)
			style_button.custom_minimum_size = Vector2(0, 58)
			style_button.text = "%s%s\n%s" % ["▶ " if GameState.active_combat_style == style_id else ("✓ " if unlocked_style else ""), str(style.name), "点击切换" if unlocked_style else "%s · 5 回响" % str(style.description)]
			style_button.disabled = not unlocked_style and (not GameState.has_path_node(str(style.requires)) or GameState.echo_shards < 5)
			style_button.pressed.connect(_toggle_combat_style.bind(style_id))
			content.add_child(style_button)
	var respec := Button.new()
	respec.custom_minimum_size = Vector2(0, 52)
	respec.text = "重构职业 · 1 因果残片（可无限次）"
	respec.disabled = GameState.selected_pathway.is_empty()
	respec.pressed.connect(_respec_pathway)
	content.add_child(respec)
	var actions := HBoxContainer.new()
	actions.name = "FixedActions"
	actions.position = Vector2(14, mobile_terminal_panel.size.y - 72)
	actions.size = Vector2(panel_width - 28, 58)
	actions.add_theme_constant_override("separation", 10)
	mobile_terminal_panel.add_child(actions)
	var warehouse := Button.new()
	warehouse.text = "装备仓库"
	warehouse.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	warehouse.pressed.connect(_open_warehouse)
	actions.add_child(warehouse)
	var close := Button.new()
	close.text = "返回回廊"
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close.pressed.connect(_close_terminal)
	actions.add_child(close)


func _mobile_terminal_section(parent: VBoxContainer, title: String, body: String) -> void:
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 19)
	heading.add_theme_color_override("font_color", Color("6cd7c0"))
	parent.add_child(heading)
	var text := Label.new()
	text.text = body
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 15)
	text.add_theme_color_override("font_color", Color("a7bbb4"))
	parent.add_child(text)


func _curator_profile_text() -> String:
	var profile: Dictionary = GameState.player_profile
	var trial := GameState.get_curator_trial()
	var lines := [str(profile.get("last_observation", "尚无足够行动数据。")), "行动 %d · 成功 %d · 静默撤离 %d · 风险选择 %d · 清除威胁 %d" % [int(profile.get("runs", 0)), int(profile.get("successful_runs", 0)), int(profile.get("quiet_successes", 0)), int(profile.get("events_taken", 0)), int(profile.get("threats_cleared", 0))]]
	lines.append("依据：%s" % "；".join(GameState.curator_evidence()))
	lines.append(_humanity_summary())
	var assessment := GameState.humanity_reflection()
	lines.append(str(assessment.get("trailer", "")))
	lines.append("世界简报：%s" % "；".join(GameState.world_briefing()))
	lines.append("成长计划：%s" % " → ".join(GameState.get_growth_plan()))
	if not GameState.heart_aspect.is_empty():
		lines.append("心相：%s：%s" % [str(GameState.heart_aspect.name), str(GameState.heart_aspect.description)])
	if not trial.is_empty():
		lines.append("试炼：%s：%s · 奖励 %s" % [trial.title, trial.description, trial.reward_text])
	var recent: Array = profile.get("recent_runs", [])
	for run in recent:
		lines.append("%s · %s · 噪音%d · 事件%d" % ["地铁" if str(run.get("world", "")) == "metro" else "疗养院", "撤离" if bool(run.get("success", false)) else "失联", int(run.get("noise", 0)), int(run.get("events", 0))])
	return "\n".join(lines)


func _humanity_summary() -> String:
	var assessment := GameState.humanity_reflection()
	var profile: Dictionary = assessment.get("profile", {})
	var dimensions: Dictionary = profile.get("dimensions", {})
	var echo: Dictionary = assessment.get("echo", {})
	if str(echo.get("id", "")) == "unformed_echo":
		return "人性回声：未成形（有效行为样本不足；不作人格判断）"
	var dimension := str(echo.get("dimension", ""))
	var result: Dictionary = dimensions.get(dimension, {})
	var evidence: Array = result.get("evidence", []) if int(result.get("score", 0)) > 0 else result.get("counter_evidence", [])
	var evidence_text := "暂无"
	if not evidence.is_empty():
		evidence_text = "%s / %s" % [str(evidence[-1].get("event_type", "")), str(evidence[-1].get("world_id", ""))]
	var knowledge: Array = result.get("knowledge", [])
	var source_text := "知识条目待补充"
	if not knowledge.is_empty():
		source_text = "%s（%s）" % [str(knowledge[0].get("title", "")), str(knowledge[0].get("source", ""))]
	return "人性回声：%s · %s · 置信度 %d%%\n行为依据：%s\n知识依据：%s\n仅反映游戏选择，不是现实人格或心理诊断。" % [
		str(echo.get("name", "")), str(result.get("interpretation", "")),
		int(round(float(result.get("confidence", 0.0)) * 100.0)), evidence_text, source_text,
	]


func _accept_trial() -> void:
	feedback.text = "阈值司仪：试炼已采纳；依据、条件与奖励均已写入档案。" if GameState.accept_curator_trial() else "阈值司仪：当前世界可用试炼均已完成或暂缓。"
	_refresh()


func _dismiss_trial() -> void:
	feedback.text = "阈值司仪：已暂缓该方向，不会重复强制提示。" if GameState.dismiss_curator_trial() else "当前没有可暂缓的试炼。"
	_refresh()
	if curator_contract_panel and curator_contract_panel.visible:
		_refresh_curator_contract_panel()


func _reset_curator_profile() -> void:
	GameState.reset_curator_profile()
	feedback.text = "阈值司仪观察已重置；装备、货币与职业成长未改变。"
	_refresh()


func _respec_pathway() -> void:
	feedback.text = "职业锚点已重构；已返还全部职业投入（锚定、节点碎片与节点残片），并扣除 1 因果残片重构费。" if GameState.respec_pathway() else "无法重构：每个存档仅限一次，并需要 1 因果残片。"
	_refresh()


func _hub_stick_center() -> Vector2:
	return Vector2(106.0, size.y - _hub_control_bottom_inset())


func _hub_action_center() -> Vector2:
	return Vector2(size.x - 104.0, size.y - _hub_control_bottom_inset())


func _hub_control_bottom_inset() -> float:
	# Keep both circles and their captions above the one- or two-row navigation
	# bar. The old fixed 108 px inset placed them behind the function buttons.
	return 240.0 if hub_navigation and hub_navigation.columns == 4 else 178.0


func _draw_mobile_hub_controls() -> void:
	var stick := _hub_stick_center()
	var action := _hub_action_center()
	var knob := stick + _touch_direction * 58.0
	draw_circle(stick, 72.0, Color(0.025, 0.12, 0.1, 0.8))
	draw_arc(stick, 72.0, 0.0, TAU, 48, Color("478f80"), 3.0)
	draw_circle(knob, 28.0, Color("5acdb5"))
	draw_circle(action, 58.0, Color(0.035, 0.16, 0.14, 0.92))
	draw_arc(action, 58.0, 0.0, TAU, 48, Color("69e4cd"), 4.0)
	if _hub_action_touch != -1:
		draw_circle(action, 48.0, Color(0.35, 0.92, 0.8, 0.28))
	draw_string(UI_FONT, action + Vector2(-12, 9), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("8bf1db"))
	draw_string(UI_FONT, stick + Vector2(-27, 104), "移动", HORIZONTAL_ALIGNMENT_CENTER, 54, 14, Color("8db8ad"))
	draw_string(UI_FONT, action + Vector2(-27, 84), "交互", HORIZONTAL_ALIGNMENT_CENTER, 54, 14, Color("8db8ad"))


func _create_hub_navigation() -> void:
	hub_navigation = GridContainer.new()
	hub_navigation.name = "IndependentHubNavigation"
	hub_navigation.columns = 8
	hub_navigation.z_index = 190
	add_child(hub_navigation)
	var entries := [
		["equipment", "装备", 0],
		["materials", "材料", 1],
		["collection", "唯一藏品", 2],
		["archive", "档案", 3],
		["career", "职业", 4],
		["dungeons", "副本", 5],
		["terminal", "终端", 6],
	]
	for index in range(entries.size()):
		var entry: Array = entries[index]
		var button := Button.new()
		button.name = "Hub%s" % str(entry[0]).capitalize()
		button.text = str(entry[1])
		button.add_theme_font_size_override("font_size", 15)
		button.icon = _hub_section_icon(int(entry[2]))
		button.expand_icon = false
		button.pressed.connect(_open_hub_section.bind(str(entry[0])))
		hub_navigation.add_child(button)


func _hub_section_icon(index: int) -> Texture2D:
	if HUB_SECTION_ICONS == null or HUB_SECTION_ICONS.get_size() != Vector2(224, 32):
		return null
	var icon := AtlasTexture.new()
	icon.atlas = HUB_SECTION_ICONS
	icon.region = Rect2(index * 32, 0, 32, 32)
	return icon


func _create_section_panel() -> void:
	section_panel = ColorRect.new()
	section_panel.name = "IndependentSection"
	section_panel.color = Color(0.007, 0.032, 0.029, 0.995)
	section_panel.visible = false
	section_panel.z_index = 240
	add_child(section_panel)
	section_title = Label.new()
	section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section_title.add_theme_font_size_override("font_size", 27)
	section_title.add_theme_color_override("font_color", Color("62dec6"))
	section_panel.add_child(section_title)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	section_panel.add_child(scroll)
	section_content = VBoxContainer.new()
	section_content.add_theme_constant_override("separation", 10)
	scroll.add_child(section_content)
	var close := Button.new()
	close.name = "Close"
	close.text = "返回回廊"
	close.pressed.connect(func(): section_panel.visible = false)
	section_panel.add_child(close)


func _close_hub_surfaces() -> void:
	if warehouse_panel:
		warehouse_panel.visible = false
	if run_archive_panel:
		run_archive_panel.visible = false
	if mirror_panel:
		mirror_panel.visible = false
	if section_panel:
		section_panel.visible = false
	if curator_contract_panel:
		curator_contract_panel.visible = false
	if _terminal_is_open():
		_close_terminal()


func _close_top_surface() -> bool:
	if audio_settings_panel and audio_settings_panel.visible:
		audio_settings_panel.hide()
		return true
	if curator_contract_panel and curator_contract_panel.visible:
		_close_curator_contract_panel()
		return true
	if salvage_reward_panel and salvage_reward_panel.visible:
		salvage_reward_panel.visible = false
		return true
	if warehouse_panel and warehouse_panel.visible:
		warehouse_panel.visible = false
		return true
	if run_archive_panel and run_archive_panel.visible:
		run_archive_panel.visible = false
		return true
	if mirror_panel and mirror_panel.visible:
		mirror_panel.visible = false
		return true
	if section_panel and section_panel.visible:
		section_panel.visible = false
		return true
	if _terminal_is_open():
		_close_terminal()
		return true
	return false


func _open_hub_section(section: String) -> void:
	_close_hub_surfaces()
	match section:
		"equipment":
			_open_warehouse()
			return
	for child in section_content.get_children():
		child.queue_free()
	match section:
		"materials": _build_material_section()
		"collection": _build_collection_section()
		"archive": _build_world_archive_section()
		"career": _build_career_section()
		"dungeons": _build_dungeon_section()
		"terminal": _build_exchange_section()
	section_panel.visible = true
	_layout_section_panel(get_viewport_rect().size)


func _section_heading(text: String, body := "") -> void:
	var heading := Label.new()
	heading.text = text
	heading.add_theme_font_size_override("font_size", 20)
	heading.add_theme_color_override("font_color", Color("76dcc5"))
	section_content.add_child(heading)
	if not body.is_empty():
		var detail := Label.new()
		detail.text = body
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_theme_font_size_override("font_size", 15)
		detail.add_theme_color_override("font_color", Color("b8cec6"))
		section_content.add_child(detail)


func _progression_icon(row: int, column: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = PROGRESSION_STATUS_ICONS
	texture.region = Rect2(clampi(column, 0, 5) * 32, clampi(row, 0, 2) * 32, 32, 32)
	return texture


func _affix_icon_index(affix_id: String) -> int:
	return ["guardian", "last_round", "suppression", "volatile", "perception", "restoration"].find(affix_id)


func _create_milestone_feedback() -> void:
	milestone_feedback = TextureRect.new()
	milestone_feedback.name = "MilestoneFeedback"
	milestone_feedback.size = Vector2(210, 210)
	milestone_feedback.position = Vector2((size.x - 210.0) * 0.5, 150)
	milestone_feedback.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	milestone_feedback.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	milestone_feedback.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	milestone_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	milestone_feedback.z_index = 500
	milestone_feedback.visible = false
	add_child(milestone_feedback)
	milestone_caption = Label.new()
	milestone_caption.position = Vector2(-120, 178)
	milestone_caption.size = Vector2(450, 42)
	milestone_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	milestone_caption.add_theme_font_override("font", UI_FONT)
	milestone_caption.add_theme_font_size_override("font_size", 22)
	milestone_caption.add_theme_color_override("font_color", Color("d9ece6"))
	milestone_caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	milestone_feedback.add_child(milestone_caption)


func _show_milestone(index: int, caption: String) -> void:
	(get_node("/root/AudioDirector") as DreadboundAudioDirector).play("success")
	if milestone_feedback == null or MILESTONE_FEEDBACK == null or MILESTONE_FEEDBACK.get_size() != Vector2(768, 192):
		return
	var texture := AtlasTexture.new()
	texture.atlas = MILESTONE_FEEDBACK
	texture.region = Rect2(clampi(index, 0, 3) * 192, 0, 192, 192)
	milestone_feedback.texture = texture
	milestone_feedback.position = Vector2((size.x - 210.0) * 0.5, 150)
	milestone_feedback.modulate = Color(1, 1, 1, 0)
	milestone_feedback.scale = Vector2(0.72, 0.72)
	milestone_feedback.visible = true
	milestone_caption.text = caption
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(milestone_feedback, "modulate", Color.WHITE, 0.18)
	tween.tween_property(milestone_feedback, "scale", Vector2.ONE, 0.22)
	tween.chain().tween_interval(1.2)
	tween.chain().set_parallel(true)
	tween.tween_property(milestone_feedback, "modulate", Color(1, 1, 1, 0), 0.35)
	tween.tween_property(milestone_feedback, "position:y", 124.0, 0.35)
	tween.chain().tween_callback(func(): milestone_feedback.visible = false)


func _create_icon_card(icon_texture: Texture2D, title_text: String, subtitle_text: String, action: Callable, badge_index := -1) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(116, 112)
	card.focus_mode = Control.FOCUS_NONE
	card.tooltip_text = "%s · %s" % [title_text, subtitle_text]
	card.pressed.connect(action)
	var icon := TextureRect.new()
	icon.position = Vector2(32, 8)
	icon.size = Vector2(52, 52)
	icon.texture = icon_texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon)
	if badge_index >= 0:
		var badge := TextureRect.new()
		badge.position = Vector2(78, 5)
		badge.size = Vector2(28, 28)
		badge.texture = _progression_icon(0, badge_index)
		badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(badge)
	var title := Label.new()
	title.position = Vector2(5, 64)
	title.size = Vector2(106, 24)
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 13)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(title)
	var subtitle := Label.new()
	subtitle.position = Vector2(5, 87)
	subtitle.size = Vector2(106, 18)
	subtitle.text = subtitle_text
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color("87b7ad"))
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(subtitle)
	return card


func _build_material_section() -> void:
	section_title.text = "材料背包"
	_section_heading("独立容量", "材料不占用装备仓库格位；每种材料上限 %d。副本中拾取的材料只有成功撤离后才会入库。" % GameProgress.MAX_MATERIAL_STACK)
	var grid := GridContainer.new()
	grid.name = "MaterialGrid"
	grid.columns = 6 if get_viewport_rect().size.x >= 800.0 else 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	section_content.add_child(grid)
	for world_id in ["sanatorium", "metro"]:
		for material_id in ExchangeEvolution.MATERIALS:
			var material: Dictionary = ExchangeEvolution.MATERIALS[material_id]
			if str(material.world) != world_id:
				continue
			var icon_texture: Texture2D = MATERIAL_ICONS.get(material_id, UNKNOWN_MATERIAL_ICON)
			var amount := int(GameState.world_materials.get(material_id, 0))
			grid.add_child(_create_icon_card(
				icon_texture,
				str(material.name),
				"×%d · %s" % [amount, str(material.rarity)],
				_select_material.bind(str(material_id))
			))
	var detail_row := HBoxContainer.new()
	detail_row.name = "MaterialDetail"
	detail_row.custom_minimum_size = Vector2(0, 145)
	detail_row.add_theme_constant_override("separation", 20)
	section_content.add_child(detail_row)
	material_detail_icon = TextureRect.new()
	material_detail_icon.custom_minimum_size = Vector2(112, 112)
	material_detail_icon.texture = UNKNOWN_MATERIAL_ICON
	material_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	material_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	material_detail_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	detail_row.add_child(material_detail_icon)
	material_detail = Label.new()
	material_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	material_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	material_detail.add_theme_font_size_override("font_size", 16)
	material_detail.add_theme_color_override("font_color", Color("c2dbd3"))
	detail_row.add_child(material_detail)
	_select_material("tissue_sample")


func _select_material(material_id: String) -> void:
	if material_detail == null or material_detail_icon == null:
		return
	var material: Dictionary = ExchangeEvolution.MATERIALS.get(material_id, {})
	if material.is_empty():
		return
	var amount := int(GameState.world_materials.get(material_id, 0))
	var world_name := "废弃疗养院" if str(material.world) == "sanatorium" else "潮没末班线"
	material_detail_icon.texture = MATERIAL_ICONS.get(material_id, UNKNOWN_MATERIAL_ICON)
	material_detail.text = "%s  ×%d\n%s · %s · %s\n\n来源：%s\n用途：%s\n叙事：%s" % [
		str(material.name), amount, world_name, str(material.rarity), str(material.category),
		str(material.source), str(material.use),
		str(narrative_catalog.material(material_id).get("meaning", "尚无归档解释。")),
	]


func _build_collection_section() -> void:
	section_title.text = "唯一藏品与成长遗物"
	var acquired := 0
	for item_id in EquipmentDatabase.ITEMS:
		var item: Dictionary = EquipmentDatabase.ITEMS[item_id]
		if not bool(item.get("unique", false)):
			continue
		var owned := GameState.equipment_inventory.has(item_id)
		acquired += 1 if owned else 0
		var state_text := "已收容" if owned else "未发现"
		var growth := ""
		if item.has("series"):
			growth = " · 成长 Lv.%d/%d" % [GameState.get_relic_growth(item_id), int(item.growth_max)]
		var lore := narrative_catalog.unique_item(str(item_id))
		var body := "世界唯一物品；发现前只显示编号 %s 与来源世界。" % str(lore.get("serial", "UNKNOWN"))
		if owned:
			var growth_stages: Array[String] = []
			for stage in lore.get("growth", []):
				growth_stages.append("· %s" % str(stage))
			var evolution_lines: Array[String] = []
			for evolution_id in lore.get("evolutions", {}):
				evolution_lines.append("· %s" % str(lore.evolutions[evolution_id]))
			body = "%s\n\n编号：%s\n起源：%s\n唯一性：%s\n取得：%s\n选择绑定：%s\n能力代价：%s\n\n成长阶段：\n%s\n\n进化含义：\n%s\n\nNPC 反应：%s\n遗失后果：%s\n重复首领：%s" % [
				str(item.description), str(lore.get("serial", "")),
				str(lore.get("origin", "")), str(lore.get("uniqueness", "")),
				str(lore.get("acquisition", "")), str(lore.get("choice_binding", "")),
				str(lore.get("cost", "")), "\n".join(growth_stages), "\n".join(evolution_lines),
				str(lore.get("npc_reactions", "")), str(lore.get("loss", "")),
				str(lore.get("repeat_defeat", "")),
			]
		_section_heading("%s  [%s]%s" % [str(item.name), state_text, growth], body)
	_section_heading("收集进度", "%d / %d。唯一物品不会进入合成输入，也不会因仓库溢出而产生复制品。" % [acquired, EquipmentDatabase.ITEMS.values().filter(func(item): return bool(item.get("unique", false))).size()])


func _build_world_archive_section() -> void:
	section_title.text = "世界与叙事档案"
	var identity := narrative_catalog.identity()
	_section_heading(str(identity.get("title", "Dreadbound")), "%s\n\n%s" % [str(identity.get("genre", "")), str(identity.get("positioning", ""))])
	var curator_row := HBoxContainer.new()
	var curator_portrait := TextureRect.new()
	curator_portrait.custom_minimum_size = Vector2(112, 112)
	var curator_texture := AtlasTexture.new()
	curator_texture.atlas = STORY_NPC_PORTRAITS
	curator_texture.region = Rect2(0, 0, 192, 192)
	curator_portrait.texture = curator_texture
	curator_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	curator_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	curator_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	curator_row.add_child(curator_portrait)
	var curator_text := Label.new()
	curator_text.text = "阈值司仪\n记录行动证据、世界变化与未完成的代价。"
	curator_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	curator_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	curator_text.add_theme_font_size_override("font_size", 16)
	curator_text.add_theme_color_override("font_color", Color("b8cec6"))
	curator_row.add_child(curator_text)
	section_content.add_child(curator_row)
	_add_codex_button("世界底层法则 · %d 条" % narrative_catalog.data.get("world_rules", {}).size(), "rules")
	_add_codex_button("四大阵营 · 信条与代价", "factions")
	_add_codex_button("行者编组 · 职责、资源与失联", "squad")
	_add_codex_button("全局主线 · 当前可知部分", "main_story")
	for world_id in ["sanatorium", "metro"]:
		var world := narrative_catalog.dungeon(world_id)
		var state: Dictionary = GameState.persistent_dungeons.dungeons.get(world_id, {})
		var progress := "未进入" if int(state.get("visits", 0)) <= 0 else "进入 %d 次 · 撤离 %d 次 · 首领击败 %d 次" % [
			int(state.get("visits", 0)), int(state.get("completed_runs", 0)), int(state.get("boss_state", {}).get("defeats", 0)),
		]
		_add_codex_button("%s / %s\n%s" % [str(world.get("name", world_id)), str(world.get("english_name", "")), progress], "dungeon:%s" % world_id)
	_section_heading("行动结算档案", "右上角“行动档案”继续保存最近一次行动、人性洞察与世界变化；本入口只呈现正式世界观与逐步解锁的真相。")


func _add_codex_button(text: String, entry_id: String) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 58)
	button.text = text
	button.pressed.connect(_open_codex_entry.bind(entry_id))
	section_content.add_child(button)


func _open_codex_entry(entry_id: String) -> void:
	for child in section_content.get_children():
		child.queue_free()
	var back := Button.new()
	back.text = "← 返回世界档案目录"
	back.pressed.connect(_open_hub_section.bind("archive"))
	section_content.add_child(back)
	match entry_id:
		"rules":
			section_title.text = "终末回廊底层法则"
			for rule_id in narrative_catalog.data.get("world_rules", {}):
				var rule := narrative_catalog.world_rule(str(rule_id))
				_section_heading(str(rule.get("title", rule_id)), "%s\n未决问题：%s" % [str(rule.get("rule", "")), str(rule.get("uncertainty", ""))])
		"factions":
			section_title.text = "四大阵营"
			for faction_id in narrative_catalog.data.get("factions", {}):
				var faction := narrative_catalog.faction(str(faction_id))
				_section_heading(str(faction.get("name", faction_id)), "信条：%s\n方式：%s\n提供：%s\n代价：%s\n核心冲突：%s" % [
					str(faction.get("creed", "")), str(faction.get("method", "")), str(faction.get("offer", "")),
					str(faction.get("price", "")), str(faction.get("conflict", "")),
				])
		"squad":
			section_title.text = "行者编组"
			var squad_data := narrative_catalog.squad()
			var formation: Dictionary = squad_data.get("formation", {})
			_section_heading(str(squad_data.get("name", "行者编组")), "%s · %s\n%s" % [str(formation.get("size", "")), str(formation.get("principle", "")), str(formation.get("leadership", ""))])
			for role_id in squad_data.get("roles", {}):
				var role: Dictionary = squad_data.roles[role_id]
				_section_heading(str(role.get("name", role_id)), "职责：%s\n失责：%s" % [str(role.get("duty", "")), str(role.get("failure", ""))])
			_section_heading("资源归属", "\n".join(squad_data.get("resource_rules", [])))
			_section_heading("失联与背叛", "%s\n\n%s" % ["\n".join(squad_data.get("loss_rules", [])), "\n".join(squad_data.get("betrayal_rules", []))])
		"main_story":
			section_title.text = "全局主线"
			var story := narrative_catalog.main_story()
			_section_heading("核心问题", str(story.get("question", "")))
			for act in story.get("acts", []):
				_section_heading(str(act.get("title", "")), "解锁条件：%s\n已知揭示：%s" % [str(act.get("condition", "")), str(act.get("reveal", ""))])
			_section_heading("阈值司仪", str(story.get("curator_position", "")))
		_:
			if entry_id.begins_with("dungeon:"):
				_build_dungeon_codex(entry_id.trim_prefix("dungeon:"))
	_layout_section_panel(get_viewport_rect().size)


func _build_dungeon_codex(world_id: String) -> void:
	var world := narrative_catalog.dungeon(world_id)
	var dungeon_state: Dictionary = GameState.persistent_dungeons.dungeons.get(world_id, {})
	section_title.text = str(world.get("name", world_id))
	_add_archive_illustration(world_id, dungeon_state)
	_section_heading("投送简介", str(world.get("short_intro", "")))
	_section_heading("完整故事", str(world.get("full_story", "")))
	_section_heading("核心恐惧", str(world.get("core_fear", "")))
	_section_heading("异常法则", str(world.get("anomaly_law", "")))
	_section_heading("投送目标", str(world.get("mission", "")))
	_section_heading("Boss 真相", str(world.get("boss_truth", "")))
	_section_heading("隐藏区域与结局", "%s\n\n可能结局：%s" % [str(world.get("hidden_area", "")), " / ".join(world.get("possible_endings", []))])
	var current_chapter_id := str(dungeon_state.get("chapter", "first_arrival"))
	var current_chapter: Dictionary = world.get("chapters", {}).get(current_chapter_id, {})
	_section_heading("当前剧情走向", "当前章节：%s\n%s\n\n进入 %d 次 · 成功撤离 %d 次" % [
		str(current_chapter.get("title", current_chapter_id)), str(current_chapter.get("briefing", "")),
		int(dungeon_state.get("visits", 0)), int(dungeon_state.get("completed_runs", 0)),
	])
	for chapter_id in world.get("chapters", {}):
		var chapter: Dictionary = world.chapters[chapter_id]
		var known: bool = chapter_id == "first_arrival" or chapter_id == current_chapter_id or dungeon_state.get("completed_events", []).any(func(event_id): return str(event_id).begins_with("%s:" % chapter_id))
		var choice_labels: Array[String] = []
		for choice in chapter.get("choices", []):
			choice_labels.append(str(choice.get("label", "")))
		_section_heading("%s%s" % ["▶ " if chapter_id == current_chapter_id else "", str(chapter.get("title", chapter_id)) if known else "未解锁章节"], "%s\n选择：%s" % [
			str(chapter.get("briefing", "")) if known else "由前一章的承诺、背叛、救援或阵营归属决定。",
			" / ".join(choice_labels) if known else "尚未显现",
		])
	if not dungeon_state.get("history", []).is_empty():
		var history_lines: Array[String] = []
		for entry in dungeon_state.get("history", []).slice(0, 8):
			if str(entry.get("choice", "")) not in ["extracted", "lost"]:
				history_lines.append("第 %d 次 · %s" % [int(entry.get("visit", 0)), str(entry.get("summary", ""))])
		_section_heading("已经发生的选择", "\n".join(history_lines) if not history_lines.is_empty() else "尚无关键剧情选择。")
	_section_heading("逐步解锁的真相档案", "正式事实不会由随机叙事改写；未解锁条目只显示来源。")
	for record in world.get("truth_records", []):
		var unlocked := _truth_record_unlocked(world_id, record)
		_section_heading("%s  [%s]" % [str(record.get("title", "")), "已解锁" if unlocked else "未解锁"], "%s\n%s" % [
			str(record.get("perspective", "")),
			str(record.get("text", "")) if unlocked else _truth_unlock_hint(record.get("unlock", {})),
		])
	_section_heading("回廊主线线索", str(world.get("main_story_clue", "")) if int(GameState.persistent_dungeons.dungeons.get(world_id, {}).get("visits", 0)) >= 2 else "需要至少两次进入该世界。")


func _add_archive_illustration(world_id: String, dungeon_state: Dictionary) -> void:
	if ARCHIVE_ILLUSTRATIONS == null or ARCHIVE_ILLUSTRATIONS.get_size() != Vector2(768, 288):
		return
	var local_index := 0
	if int(dungeon_state.get("boss_state", {}).get("defeats", 0)) > 0:
		local_index = 1
	elif int(dungeon_state.get("completed_runs", 0)) > 0:
		local_index = 2
	var index := local_index + (3 if world_id == "metro" else 0)
	var image := TextureRect.new()
	image.custom_minimum_size = Vector2(0, 238)
	var texture := AtlasTexture.new()
	texture.atlas = ARCHIVE_ILLUSTRATIONS
	texture.region = Rect2((index % 3) * 256, floori(float(index) / 3.0) * 144, 256, 144)
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	section_content.add_child(image)


func _truth_record_unlocked(world_id: String, record: Dictionary) -> bool:
	var unlock: Dictionary = record.get("unlock", {})
	var dungeon: Dictionary = GameState.persistent_dungeons.dungeons.get(world_id, {})
	match str(unlock.get("kind", "")):
		"visit": return int(dungeon.get("visits", 0)) >= int(unlock.get("count", 1))
		"completed_run": return int(dungeon.get("completed_runs", 0)) >= int(unlock.get("count", 1))
		"boss_defeat": return int(dungeon.get("boss_state", {}).get("defeats", 0)) >= int(unlock.get("count", 1))
		"area": return dungeon.get("opened_areas", []).has(str(unlock.get("id", "")))
	return false


func _truth_unlock_hint(unlock: Dictionary) -> String:
	match str(unlock.get("kind", "")):
		"visit": return "进入该世界 %d 次后解锁。" % int(unlock.get("count", 1))
		"completed_run": return "成功撤离该世界 %d 次后解锁。" % int(unlock.get("count", 1))
		"boss_defeat": return "击败该世界首领 %d 次后解锁。" % int(unlock.get("count", 1))
		"area": return "发现对应隐藏区域后解锁。"
	return "继续探索以解锁。"


func _build_career_section() -> void:
	section_title.text = "职业锚点与战斗流派"
	_section_heading("当前职业", "%s · 当前流派：%s" % [GameState.get_pathway_name(), str(ExchangeEvolution.COMBAT_STYLES.get(GameState.active_combat_style, {}).get("name", "未选择"))])
	if not GameState.heart_aspect.is_empty():
		var heart_ids := ["watch", "last_breath", "broken_oath", "seek_gap", "contain_abyss", "finale"]
		var heart_row := HBoxContainer.new()
		var heart_icon := TextureRect.new()
		heart_icon.custom_minimum_size = Vector2(58, 58)
		heart_icon.texture = _progression_icon(1, maxi(0, heart_ids.find(str(GameState.heart_aspect.get("id", "")))))
		heart_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		heart_row.add_child(heart_icon)
		var heart_text := Label.new()
		heart_text.text = "%s\n%s" % [str(GameState.heart_aspect.get("name", "未成形心相")), str(GameState.heart_aspect.get("description", ""))]
		heart_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		heart_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heart_text.add_theme_color_override("font_color", Color("c8b8df"))
		heart_row.add_child(heart_text)
		section_content.add_child(heart_row)
	for node_id in GameProgress.PATH_NODES:
		var node: Dictionary = GameProgress.PATH_NODES[node_id]
		if (GameState.selected_pathway.is_empty() and not str(node.get("requires", "")).is_empty()) or (not GameState.selected_pathway.is_empty() and str(node.path) != GameState.selected_pathway):
			continue
		var button := Button.new()
		var unlocked := GameState.unlocked_path_nodes.has(node_id)
		button.text = "%s%s\n%s" % ["✓ " if unlocked else "", str(node.name), "已锚定" if unlocked else str(node.description)]
		button.disabled = unlocked
		button.pressed.connect(func():
			_unlock_path_node(node_id)
			_open_hub_section("career")
		)
		section_content.add_child(button)
	if not GameState.selected_pathway.is_empty():
		_section_heading("战斗流派", "职业决定身份；流派可在已解锁项目之间切换。")
		for style_id in ExchangeEvolution.COMBAT_STYLES:
			var style: Dictionary = ExchangeEvolution.COMBAT_STYLES[style_id]
			if str(style.path) != GameState.selected_pathway:
				continue
			var style_button := Button.new()
			var unlocked_style := GameState.unlocked_combat_styles.has(style_id)
			style_button.text = "%s%s\n%s" % ["▶ " if GameState.active_combat_style == style_id else ("✓ " if unlocked_style else ""), str(style.name), "点击切换" if unlocked_style else "%s · 5 回响" % str(style.description)]
			style_button.disabled = not unlocked_style and (not GameState.has_path_node(str(style.requires)) or GameState.echo_shards < 5)
			style_button.pressed.connect(func():
				_toggle_combat_style(style_id)
				_open_hub_section("career")
			)
			section_content.add_child(style_button)


func _build_dungeon_section() -> void:
	section_title.text = "灾难副本与投送"
	_section_heading("当前投送", "%s · %s\n副本选择、难度和出发集中在此入口。" % [_world_name(), str(GameState.get_difficulty().name)])
	for world_id in ["sanatorium", "metro"]:
		var world := narrative_catalog.dungeon(world_id)
		var state: Dictionary = GameState.persistent_dungeons.dungeons.get(world_id, {})
		var chapter_id := str(state.get("chapter", "first_arrival"))
		var chapter: Dictionary = world.get("chapters", {}).get(chapter_id, {})
		_section_heading(str(world.get("name", world_id)), "%s\n核心恐惧：%s\n当前剧情：%s · %s" % [
			str(world.get("short_intro", "")), str(world.get("core_fear", "")),
			str(chapter.get("title", chapter_id)), str(chapter.get("briefing", "")),
		])
		var story_button := Button.new()
		story_button.text = "查看完整故事、章节走向与真相档案"
		story_button.pressed.connect(_open_codex_entry.bind("dungeon:%s" % world_id))
		section_content.add_child(story_button)
		var world_button_entry := Button.new()
		world_button_entry.text = "%s选择 %s" % ["▶ " if GameState.selected_world == world_id else "", str(world.get("name", world_id))]
		world_button_entry.pressed.connect(func():
			GameState.selected_world = world_id
			GameState.save_progress()
			_open_hub_section("dungeons")
		)
		section_content.add_child(world_button_entry)
	var difficulty := Button.new()
	difficulty.text = "切换难度：%s\n%s" % [str(GameState.get_difficulty().name), str(GameState.get_difficulty().description)]
	difficulty.pressed.connect(func():
		_cycle_difficulty()
		_open_hub_section("dungeons")
	)
	section_content.add_child(difficulty)
	var deploy := Button.new()
	deploy.text = "建立连接并进入%s" % _world_name()
	deploy.pressed.connect(_deploy)
	section_content.add_child(deploy)


func _build_exchange_section() -> void:
	section_title.text = "异常兑换与合成终端"
	_section_heading("轮换 %d" % GameState.exchange_cycle, "终端只处理兑换与合成；装备管理、材料查看、职业成长和副本投送均已拆分到独立入口。")
	for offer in GameState.get_exchange_offers():
		var offer_button := Button.new()
		offer_button.text = "兑换 %s · %d 回响" % [str(offer.name), int(offer.echo_cost)]
		offer_button.disabled = GameState.echo_shards < int(offer.echo_cost) or GameState.exchange_purchases.has("%d:%s" % [GameState.exchange_cycle, str(offer.id)])
		offer_button.pressed.connect(func():
			_purchase_exchange(str(offer.id))
			_open_hub_section("terminal")
		)
		section_content.add_child(offer_button)
	_section_heading("装备合成路径", "成本：消耗 3 件同槽位、同品质且未被保护的装备，不额外消耗回响。\n结果：品质提升 1 阶并锁定三个候选；放弃结果可获得余烬并提高该槽位保底。\n催化：额外消耗 1 份世界材料，使首个候选偏向该世界词条；锁定指定词条另需 1 因果残片。")
	var quality_names := ["制式", "改装", "回响", "异常"]
	var groups := _synthesis_groups()
	if groups.is_empty():
		_section_heading("当前没有可合成组合", "至少收集 3 件同槽同品质装备。已装备的唯一一件会保留，唯一物品和异常品质不能作为输入。")
	for key in groups:
		var group: Dictionary = groups[key]
		var source_rank := int(group.get("rank", 0))
		var candidates: Array = ExchangeEvolution.SYNTHESIS_POOLS.get("%s:%d" % [str(group.slot), source_rank + 1], [])
		var candidate_names: Array[String] = []
		for item_id in candidates:
			candidate_names.append(str(EquipmentDatabase.get_item(str(item_id)).get("name", item_id)))
		_section_heading("%s · %s → %s  [%d/3]" % [
			"武器" if str(group.slot) == "weapon" else "护符",
			quality_names[source_rank], quality_names[source_rank + 1], int(group.usable),
		], "候选池：%s" % " / ".join(candidate_names))
		if int(group.usable) < 3:
			continue
		var basic := Button.new()
		basic.text = "消耗 3 件开始合成 · 不使用催化"
		basic.pressed.connect(_run_synthesis_group.bind(str(key), ""))
		section_content.add_child(basic)
		for material_id in ExchangeEvolution.MATERIALS:
			var material: Dictionary = ExchangeEvolution.MATERIALS[material_id]
			if str(material.world) != GameState.selected_world or int(GameState.world_materials.get(material_id, 0)) <= 0:
				continue
			var catalyst := Button.new()
			catalyst.text = "消耗 3 件 + %s ×1（持有 %d）" % [str(material.name), int(GameState.world_materials.get(material_id, 0))]
			catalyst.pressed.connect(_run_synthesis_group.bind(str(key), str(material_id)))
			section_content.add_child(catalyst)
	_section_heading("当前保底", "武器 %d/3 · 护符 %d/3 · 合成余烬 %d\n每次放弃三选一结果，获得余烬并提高对应槽位保底。" % [
		int(GameState.synthesis_pity.get("weapon", 0)), int(GameState.synthesis_pity.get("charm", 0)), GameState.synthesis_embers,
	])


func _synthesis_groups() -> Dictionary:
	var groups := {}
	for item_id in GameState.equipment_inventory:
		var item := EquipmentDatabase.get_item(str(item_id))
		if item.is_empty() or bool(item.get("unique", false)) or int(item.get("quality_rank", -1)) >= 3:
			continue
		var key := "%s:%d" % [str(item.slot), int(item.quality_rank)]
		if not groups.has(key):
			groups[key] = {"slot": str(item.slot), "rank": int(item.quality_rank), "items": [], "usable": 0}
		groups[key].items.append(str(item_id))
	for key in groups:
		var preserved := {}
		var usable := 0
		for item_id in groups[key].items:
			if GameState.equipped.values().has(item_id) and not bool(preserved.get(item_id, false)):
				preserved[item_id] = true
			else:
				usable += 1
		groups[key].usable = usable
	return groups


func _safe_synthesis_inputs(key: String) -> Array[String]:
	var group: Dictionary = _synthesis_groups().get(key, {})
	var result: Array[String] = []
	var preserved := {}
	for item_id in group.get("items", []):
		if GameState.equipped.values().has(item_id) and not bool(preserved.get(item_id, false)):
			preserved[item_id] = true
			continue
		result.append(str(item_id))
		if result.size() == 3:
			break
	return result


func _run_synthesis_group(key: String, catalyst_id: String) -> void:
	var inputs := _safe_synthesis_inputs(key)
	if inputs.size() != 3:
		feedback.text = "合成输入不足：需要 3 件同槽同品质、且未被装备保护的物品。"
		return
	if GameState.begin_synthesis(inputs, catalyst_id).is_empty():
		feedback.text = "合成失败：检查材料数量、仓库状态或是否已有待选结果。"
		return
	feedback.text = "合成结果已锁定：请在装备入口查看三个候选并选择。"
	_open_warehouse()


func _open_warehouse() -> void:
	selected_equipment_id = ""
	_refresh_warehouse()
	warehouse_panel.visible = true


func _refresh_warehouse() -> void:
	for child in warehouse_list.get_children():
		child.queue_free()
	warehouse_status.text = "装备 %d/%d · 合成余烬 %d · 点击格子查看详情" % [
		GameState.equipment_inventory.size(), GameProgress.MAX_EQUIPMENT, GameState.synthesis_embers,
	]
	if not GameState.pending_synthesis.is_empty():
		warehouse_status.text = "合成结果已锁定 · 从候选格中选择一项"
		var candidates: Array = GameState.pending_synthesis.get("candidates", [])
		for index in range(candidates.size()):
			var candidate: Dictionary = candidates[index]
			var candidate_item := EquipmentDatabase.get_item(str(candidate.item_id))
			var candidate_affix: Dictionary = ExchangeEvolution.AFFIXES.get(str(candidate.affix_id), {})
			warehouse_list.add_child(_create_icon_card(
				EQUIPMENT_ICONS.get(str(candidate.item_id), UNKNOWN_EQUIPMENT_ICON),
				str(candidate_item.name),
				"候选 · %s" % str(candidate_affix.get("name", "未知")),
				_choose_synthesis.bind(index),
				_affix_icon_index(str(candidate.affix_id)),
			))
		var reject := Button.new()
		reject.custom_minimum_size = Vector2(116, 112)
		reject.text = "放弃结果\n转为余烬"
		reject.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reject.pressed.connect(_reject_synthesis)
		warehouse_list.add_child(reject)
	else:
		var synthesize := Button.new()
		synthesize.custom_minimum_size = Vector2(116, 112)
		synthesize.text = "自动合成\n三件 → 三选一"
		synthesize.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		synthesize.pressed.connect(_auto_synthesis)
		warehouse_list.add_child(synthesize)
	var counts := {}
	for item_id in GameState.equipment_inventory:
		counts[item_id] = int(counts.get(item_id, 0)) + 1
	for item_id in counts:
		var item := EquipmentDatabase.get_item(item_id)
		var equipped_mark := "◆ " if GameState.equipped.values().has(item_id) else ""
		warehouse_list.add_child(_create_icon_card(
			EQUIPMENT_ICONS.get(str(item_id), UNKNOWN_EQUIPMENT_ICON),
			"%s%s" % [equipped_mark, str(item.name)],
			"×%d · %s" % [counts[item_id], str(item.quality)],
			_select_equipment.bind(str(item_id)),
			_affix_icon_index(str(GameState.equipment_affixes.get(item_id, ""))),
		))
	equip_button.disabled = true
	salvage_button.disabled = true
	progress_button.disabled = true
	progress_button.text = "升级 / 进化"
	warehouse_preview.texture = UNKNOWN_EQUIPMENT_ICON
	warehouse_detail.text = "点击装备格查看大图、评级、属性、强化与进化说明。"


func _apply_equipment_icon(button: Button, item_id: String) -> void:
	if not EQUIPMENT_ICONS.has(item_id):
		return
	button.icon = EQUIPMENT_ICONS[item_id]
	button.expand_icon = false


func _select_equipment(item_id: String) -> void:
	selected_equipment_id = item_id
	var item := EquipmentDatabase.get_item(item_id)
	warehouse_preview.texture = EQUIPMENT_ICONS.get(item_id, UNKNOWN_EQUIPMENT_ICON)
	var equipped_mark := "\n\n当前已装备" if GameState.is_item_equipped(item_id) else ""
	var level := GameState.get_relic_growth(item_id)
	var growth := "\n成长：Lv.%d/%d（击败对应首领可提升）\n当前形态：%s" % [level, int(item.get("growth_max", 0)), EquipmentDatabase.relic_growth_description(item_id, level)] if item.has("series") else ""
	var upgrade_level := int(GameState.equipment_levels.get(item_id, 0))
	var affix_id := str(GameState.equipment_affixes.get(item_id, ""))
	var affix_name := str(ExchangeEvolution.AFFIXES.get(affix_id, {}).get("name", "无"))
	var evolution := GameState.current_equipment_evolution(item_id)
	var evolution_name := str(evolution.get("name", "尚未进化"))
	warehouse_detail.text = "%s · %s\n评级 %d · 强化 Lv.%d/5\n词条：%s · 进化：%s\n槽位：%s\n\n%s\n\n%s%s%s" % [
		item.quality, item.name, item.rating, upgrade_level, affix_name, evolution_name,
		EquipmentDatabase.slot_label(item_id), item.description,
		_equipment_progression_guide(item_id), growth, equipped_mark,
	]
	equip_button.disabled = false
	salvage_button.disabled = GameState.equipped.values().has(item_id) and GameState.equipment_inventory.count(item_id) <= 1
	progress_button.disabled = false
	if upgrade_level < 5:
		var cost := GameState.equipment_upgrade_cost(item_id)
		progress_button.text = "强化至 Lv.%d\n%d 回响 + %d 余烬" % [upgrade_level + 1, int(cost.get("echo_shards", 0)), int(cost.get("synthesis_embers", 0))]
	else:
		progress_button.text = "查看 / 选择进化路径" if ExchangeEvolution.EVOLUTIONS.has(item_id) else "已满级 · 无进化分支"
		progress_button.disabled = not ExchangeEvolution.EVOLUTIONS.has(item_id)


func _equipment_progression_guide(item_id: String) -> String:
	var level := int(GameState.equipment_levels.get(item_id, 0))
	var lines: Array[String] = ["【成长路径】"]
	if level < 5:
		var cost := GameState.equipment_upgrade_cost(item_id)
		lines.append("下一步：强化 Lv.%d → Lv.%d" % [level, level + 1])
		lines.append("成本：%d 回响碎片 + %d 合成余烬（持有 %d / %d）" % [
			int(cost.get("echo_shards", 0)), int(cost.get("synthesis_embers", 0)),
			GameState.echo_shards, GameState.synthesis_embers,
		])
	else:
		lines.append("五级强化已完成。")
	if not ExchangeEvolution.EVOLUTIONS.has(item_id):
		lines.append("该装备没有独立进化分支；可通过合成获得更高品质与词条。")
		return "\n".join(lines)
	lines.append("进化前置：强化 Lv.5 + 对应行为熟练度 + 1 因果残片。")
	var mastery: Dictionary = GameState.equipment_mastery.get(item_id, {})
	for evolution_id in ExchangeEvolution.EVOLUTIONS[item_id]:
		var branch: Dictionary = ExchangeEvolution.EVOLUTIONS[item_id][evolution_id]
		var progress := int(mastery.get(str(branch.mastery), 0))
		lines.append("· %s：%s [%d/%d]" % [str(branch.name), str(branch.description), progress, int(branch.required)])
	return "\n".join(lines)


func _purchase_exchange(offer_id: String) -> void:
	feedback.text = "兑换完成，物资已写入仓库。" if GameState.purchase_exchange_offer(offer_id) else "兑换失败：检查回响、仓库容量或本轮限购。"
	_refresh_warehouse()
	_refresh()


func _auto_synthesis() -> void:
	var groups := {}
	for item_id in GameState.equipment_inventory:
		var item := EquipmentDatabase.get_item(item_id)
		if item.is_empty() or bool(item.get("unique", false)) or int(item.get("quality_rank", -1)) >= 3:
			continue
		var key := "%s:%d" % [str(item.slot), int(item.quality_rank)]
		if not groups.has(key):
			groups[key] = []
		groups[key].append(item_id)
	for key in groups:
		var inputs: Array = groups[key]
		var usable: Array[String] = []
		var preserved := {}
		for item_id in inputs:
			if GameState.equipped.values().has(item_id) and not bool(preserved.get(item_id, false)):
				preserved[item_id] = true
				continue
			usable.append(str(item_id))
			if usable.size() == 3:
				break
		if usable.size() == 3 and not GameState.begin_synthesis(usable).is_empty():
			feedback.text = "合成完成计算：结果已经锁定，请在仓库列表三选一。"
			_refresh_warehouse()
			return
	feedback.text = "没有三件可安全消耗的同槽、同品质装备；已装备与唯一遗物不会被误用。"


func _choose_synthesis(index: int) -> void:
	var result := GameState.complete_synthesis(index)
	feedback.text = "已选择%s，词条「%s」已固定。" % [str(EquipmentDatabase.get_item(str(result.get("item_id", ""))).get("name", "合成装备")), str(ExchangeEvolution.AFFIXES.get(str(result.get("affix_id", "")), {}).get("name", "未知"))] if not result.is_empty() else "无法领取合成结果：请检查仓库容量。"
	_refresh_warehouse()
	_refresh()


func _reject_synthesis() -> void:
	var gained := GameState.reject_synthesis()
	feedback.text = "合成结果已转化：+%d 合成余烬，保底进度提高。" % gained
	_refresh_warehouse()
	_refresh()


func _progress_selected() -> void:
	if selected_equipment_id.is_empty():
		return
	if int(GameState.equipment_levels.get(selected_equipment_id, 0)) < 5:
		feedback.text = "装备强化完成。" if GameState.upgrade_equipment(selected_equipment_id) else "强化失败：回响或合成余烬不足。"
	else:
		_show_evolution_paths(selected_equipment_id)
		return
	_refresh_warehouse()
	_refresh()
	if not selected_equipment_id.is_empty():
		_select_equipment(selected_equipment_id)


func _show_evolution_paths(item_id: String) -> void:
	if not ExchangeEvolution.EVOLUTIONS.has(item_id):
		feedback.text = "该装备已满级，但没有独立进化分支。"
		return
	for child in section_content.get_children():
		child.queue_free()
	var item := EquipmentDatabase.get_item(item_id)
	section_title.text = "%s：三条进化路径" % str(item.get("name", item_id))
	_section_heading("进化规则", "路径由玩家明确选择，不再自动采用第一条。每次进化消耗 1 因果残片；当前持有 %d。行为进度来自装备实际战斗记录。" % GameState.causality_fragments)
	var available_map := {}
	for branch in GameState.available_evolutions(item_id):
		available_map[str(branch.id)] = branch
	for evolution_id in ExchangeEvolution.EVOLUTIONS[item_id]:
		var evolution: Dictionary = ExchangeEvolution.EVOLUTIONS[item_id][evolution_id]
		var state: Dictionary = available_map.get(evolution_id, {})
		var progress := int(GameState.equipment_mastery.get(item_id, {}).get(str(evolution.mastery), 0))
		var ready := bool(state.get("available", false)) and GameState.causality_fragments >= 1
		_section_heading(str(evolution.name), "%s\n行为条件：%s %d/%d\n能力：%s\n叙事含义：%s" % [
			str(evolution.description), str(evolution.mastery), progress, int(evolution.required),
			_format_bonus_map(evolution.get("bonuses", {})),
			str(narrative_catalog.unique_item(item_id).get("evolutions", {}).get(evolution_id, "该路径尚无独立叙事。")),
		])
		var choose := Button.new()
		choose.text = "选择「%s」· 消耗 1 因果残片%s" % [str(evolution.name), "" if ready else "（条件未满足）"]
		choose.disabled = not ready
		choose.pressed.connect(_choose_evolution.bind(item_id, str(evolution_id)))
		section_content.add_child(choose)
	section_panel.visible = true
	_layout_section_panel(get_viewport_rect().size)


func _choose_evolution(item_id: String, evolution_id: String) -> void:
	var name := str(ExchangeEvolution.EVOLUTIONS.get(item_id, {}).get(evolution_id, {}).get("name", evolution_id))
	feedback.text = "装备已进化为「%s」。" % name if GameState.evolve_equipment(item_id, evolution_id) else "进化失败：检查行为条件与因果残片。"
	section_panel.visible = false
	_refresh_warehouse()
	_refresh()
	_select_equipment(item_id)


func _format_bonus_map(bonuses: Dictionary) -> String:
	var names := {
		"max_health": "生命", "movement_speed": "移速", "melee_damage": "近战",
		"ranged_damage": "手枪", "shotgun_damage": "霰弹", "bandage_heal": "治疗",
		"attack_range": "近战范围", "ranged_range": "远程范围", "shotgun_range": "霰弹范围",
	}
	var lines: Array[String] = []
	for key in bonuses:
		var value: Variant = bonuses[key]
		lines.append("%s %s%s" % [str(names.get(key, key)), "+" if float(value) >= 0.0 else "", str(value)])
	return " · ".join(lines)


func _equip_selected() -> void:
	if GameState.equip_item(selected_equipment_id):
		feedback.text = "装备已同步，下一次投送生效。"
		_refresh_warehouse()
		_refresh()


func _salvage_selected() -> void:
	var item := EquipmentDatabase.get_item(selected_equipment_id)
	var rewards := GameState.get_disassembly_rewards(item)
	if GameState.disassemble_item(selected_equipment_id):
		var fragment_text := "\n因果残片  +%d" % int(rewards.causality_fragments) if int(rewards.causality_fragments) > 0 else ""
		feedback.text = "已拆解 %s：+%d 回响碎片%s" % [str(item.name), int(rewards.echo_shards), " · +%d 因果残片" % int(rewards.causality_fragments) if int(rewards.causality_fragments) > 0 else ""]
		salvage_reward_detail.text = "已分解\n%s · %s\n\n获得\n回响碎片  +%d%s" % [str(item.quality), str(item.name), int(rewards.echo_shards), fragment_text]
		_layout_salvage_reward(get_viewport_rect().size)
		salvage_reward_panel.visible = true
		selected_equipment_id = ""
		_refresh_warehouse()
		_refresh()
