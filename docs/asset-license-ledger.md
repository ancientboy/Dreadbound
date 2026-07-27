# Dreadbound 资产来源与授权台账

本台账记录所有进入正式游戏、宣传页面和可下载版本的非代码资产。`content/alpha_asset_manifest.json` 管范围和状态，本文件管来源与授权证据。

## 准入规则

允许：

- Dreadbound 团队原创。
- 为 Dreadbound 定向生成、且服务条款明确允许商业使用与修改的资产。
- CC0 / Public Domain。
- CC BY 4.0，前提是完整记录作者、原始链接、许可证链接并在游戏 Credits 履行署名。
- 明确允许商业游戏内使用、修改与发行成品的付费/免费许可证。

禁止：

- 来源不明、“网上免费”但无许可证的素材。
- CC BY-NC、CC BY-ND 或仅限个人使用。
- 从影视、其他游戏、音乐作品或素材包预览中提取的内容。
- 无法证明生成服务商业使用权的 AI 音频/图像。
- 要求将游戏源素材再次开放下载、且与项目发行方式冲突的许可证。

外部素材必须保存许可证页面的标题、链接和获取日期；付费素材还应在私有采购记录中保留订单证明，仓库不提交个人付款信息。

## 状态说明

- `planned`：仅在清单中规划，尚未产生文件。
- `in_progress`：正在原创/生成/改制，不可当作正式资产发布。
- `review`：已进游戏等待视觉、音频、性能与授权复核。
- `approved`：复核通过，可进入正式构建。
- `rejected`：不再使用；文件应从正式资源目录移除。

## 已登记资产

| Asset ID | 文件 | 来源类型 | 作者/服务 | 原始链接或生成记录 | 许可证 | 修改 | 状态 |
|---|---|---|---|---|---|---|---|
| `font_ui_chinese_full` | `assets/fonts/DreadboundChineseFull.otf` | 开源字体 | Noto Sans CJK / SIL Open Font License | 见 `assets/fonts/OFL.txt` | OFL-1.1 | 子集/格式整理 | approved |
| `font_ui_chinese_legacy` | `assets/fonts/DreadboundChinese.ttf` | 开源字体 | 见字体随附许可证 | 见 `assets/fonts/OFL.txt` | OFL-1.1 | 旧版兼容 | approved |
| `art_home_keyart` | `assets/art/brand/home_keyart.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 prompt | `docs/o1-visual-slice.md` | 商业生成与修改权 | 1280×720 裁切、128 色索引、Nearest 整理 | review |
| `art_corridor_tileset` | `assets/art/worlds/corridor/corridor_tileset.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 prompt | `docs/o1-visual-slice.md` | 商业生成与修改权 | 色键分格、64 Tile、32×32 Nearest | review |
| `art_player_drifter` | `assets/art/characters/drifter/drifter_spritesheet.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 prompt | `docs/o1-visual-slice.md` | 商业生成与修改权 | 色键移除、4×6 帧格、48×64 Nearest | review |
| `art_enemy_patient` | `assets/art/characters/sanatorium/patient_spritesheet.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 prompt | `docs/o1-visual-slice.md` | 商业生成与修改权 | 色键移除、4×6 帧格、48×64 Nearest | review |
| `art_sanatorium_room_benchmark` | `assets/art/worlds/sanatorium/sanatorium_room_benchmark.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 prompt | `docs/o1-visual-slice.md` | 商业生成与修改权 | 1280×720 裁切、128 色索引、Nearest 整理 | review |
| `art_corridor_props` | `assets/art/worlds/corridor/corridor_props.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 2 prompt | `docs/o1-visual-slice.md` | 商业生成与修改权 | 色键移除、六件分格、128×128 Nearest | review |
| `art_weapon_world_basic` | `assets/art/weapons/basic_weapons.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 2 prompt | `docs/o1-visual-slice.md` | 商业生成与修改权 | 色键移除、三件分格、32×32 Nearest | review |
| `art_icon_service_crowbar` | `assets/art/icons/equipment/service_crowbar.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 2 prompt | `docs/o1-visual-slice.md` | 商业生成与修改权 | 32×32 裁切、透明边缘与限色 | review |
| `art_icon_balanced_pistol` | `assets/art/icons/equipment/balanced_pistol.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 2 prompt | `docs/o1-visual-slice.md` | 商业生成与修改权 | 32×32 裁切、透明边缘与限色 | review |
| `art_icon_breach_shotgun` | `assets/art/icons/equipment/breach_shotgun.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 2 prompt | `docs/o1-visual-slice.md` | 商业生成与修改权 | 32×32 裁切、透明边缘与限色 | review |
| `art_vfx_combat_core` | `assets/art/vfx/combat_core.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 2 prompt | `docs/o1-visual-slice.md` | 商业生成与修改权 | 色键移除、八格 64×64、透明边缘与限色 | review |
| `art_sanatorium_tileset` | `assets/art/worlds/sanatorium/sanatorium_tileset.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 3 prompt | `docs/o1-sanatorium-slice.md` | 商业生成与修改权 | 8×8 分格、32×32 Tile、色键与饱和边缘清理 | review |
| `art_sanatorium_props` | `assets/art/worlds/sanatorium/sanatorium_props.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 3 prompt | `docs/o1-sanatorium-slice.md` | 商业生成与修改权 | 4×3 分格、128×128 Prop、透明边缘整理 | review |
| `art_enemy_crawler` | `assets/art/characters/sanatorium/crawler_spritesheet.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 3 prompt | `docs/o1-sanatorium-slice.md` | 商业生成与修改权 | 色键移除、4×6 帧格、64×48 Nearest | review |
| `art_enemy_orderly` | `assets/art/characters/sanatorium/orderly_spritesheet.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 3 prompt | `docs/o1-sanatorium-slice.md` | 商业生成与修改权 | 色键移除、4×6 帧格、48×64 Nearest | review |
| `art_npc_threshold_curator` | `assets/art/characters/corridor/threshold_curator_spritesheet.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 3 prompt | `docs/o1-sanatorium-slice.md` | 商业生成与修改权 | 色键移除、4×6 帧格、96×96 Boss 级 NPC | review |
| `art_boss_stitch_director` | `assets/art/characters/sanatorium/stitch_director_spritesheet.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 4 prompt | `docs/o1-sanatorium-boss-items.md` | 商业生成与修改权 | 色键移除、4×6 帧格、96×96 Boss | review |
| `art_weapon_director_reaper_growth` | `assets/art/weapons/director_reaper_growth.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 4 prompt | `docs/o1-sanatorium-boss-items.md` | 商业生成与修改权 | 六级分格、64×64、透明边缘与限色 | review |
| `art_icon_echo_edge` | `assets/art/icons/equipment/echo_edge.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 4 prompt | `docs/o1-sanatorium-boss-items.md` | 商业生成与修改权 | 32×32 裁切、透明边缘与限色 | review |
| `art_icon_medical_tag` | `assets/art/icons/equipment/medical_tag.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 4 prompt | `docs/o1-sanatorium-boss-items.md` | 商业生成与修改权 | 32×32 裁切、透明边缘与限色 | review |
| `art_icon_calming_coil` | `assets/art/icons/equipment/calming_coil.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 4 prompt | `docs/o1-sanatorium-boss-items.md` | 商业生成与修改权 | 32×32 裁切、透明边缘与限色 | review |
| `art_icon_ward_echo` | `assets/art/icons/equipment/ward_echo.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 4 prompt | `docs/o1-sanatorium-boss-items.md` | 商业生成与修改权 | 32×32 裁切、透明边缘与限色 | review |
| `art_icon_director_reaper` | `assets/art/icons/unique/director_reaper.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 4 prompt | `docs/o1-sanatorium-boss-items.md` | 商业生成与修改权 | 32×32 裁切、透明边缘与限色 | review |
| `art_material_tissue_sample` | `assets/art/icons/materials/tissue_sample.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 4 prompt | `docs/o1-sanatorium-boss-items.md` | 商业生成与修改权 | 32×32 裁切、透明边缘与限色 | review |
| `art_material_medical_record` | `assets/art/icons/materials/medical_record.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 4 prompt | `docs/o1-sanatorium-boss-items.md` | 商业生成与修改权 | 32×32 裁切、透明边缘与限色 | review |
| `art_material_stitch_core` | `assets/art/icons/materials/stitch_core.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 4 prompt | `docs/o1-sanatorium-boss-items.md` | 商业生成与修改权 | 32×32 裁切、透明边缘与限色 | review |
| `art_vfx_world_feedback` | `assets/art/vfx/world_feedback.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 4 prompt | `docs/o1-sanatorium-boss-items.md` | 商业生成与修改权 | 4×2 分格、64×64 拾取物、透明边缘与限色 | review |
| `art_world_reward_chest` | `assets/art/worlds/global/reward_chest.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 4 prompt | `docs/o1-sanatorium-boss-items.md` | 商业生成与修改权 | 64×64 裁切、透明边缘与限色 | review |
| `art_vfx_sanatorium_objective_lighting` | `assets/art/vfx/sanatorium_objective_lighting.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 batch 4 prompt | `docs/o1-sanatorium-boss-items.md` | 商业生成与修改权 | 4×2 分格、128×128、紫色键边缘清理与限色 | review |
| `art_corridor_hub_atlas` | `assets/art/worlds/corridor/corridor_hub_atlas.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 corridor prompt | `docs/o1-corridor-inventory-grid.md` | 商业生成与修改权 | 4×4 分格、128×128、色键/浅色分隔线清理与限色 | review |
| `art_ui_hub_section_icons` | `assets/art/ui/hub_section_icons.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 corridor prompt | `docs/o1-corridor-inventory-grid.md` | 商业生成与修改权 | 七格 32×32、透明边缘与限色 | review |
| `art_icon_o1_remaining_equipment` | `assets/art/icons/equipment/`、`assets/art/icons/unique/` | 定向生成原创 | OpenAI image generation / Dreadbound O1 inventory prompt | `docs/o1-corridor-inventory-grid.md` | 商业生成与修改权 | 补齐 11 件装备图标、32×32、透明边缘与限色 | review |
| `art_material_o1_metro` | `assets/art/icons/materials/` | 定向生成原创 | OpenAI image generation / Dreadbound O1 inventory prompt | `docs/o1-corridor-inventory-grid.md` | 商业生成与修改权 | 三种地铁材料图标、32×32、透明边缘与限色 | review |
| `art_metro_tileset` | `assets/art/worlds/metro/metro_tileset.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 metro prompt | `docs/o1-metro-environment.md` | 商业生成与修改权 | 8×8 分格、32×32 Tile、色键与紫边清理、限色 | review |
| `art_metro_props` | `assets/art/worlds/metro/metro_props.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 metro prompt | `docs/o1-metro-environment.md` | 商业生成与修改权 | 4×3 分格、128×128 Prop、透明边缘与限色 | review |
| `art_enemy_drowned` | `assets/art/characters/metro/drowned_spritesheet.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 metro prompt | `docs/o1-metro-environment.md` | 商业生成与修改权 | 色键移除、4×6 帧格、48×64 Nearest | review |
| `art_enemy_inspector` | `assets/art/characters/metro/inspector_spritesheet.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 metro prompt | `docs/o1-metro-environment.md` | 商业生成与修改权 | 色键移除、4×6 帧格、48×64 Nearest | review |
| `art_enemy_signal_anchor` | `assets/art/characters/metro/signal_anchor_spritesheet.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 metro prompt | `docs/o1-metro-environment.md` | 商业生成与修改权 | 色键移除、4×6 帧格、64×64 Nearest | review |
| `art_boss_conductor_echo` | `assets/art/characters/metro/last_train_conductor_spritesheet.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 metro finish prompt | `docs/o1-metro-visual-finish.md` | 商业生成与修改权 | 色键移除、4×6 帧格、96×96 Boss、透明边缘与限色 | review |
| `art_weapon_conductor_railgun_growth` | `assets/art/weapons/conductor_railgun_growth.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 metro finish prompt | `docs/o1-metro-visual-finish.md` | 商业生成与修改权 | 六级分格、64×64、统一握把锚点与限色 | review |
| `art_vfx_metro_enemy_skills` | `assets/art/vfx/metro_enemy_skills.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 metro finish prompt | `docs/o1-metro-visual-finish.md` | 商业生成与修改权 | 4×2 分格、128×128、色键与透明边缘清理 | review |
| `art_vfx_metro_flood_layers` | `assets/art/vfx/metro_flood_layers.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 metro finish prompt | `docs/o1-metro-visual-finish.md` | 商业生成与修改权 | 4×2 分格、128×128、深浅水/水线/浸没层整理 | review |
| `art_vfx_player_states_lighting` | `assets/art/vfx/player_states_lighting.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 metro finish prompt | `docs/o1-metro-visual-finish.md` | 商业生成与修改权 | 4×2 分格、128×128、胸灯/光锥/路径状态整理 | review |
| `art_brand_logo` | `assets/art/brand/dreadbound_logo.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 visual completion prompt | `docs/o1-metro-visual-finish.md` | 商业生成与修改权 | 精确字标校对、512×128、色键与透明边缘清理 | review |
| `art_ui_mobile_controls` | `assets/art/ui/mobile_controls.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 visual completion prompt | `docs/o1-metro-visual-finish.md` | 商业生成与修改权 | 4×2 分格、64×64 触控图标、透明边缘与限色 | review |
| `art_ui_unknown_equipment` | `assets/art/icons/ui/unknown_equipment.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 inventory prompt | `docs/o1-corridor-inventory-grid.md` | 商业生成与修改权 | 32×32 锁定装备占位图标 | review |
| `art_ui_unknown_material` | `assets/art/icons/ui/unknown_material.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 inventory prompt | `docs/o1-corridor-inventory-grid.md` | 商业生成与修改权 | 32×32 锁定材料占位图标 | review |
| `art_corridor_floor_tile` | `assets/art/worlds/corridor/corridor_floor_tile.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 corridor prompt | `docs/o1-corridor-inventory-grid.md` | 商业生成与修改权 | 128×128 回廊重复地板模块 | review |
| `art_player_profession_steadfast` | `assets/art/characters/professions/steadfast_spritesheet.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 profession prompt | `docs/o1-professions-npcs.md` | 商业生成与修改权 | 色键移除、4×6 帧格、48×64 Nearest、限色 | review |
| `art_player_profession_armorer` | `assets/art/characters/professions/armorer_spritesheet.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 profession prompt | `docs/o1-professions-npcs.md` | 商业生成与修改权 | 色键移除、4×6 帧格、48×64 Nearest、限色 | review |
| `art_player_profession_resonant` | `assets/art/characters/professions/resonant_spritesheet.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 profession prompt | `docs/o1-professions-npcs.md` | 商业生成与修改权 | 色键移除、4×6 帧格、48×64 Nearest、限色 | review |
| `art_player_combat_style_forms` | `assets/art/characters/professions/combat_style_forms.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 profession-form prompt | `docs/o1-professions-npcs.md` | 商业生成与修改权 | 4×3 分格、128×128、透明边缘与限色 | review |
| `art_vfx_profession_skills` | `assets/art/vfx/profession_skills.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 profession-skill prompt | `docs/o1-professions-npcs.md` | 商业生成与修改权 | 4×3 分格、128×128、透明边缘与限色 | review |
| `art_npc_story_cast` | `assets/art/characters/npcs/story_npcs_idle.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 narrative-NPC prompt | `docs/o1-professions-npcs.md` | 商业生成与修改权 | 五行六帧、64×96、色键与透明边缘清理 | review |
| `art_vfx_sanatorium_enemy_skills` | `assets/art/vfx/sanatorium_enemy_skills.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 full-visual P0 prompt | `docs/o1-full-visual-materialization.md` | 商业生成与修改权 | 4×2、128×128、自动色键与限色 | review |
| `art_weapon_advanced_runtime` | `assets/art/weapons/advanced_weapons.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 full-visual P0 prompt | `docs/o1-full-visual-materialization.md` | 商业生成与修改权 | 五格 64×64、统一握把锚点 | review |
| `art_weapon_boss_evolution_branches` | `assets/art/weapons/boss_evolution_weapons.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 full-visual P0 prompt | `docs/o1-full-visual-materialization.md` | 商业生成与修改权 | 3×2、128×64、六分支轮廓 | review |
| `art_material_world_and_enemy_affixes` | `assets/art/vfx/materials_enemy_affixes.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 full-visual P0 prompt | `docs/o1-full-visual-materialization.md` | 商业生成与修改权 | 四掉落物、六身体附着层、64×64 | review |
| `art_player_style_forms_steadfast_directional` | `assets/art/characters/professions/combat_style_forms_steadfast.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 full-visual P1 prompt | `docs/o1-full-visual-materialization.md` | 商业生成与修改权 | 4 流派×4 方向、128×128 | review |
| `art_player_style_forms_armorer_directional` | `assets/art/characters/professions/combat_style_forms_armorer.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 full-visual P1 prompt | `docs/o1-full-visual-materialization.md` | 商业生成与修改权 | 4 流派×4 方向、128×128 | review |
| `art_player_style_forms_resonant_directional` | `assets/art/characters/professions/combat_style_forms_resonant.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 full-visual P1 prompt | `docs/o1-full-visual-materialization.md` | 商业生成与修改权 | 4 流派×4 方向、128×128 | review |
| `art_vfx_profession_skills_steadfast_animated` | `assets/art/vfx/profession_skills_steadfast.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 full-visual P1 prompt | `docs/o1-full-visual-materialization.md` | 商业生成与修改权 | 4 技能×4 帧、128×128 | review |
| `art_vfx_profession_skills_armorer_animated` | `assets/art/vfx/profession_skills_armorer.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 full-visual P1 prompt | `docs/o1-full-visual-materialization.md` | 商业生成与修改权 | 4 技能×4 帧、128×128 | review |
| `art_vfx_profession_skills_resonant_animated` | `assets/art/vfx/profession_skills_resonant.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 full-visual P1 prompt | `docs/o1-full-visual-materialization.md` | 商业生成与修改权 | 4 技能×4 帧、128×128 | review |
| `art_ui_progression_status_icons` | `assets/art/ui/progression_status_icons.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 full-visual P1 prompt | `docs/o1-full-visual-materialization.md` | 商业生成与修改权 | 6×3、32×32 词条/心相/状态 | review |
| `art_npc_story_portraits` | `assets/art/characters/npcs/story_npc_portraits.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 full-visual P2 prompt | `docs/o1-full-visual-materialization.md` | 商业生成与修改权 | 六格 192×192、自动绿色键清理 | review |
| `art_metro_maintenance_level` | `assets/art/worlds/metro/metro_maintenance_atlas.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 full-visual P2 prompt | `docs/o1-full-visual-materialization.md` | 商业生成与修改权 | 4×2、128×128 隐藏区域模块 | review |
| `art_narrative_archive_illustrations` | `assets/art/narrative/archive_illustrations.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 full-visual P2 prompt | `docs/o1-full-visual-materialization.md` | 商业生成与修改权 | 3×2、256×144 阶段档案插图 | review |
| `art_vfx_milestone_feedback` | `assets/art/vfx/milestone_feedback.png` | 定向生成原创 | OpenAI image generation / Dreadbound O1 full-visual P2 prompt | `docs/o1-full-visual-materialization.md` | 商业生成与修改权 | 四格 192×192 成长反馈 | review |

后续每个 O1/O2 资产在进入仓库的同一次提交中增加一行。使用成套素材时仍需逐个 Asset ID 关联，不能只写“某素材网站”。

| Asset ID | 路径 | 来源 | 生成记录 | 权利 | 备注 | 状态 |
|---|---|---|---|---|---|---|
| `audio_runtime_o2` | `scripts/audio_director.gd` | 原创程序系统 | `tools/generate_o2_audio.py`，2026-07-26 | 项目原创 | Music/Ambience/Combat/Creature/World/UI/Voice 总线、Web 首次输入解锁、24 声部池与音量持久化 | review |
| `audio_music_o2` | `assets/audio/music/*.ogg` | 原创合成 | `tools/generate_o2_audio.py`，确定性 seed 20260726 | 项目原创 | 六首循环：首页、回廊、疗养院探索/Boss、地铁探索/Boss | review |
| `audio_ambience_o2` | `assets/audio/ambience/*.ogg` | 原创合成 | `tools/generate_o2_audio.py`，确定性 seed 20260726 | 项目原创 | 五条环境循环：结构、病区、地下室、站台、洪水 | review |
| `audio_sfx_o2_core` | `assets/audio/sfx/**/*.wav` | 原创合成 | `tools/generate_o2_audio.py`，确定性 seed 20260726 | 项目原创 | UI、玩家、世界、敌人及十二流派技能；高频脚步/命中/拾取含四个变体 | review |
| `audio_sfx_cc0_kenney_rpg` | `assets/audio/sfx/ui/*.wav`、`assets/audio/sfx/player/combat/{player_melee_swing_01,player_melee_swing_02,player_switch_01,player_heal_01,player_hit_01..04}.wav`、`assets/audio/sfx/world/{pickup,objective}/*.wav` | Kenney via OpenGameArt | https://opengameart.org/content/50-rpg-sound-effects，下载于 2026-07-26 | CC0 | 替换原程序合成的高频 UI/近战/拾取/交互音；统一高通 70Hz、低通 5.2–9kHz，并按用途降至原素材 11–27% 增益，降低尖锐感与噪音 | review |
