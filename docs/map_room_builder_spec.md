# RoomBuilder 房间规范

地图结构统一使用 `128 × 128` 固定网格。房型只描述数据，
`RoomBuilder` 负责生成 TileMap、边界和运行时锚点。

## 必填字段

| 字段 | 说明 |
|---|---|
| `room_id` | 房型稳定 ID |
| `room_kind` | `combat`、`elite`、`ambush` 或 `boss` |
| `size_class` | `MapRoomModule.RoomSizeClass` |
| `grid_cells` | 所有可行走地面格；必须连通、无孔洞 |
| `map_bounds` | Camera2D 的世界边界 |
| `camera_zoom` | 房型镜头缩放 |
| `camera_guide_outline` | 镜头目标可移动的多边形 |
| `door_sockets` | 门方向和门所在的墙格 |
| `spawn` | 无入口门时的角色出生点 |
| `zones` | 遭遇区域与敌人出生点 |

## 可选字段

| 字段 | 说明 |
|---|---|
| `guide_line` | 医院地面引导线折线 |
| `content_slots` | 家具、掩体、敌人或目标的语义插槽 |

门槽的 `cell` 表示墙格，不是最终世界坐标。生成器会把它换算到墙脚连接线，
门框、碰撞缺口和房间切换必须共同使用该锚点。

## 生成结果

同一份房型规格会生成：

- 地面 `TileMapLayer`
- 北墙、侧墙、前景墙与转角层
- 门槽 `Marker2D`
- 内容插槽 `Marker2D`
- 顺时针简化的可行走多边形
- `NavigationRegion2D`
- Camera2D 世界边界与引导区域
- 带门洞切口的边界碰撞

大于医院地面母图 `8 × 6` 的房间使用镜像往返取样扩展图集，
使新增区域在原始像素边缘处连续，不直接从图集末格跳回首格。

## 当前验证房型

| 房型 | 地面格 | 镜头规则 | 验证重点 |
|---|---:|---|---|
| 标准战斗房 | 40 | 中心小范围跟随 | 基准构图与东西门 |
| 长条住院区 | 60 | 只沿长轴跟随 | 多屏横向移动 |
| L 形精英病区 | 45 | L 形双轴跟随 | 凹角、异型碰撞与导航 |

新增房型时应先加入 `MapThemeCatalog`，再扩展
`test_map_theme_catalog.gd` 和 `test_map_style_demo.gd` 的结构断言。
