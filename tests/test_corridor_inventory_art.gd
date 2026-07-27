extends SceneTree

const EQUIPMENT_ICON_PATHS := {
	"service_crowbar": "res://assets/art/icons/equipment/service_crowbar.png",
	"balanced_pistol": "res://assets/art/icons/equipment/balanced_pistol.png",
	"breach_shotgun": "res://assets/art/icons/equipment/breach_shotgun.png",
	"echo_edge": "res://assets/art/icons/equipment/echo_edge.png",
	"medical_tag": "res://assets/art/icons/equipment/medical_tag.png",
	"calming_coil": "res://assets/art/icons/equipment/calming_coil.png",
	"ward_echo": "res://assets/art/icons/equipment/ward_echo.png",
	"cyan_mark": "res://assets/art/icons/equipment/cyan_mark.png",
	"waterproof_pulse": "res://assets/art/icons/equipment/waterproof_pulse.png",
	"station_whistle": "res://assets/art/icons/equipment/station_whistle.png",
	"insulated_crowbar": "res://assets/art/icons/equipment/insulated_crowbar.png",
	"last_ticket": "res://assets/art/icons/equipment/last_ticket.png",
	"nullpoint_sidearm": "res://assets/art/icons/equipment/nullpoint_sidearm.png",
	"siege_core": "res://assets/art/icons/equipment/siege_core.png",
	"volatile_edge": "res://assets/art/icons/equipment/volatile_edge.png",
	"archive_lens": "res://assets/art/icons/equipment/archive_lens.png",
	"linye_pass": "res://assets/art/icons/unique/linye_pass.png",
	"director_reaper": "res://assets/art/icons/unique/director_reaper.png",
	"conductor_railgun": "res://assets/art/icons/unique/conductor_railgun.png",
}

const MATERIAL_ICON_PATHS := {
	"tissue_sample": "res://assets/art/icons/materials/tissue_sample.png",
	"medical_record": "res://assets/art/icons/materials/medical_record.png",
	"stitch_core": "res://assets/art/icons/materials/stitch_core.png",
	"flooded_circuit": "res://assets/art/icons/materials/flooded_circuit.png",
	"ticket_stub": "res://assets/art/icons/materials/ticket_stub.png",
	"conductor_coil": "res://assets/art/icons/materials/conductor_coil.png",
}


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_check_texture("res://assets/art/worlds/corridor/corridor_hub_atlas.png", Vector2i(512, 512))
	_check_texture("res://assets/art/ui/hub_section_icons.png", Vector2i(224, 32))
	for item_id in EquipmentDatabase.ITEMS:
		assert(EQUIPMENT_ICON_PATHS.has(item_id), "equipment icon mapping missing: %s" % item_id)
		_check_texture(EQUIPMENT_ICON_PATHS[item_id], Vector2i(32, 32))
	for material_id in ExchangeEvolution.MATERIALS:
		assert(MATERIAL_ICON_PATHS.has(material_id), "material icon mapping missing: %s" % material_id)
		_check_texture(MATERIAL_ICON_PATHS[material_id], Vector2i(32, 32))

	var corridor: Control = load("res://scenes/corridor.tscn").instantiate()
	root.add_child(corridor)
	await process_frame
	var navigation := corridor.get_node("IndependentHubNavigation") as GridContainer
	assert(navigation != null and navigation.get_child_count() == 8)
	for button in navigation.get_children():
		assert(button is Button and button.icon != null, "hub navigation entry has no atlas icon")
	var avatar_entry := navigation.get_node_or_null("HubAvatar") as Button
	assert(avatar_entry != null and avatar_entry.text == "角色", "角色切换入口缺失")
	corridor._open_hub_section("avatar")
	assert(corridor.section_title.text == "角色切换")
	assert(corridor.section_content.get_child_count() >= 4)

	var game_state := root.get_node("GameState")
	game_state.equipment_inventory.clear()
	game_state.equipment_inventory.append_array([
		"service_crowbar", "cyan_mark", "waterproof_pulse", "director_reaper",
	])
	corridor._open_warehouse()
	assert(corridor.warehouse_list is GridContainer)
	assert(corridor.warehouse_list.columns >= 2)
	assert(corridor.warehouse_list.get_child_count() >= 5)
	corridor._select_equipment("cyan_mark")
	assert(corridor.warehouse_preview.texture != null)
	assert(corridor.warehouse_detail.text.contains("异常青印"))

	corridor._open_hub_section("materials")
	var material_grid := corridor.section_content.get_node("MaterialGrid") as GridContainer
	assert(material_grid != null and material_grid.get_child_count() == ExchangeEvolution.MATERIALS.size())
	corridor._select_material("conductor_coil")
	assert(corridor.material_detail_icon.texture != null)
	assert(corridor.material_detail.text.contains("车长线圈"))

	var source := FileAccess.get_file_as_string("res://scripts/corridor.gd")
	assert(source.contains("_draw_hub_asset(0"))
	assert(source.contains("_draw_legend_gate(SANATORIUM_GATE_POSITION"))
	assert(source.contains("CORRIDOR_HUB_ATLAS"))
	assert(source.contains("_create_icon_card"))
	assert(not source.contains("draw_colored_polygon(floor"), "corridor still draws the central graybox polygon")

	var manifest_file := FileAccess.open("res://content/alpha_asset_manifest.json", FileAccess.READ)
	var manifest: Dictionary = JSON.parse_string(manifest_file.get_as_text())
	var entries := {}
	for entry_value in manifest.get("assets", []):
		var entry: Dictionary = entry_value
		entries[str(entry.id)] = entry
	for asset_id in [
		"art_corridor_hub_atlas", "art_ui_hub_section_icons",
		"art_icon_cyan_mark", "art_icon_conductor_railgun",
		"art_material_flooded_circuit", "art_material_ticket_stub", "art_material_conductor_coil",
	]:
		assert(entries.has(asset_id))
		assert(str(entries[asset_id].status) == "review")

	corridor.queue_free()
	print("Corridor inventory art passed: full hub atlas, seven navigation icons, complete item/material icons, grid inventory and click-to-detail panels")
	quit()


func _check_texture(path: String, expected_size: Vector2i) -> void:
	var texture := load(path) as Texture2D
	assert(texture != null, "texture cannot load: %s" % path)
	var image := texture.get_image()
	assert(not image.is_empty())
	assert(image.get_size() == expected_size, "wrong texture size: %s" % path)
	assert(image.detect_alpha() != Image.ALPHA_NONE, "texture has no alpha: %s" % path)
	assert(image.get_used_rect().size.x > 0 and image.get_used_rect().size.y > 0)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			assert(not (color.r > 0.72 and color.b > 0.72 and color.g < 0.3), "chroma key remains: %s" % path)
