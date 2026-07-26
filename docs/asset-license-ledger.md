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

后续每个 O1/O2 资产在进入仓库的同一次提交中增加一行。使用成套素材时仍需逐个 Asset ID 关联，不能只写“某素材网站”。
