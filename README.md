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

项目处于**探索与地图系统阶段**。当前包含中文版任务界面、房间探索迷雾、可展开小地图、玩家生命与近战、The Patient 敌人、死亡重开、手机触控，以及三份记录、供电和撤离任务路线；仍不包含正式美术和完整装备系统。

## 运行目标

安装 Godot 4 后，在 Project Manager 中导入 `project.godot` 并按 **F5**，或运行 `godot --path .`（部分系统命令名为 `godot4`）。电脑使用 WASD/方向键移动、空格或 J 攻击、E 交互；手机和平板使用左侧虚拟摇杆、右侧攻击和交互按钮。建议横屏游玩。

首个可玩目标是一局 10～15 分钟的废弃疗养院垂直切片：寻找三份实验记录、恢复地下室电力，并在怪物追击下撤离。

![灰盒移动与交互原型](docs/images/graybox-movement.png)

![探索迷雾与可展开地图](docs/images/expanded-map.png)

## 开发路线

1. **最小框架（完成）**：项目配置、文档、占位启动场景。
2. **任务灰盒（完成）**：已完成四方向移动、碰撞、相机、手机触控、疗养院分区、三份记录、供电与撤离流程。
3. **最小战斗闭环（完成）**：玩家生命与受击、基础近战攻击、The Patient 追击与扑击、死亡与重开。
4. **探索地图（完成）**：未探索房间迷雾、进入后渐显、右上角小地图和可展开全图。
5. **资源管理（下一步）**：拆分正式场景结构，加入资源搜集、一种消耗品和简化物品栏。
6. **表现与平衡**：统一像素素材、灯光和音效、终端风格 UI、永久强化及 Web 性能优化。

详见 [`docs/game-vision.md`](docs/game-vision.md)、[`docs/art-style.md`](docs/art-style.md) 和 [`docs/first-vertical-slice.md`](docs/first-vertical-slice.md)。第一阶段不开发多人、3D、复杂队友 AI、程序化地图或大量装备。

## Web 版本

项目包含 Web 导出预设。安装与当前 Godot 版本匹配的 Export Templates 后，可以运行：

```bash
godot --headless --path . --export-release Web builds/web/index.html
python3 -m http.server 8000 --directory builds/web
```

然后访问 `http://localhost:8000`。`.github/workflows/deploy-web.yml` 会在 `main` 分支更新时构建并部署 GitHub Pages；首次使用需要在仓库 **Settings → Pages → Source** 中选择 **GitHub Actions**。
