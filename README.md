# Dreadbound

**Dreadbound** 是一款使用 Godot 4 与 GDScript 开发的原创单机 2D 俯视角恐怖生存 Roguelite。玩家作为被“终末回廊”选中的行者，进入由文明恐惧、记忆和未来可能性生成的灾难世界，探索、战斗、管理资源、修复异常并决定何时撤离。

项目只借鉴“无限流”题材中进入不同危险世界并成长的结构，不使用现有作品的角色、专有名词、剧情、电影副本或具体强化内容。

## 项目定位

- 引擎与脚本：Godot 4、GDScript
- 模式与视角：单机、2D 俯视角、四方向移动
- 首要平台：电脑浏览器 Web；后续支持 Windows 下载版
- 设计分辨率：1280×720；场景 Tile：32×32 像素
- 视觉方向：写实人体比例的低分辨率恐怖像素风

## 当前阶段

项目处于**首个垂直切片完成与发布验证阶段**。新存档首次打开会直接进入疗养院教学局，成功撤离后解锁终末回廊；已有成功记录的存档会从回廊开始。副本中可以主动撤回，并包含“污染药柜”和“回响病房”两种风险事件；玩家需要在额外补给、碎片、受伤和敌袭之间作出选择。

## 运行目标

安装 Godot 4 后，在 Project Manager 中导入 `project.godot` 并按 **F5**，或运行 `godot --path .`。电脑使用 WASD/方向键移动、空格/J 攻击、R/Tab 切换武器、F 切换道具、Q 使用当前道具、E 交互；手机和平板使用左侧摇杆及右侧攻击、武器切换、道具切换、当前道具和交互按钮。当前选中的道具及数量会显示在顶部状态栏与道具按钮中。建议横屏游玩。

首个可玩目标是一局 10～15 分钟的废弃疗养院垂直切片：寻找三份实验记录、恢复地下室电力，并在怪物追击下撤离。

![灰盒移动与交互原型](docs/images/graybox-movement.png)

![探索迷雾与可展开地图](docs/images/expanded-map.png)

![终末回廊整备与永久强化界面](docs/images/terminal-corridor.png)

![可打开与关闭的行者整备终端](docs/images/corridor-terminal.png)

![终末回廊异常装备仓库](docs/images/equipment-warehouse.png)

![疗养院回响病房风险事件](docs/images/risk-event.png)

![疗养院完整垂直切片](docs/images/vertical-slice.png)

## 开发路线

1. **最小框架（完成）**：项目配置、文档、占位启动场景。
2. **任务灰盒（完成）**：已完成四方向移动、碰撞、相机、手机触控、疗养院分区、三份记录、供电与撤离流程。
3. **最小战斗闭环（完成）**：玩家生命与受击、基础近战攻击、The Patient 追击与扑击、死亡与重开。
4. **探索地图（完成）**：未探索房间迷雾、进入后渐显、右上角小地图和可展开全图。
5. **资源管理（完成）**：玩家与敌人独立场景、绷带、回响碎片、自动拾取和简化物品状态。
6. **内容扩展（完成）**：The Crawler、基础手枪、近战/远程切换和弹药资源。
7. **终末回廊闭环（完成）**：撤离结算、局外资源账户、角色属性、4 项永久强化、三套简化整备、存档和再次出发。
8. **风险事件（完成）**：污染药柜与回响病房，包含补给/伤害和碎片/敌袭的风险收益选择。
9. **疗养院战斗内容（完成）**：The Orderly、供电后苏醒的“缝合主任”Boss、蓄力预警、阶段变化与可绕行撤离。
10. **装备内容（完成）**：霰弹枪、霰弹拾取、镇静剂和第四套“破门配置”，补齐 3 种武器与 3 种消耗品。
11. **引导与表现（完成）**：首局中文提示、关键任务通知、低成本手电筒、电力环境变化、合成反馈音和统一终端 UI。
12. **平衡与稳定性（完成首轮）**：敌人分工、移动端安全布局、减少拾取物重绘、WebGL 恢复与 v1→v2 存档迁移。
13. **完整回归（完成自动化）**：任务、战斗、地图、资源、事件、成长、Boss、三武器和三消耗品均进入部署门禁；真实设备仍需每次发布后持续烟雾测试。
14. **阶段 G 奖励基础（完成）**：普通怪物掉落、Boss 三选一回收箱、8 件样品装备、4 档品质、仓库、装备、拆解和撤离入库。
15. **动态副本框架 H1（完成）**：带种子的房间模块重组、任务插槽、可达性验证、小地图适配与行动代码复现。
16. **动态任务与 AI 导演 H2–H4（完成首轮）**：支线条件、因果链、压力/节奏导演、敌人记忆和 500 种子回归。
17. **第二个灾难世界（完成首轮）**：潮没末班线已接入双契约、潮位/噪音/车次、双路线撤离、专属敌人和 Boss、四件机制装备与阈值司仪试炼；后续发布继续执行桌面与真实移动设备烟雾测试。所有世界必须遵守共享的 [UI 开发与验收标准](docs/ui-development-standard.md)，不得复制固定坐标界面。

详见 [`docs/game-vision.md`](docs/game-vision.md)、[`docs/art-style.md`](docs/art-style.md)、[`docs/first-vertical-slice.md`](docs/first-vertical-slice.md)、[`docs/progression-roadmap.md`](docs/progression-roadmap.md)、[`docs/pre-second-map-plan.md`](docs/pre-second-map-plan.md)、[`docs/loot-and-progression-plan.md`](docs/loot-and-progression-plan.md)、[`docs/dynamic-director-plan.md`](docs/dynamic-director-plan.md) 和 [`docs/second-disaster-world-design.md`](docs/second-disaster-world-design.md)。第一阶段不开发多人、3D、复杂队友 AI、程序化地图或大量装备。

## Web 版本

项目包含 Web 导出预设。安装与当前 Godot 版本匹配的 Export Templates 后，可以运行：

```bash
godot --headless --path . --export-release Web builds/web/index.html
python3 -m http.server 8000 --directory builds/web
```

然后访问 `http://localhost:8000`。`.github/workflows/deploy-web.yml` 会在 `main` 分支更新时构建并部署 GitHub Pages；首次使用需要在仓库 **Settings → Pages → Source** 中选择 **GitHub Actions**。

线上试玩固定地址为 <https://ancientboy.github.io/Dreadbound>。后续发布说明始终使用这个地址，不附加提交编号或查询参数。
