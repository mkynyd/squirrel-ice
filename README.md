# 雾凇输入法

[Squirrel](https://github.com/rime/squirrel)（鼠须管）+ [rime-ice](https://github.com/iDvel/rime-ice)（雾凇拼音）的 macOS 原生输入法。开箱即用，无需手动部署 YAML 配置文件。

## 特性

- **开箱即用** — 内置雾凇拼音全套词库、方案、Lua 脚本和 OpenCC 数据，无需额外配置
- **可视化配置** — SwiftUI 原生设置面板，图形化管理主题、词库、输入方案、键盘布局
- **主题系统** — 内置 macOS Light/Dark 和微信风格主题，支持自定义颜色并实时预览
- **热部署** — 修改配置后自动通知输入法重新加载，无需手动重启
- **macOS 原生** — AppKit 候选窗 + SwiftUI 设置面板 + Sparkle 自动更新，纯原生组件
- **轻量** — 不引入 Electron/Chromium，App 体积约 60 MB，pkg 安装包约 20 MB

## 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Apple Silicon (arm64) / Intel (x86_64)

## 快速开始

```bash
# 克隆仓库
git clone https://github.com/mkynyd/squirrel-ice.git
cd squirrel-ice

# 一键构建 Debug 版本
make debug ARCHS='arm64'

# 或构建 Release 通用二进制并打包
make package ARCHS='arm64 x86_64' BUILD_UNIVERSAL=1
```

## 技术栈

| 层次 | 技术 | 说明 |
|------|------|------|
| 核心引擎 | [librime](https://github.com/rime/librime) (C++) | Rime 输入法核心，拼音切分、词典查询、候选排序 |
| 输入法前端 | Squirrel (Swift + AppKit) | macOS Input Method Kit 实现，候选窗渲染、按键处理 |
| 配置界面 | SwiftUI | macOS 原生设置窗口，标签页式导航 |
| 配置存储 | YAML | Rime 标准配置格式，完全兼容 Rime 生态 |
| 插件系统 | librime-lua | 日期/计算器/Unicode/农历 等扩展功能 |
| 简繁转换 | OpenCC | 中国大陆/台湾/香港/日本汉字转换 |
| 自动更新 | Sparkle 2 | macOS 应用标准更新框架 |

## 目录结构

```
squirrel-ice/
├── README.md
├── BUILD.md                       # 详细构建文档
├── Makefile                       # 根目录构建入口
├── squirrel/                      # Squirrel 输入法（定制版）
│   ├── Squirrel.xcodeproj/
│   ├── sources/                   # Swift 源码
│   │   ├── Main.swift             # App 入口
│   │   ├── SquirrelApplicationDelegate.swift  # Rime 生命周期
│   │   ├── SquirrelInputController.swift      # 输入法控制器
│   │   ├── SquirrelTheme.swift    # 主题数据模型
│   │   ├── SquirrelView.swift     # 候选窗渲染
│   │   ├── SquirrelPanel.swift    # 候选窗面板
│   │   ├── WuSongConfigManager.swift       # 配置管理核心
│   │   ├── WuSongSettingsView.swift        # SwiftUI 设置面板
│   │   ├── WuSongSettingsWindowController.swift  # 设置窗口
│   │   └── ThemeLoader.swift      # 主题加载与颜色工具
│   ├── data/                      # 内置 Rime 配置
│   │   ├── cn_dicts/              # 中文词库
│   │   ├── en_dicts/              # 英文词库
│   │   ├── lua/                   # Lua 脚本
│   │   └── opencc/                # OpenCC 简繁转换
│   ├── themes/                    # 内置主题 YAML
│   ├── librime/                   # librime 引擎（子模块）
│   ├── plum/                      # Rime 包管理器（子模块）
│   ├── Sparkle/                   # 更新框架（子模块）
│   └── Makefile
├── vendor/rime-ice/               # 上游 rime-ice 配置（只读参考）
├── scripts/bootstrap_sources.sh   # 源码引导脚本
└── script/build_and_run.sh        # 构建+运行脚本
```

## 构建

### 安装依赖

```bash
brew install cmake boost capnp leveldb
```

### 编译

```bash
# Debug arm64
make debug ARCHS='arm64'

# Release 通用二进制 + pkg 打包
make package ARCHS='arm64 x86_64' BUILD_UNIVERSAL=1
```

构建产物：
- `squirrel/build/Build/Products/Release/Squirrel.app`
- `squirrel/build/package/Squirrel.pkg`

### 签名与公证

```bash
export DEV_ID="Developer ID Application: Your Name (TEAMID)"
make package ARCHS='arm64 x86_64' BUILD_UNIVERSAL=1
```

`DEV_ID` 设置后将自动执行代码签名、`productsign` 和公证流程。

## 功能清单

| 功能 | 实现方式 | 状态 |
|------|---------|------|
| 主题切换 | 设置面板 Picker + 实时预览 | ✅ |
| 自定义主题颜色 | ColorPicker 编辑，保存为 custom 主题 | ✅ |
| 词库管理（启用/禁用） | Toggle 开关，自动更新 `import_tables` | ✅ |
| 双拼方案选择 | Picker，自动更新 `schema_list` | ✅ |
| 按键布局 | 英文键盘布局选择（ABC/ABC Extended） | ✅ |
| 候选窗字体大小 | Slider 调节，实时预览 | ✅ |
| 候选方向 | 横向/纵向切换 | ✅ |
| 用户词典 | 一键打开 `custom_phrase.txt` | ✅ |
| 中英混输 | melt_eng schema | ✅ |
| 繁体输出 | OpenCC 简繁转换 | ✅ |
| 符号输入 | symbols_v.yaml 内置 | ✅ |
| 日期/计算器 | librime-lua 插件 | ✅ |
| 配置热部署 | DistributedNotificationCenter 通知 | ✅ |
| 自动更新 | Sparkle 2 框架 | ✅ |

## 配置目录

首次启动时，内置配置自动部署到 `~/Library/Rime/`：

```
~/Library/Rime/
├── .wusong_version       # 版本标记，用于增量更新
├── squirrel.custom.yaml  # 外观设置（主题/字体/布局）
├── default.custom.yaml   # 输入方案列表
├── rime_ice.dict.custom.yaml  # 词库列表
├── cn_dicts/             # 中文词库
├── en_dicts/             # 英文词库
├── lua/                  # Lua 脚本
├── opencc/               # OpenCC 简繁转换
└── themes/               # 用户自定义主题
```

## 主题系统

主题使用 YAML 格式定义，颜色采用 `0xAABBGGRR` 十六进制格式：

```yaml
name: macOS Light
author: WuSong
color_scheme:
  back_color: 0xFFFFFF
  candidate_text_color: 0x1D1D1F
  hilited_candidate_back_color: 0x007AFF
  hilited_candidate_text_color: 0xFFFFFF
  label_color: 0x8E8E93
  comment_text_color: 0x8E8E93
  border_color: 0xD1D1D6
style:
  corner_radius: 8
  font_point: 16
  candidate_list_layout: linear
```

内置主题位于 `squirrel/themes/`，用户自定义主题保存在 `~/Library/Rime/themes/`。

## 配置通知

修改配置后，系统通过 `DistributedNotificationCenter` 发送 `WuSongConfigChanged` 通知，输入法进程收到后自动重新部署 Rime 配置。

## 开发

```bash
# 修改源码后快速验证
make debug ARCHS='arm64'
killall Squirrel
# 切换到输入法触发加载

# 查看 Rime 日志
tail -f ~/Library/Rime/rime.log
```

## 上游项目

- [rime/squirrel](https://github.com/rime/squirrel) — 鼠须管输入法
- [iDvel/rime-ice](https://github.com/iDvel/rime-ice) — 雾凇拼音配置
- [rime/librime](https://github.com/rime/librime) — Rime 输入法引擎

## 许可

本项目基于 Squirrel 修改，遵循原有开源协议。详见各子目录的 LICENSE 文件。
