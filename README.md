# 雾凇输入法

**语言：中文 | [English](README.en.md)**

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-555.svg)](BUILD.md)
[![Native macOS](https://img.shields.io/badge/UI-AppKit%20%2B%20SwiftUI-0A84FF.svg)](squirrel/sources)

雾凇输入法是一个面向 macOS 的原生 Rime 输入法发行版。它将 [Squirrel](https://github.com/rime/squirrel) 的 macOS 输入法前端与 [rime-ice](https://github.com/iDvel/rime-ice) 的拼音配置打包在一起，提供开箱即用的安装、内置词库、原生设置面板和主题管理。

项目目标很直接：保留 Rime 生态的透明、可配置和高性能，同时降低普通 macOS 用户第一次安装和维护配置的成本。

## 特性

- **开箱即用**：内置雾凇拼音配置、词库、Lua 脚本和 OpenCC 数据，安装后即可使用
- **原生设置面板**：使用 SwiftUI 管理主题、词库、输入方案、键盘布局和候选窗样式
- **主题系统**：内置 macOS Light、macOS Dark 和微信风格主题，支持自定义颜色与实时预览
- **配置热部署**：保存配置后通知输入法重新部署，无需手动重启
- **Rime 生态兼容**：继续使用 YAML 配置、用户词典、schema 和 OpenCC 数据格式
- **轻量架构**：不引入 Electron 或 Chromium，候选窗和设置界面均使用 macOS 原生技术

## 截图

当前仓库尚未提交正式截图。发布前建议补充：

- 候选窗浅色和深色主题
- 设置面板的主题、词库、方案管理页面
- 安装后在系统输入法列表中的显示状态

## 系统要求

- macOS 13.0 Ventura 或更高版本
- Apple Silicon 或 Intel Mac
- 构建需要 Xcode 14 或更高版本

## 快速开始

```bash
git clone https://github.com/mkynyd/squirrel-ice.git
cd squirrel-ice

# 准备源码和内置配置
make prepare

# 构建 Debug 版本，默认 arm64
make debug

# 构建 Release 并生成 pkg，默认 arm64
make package

# 可选：构建通用二进制，需要依赖库也已按 arm64+x86_64 构建
make package-universal
```

构建产物：

- `squirrel/build/Build/Products/Debug/Squirrel.app`
- `squirrel/build/Build/Products/Release/Squirrel.app`
- `squirrel/package/Squirrel.pkg`

更多构建、签名和公证说明见 [BUILD.md](BUILD.md)。

## 安装依赖

```bash
brew install cmake boost capnp leveldb
```

如果需要发布签名包，请准备 Apple Developer ID 证书，并在构建前设置：

```bash
export DEV_ID="Developer ID Application: Your Name (TEAMID)"
make package
```

默认打包目标为 `arm64`。如需同时支持 Intel Mac，请先确保 librime、Sparkle 和相关依赖均为通用二进制，再运行 `make package-universal`。

## 技术栈

| 层次 | 技术 | 用途 |
| --- | --- | --- |
| 输入法前端 | Squirrel, Swift, AppKit | macOS Input Method Kit、候选窗、按键处理 |
| 设置界面 | SwiftUI | 图形化配置、主题预览、偏好设置 |
| 核心引擎 | librime, C++ | 拼音切分、词典查询、候选排序、用户词典 |
| 配置格式 | YAML | Rime 标准配置，便于迁移和调试 |
| 扩展能力 | librime-lua, OpenCC | Lua 扩展、字符转换和输出处理 |
| 自动更新 | Sparkle 2 | macOS 应用更新框架 |

## 功能状态

| 功能 | 状态 |
| --- | --- |
| 主题切换和实时预览 | 已实现 |
| 自定义主题颜色 | 已实现 |
| 词库启用和禁用 | 已实现 |
| 双拼方案选择 | 已实现 |
| 英文键盘布局选择 | 已实现 |
| 候选窗字号和方向 | 已实现 |
| 用户词典快捷入口 | 已实现 |
| 中英混输 | 已实现 |
| 繁体输出 | 已实现 |
| 符号、日期、计算器、Unicode 等扩展输入 | 已实现 |
| 配置热部署 | 已实现 |
| Sparkle 自动更新框架 | 已集成 |

## 目录结构

```text
squirrel-ice/
├── README.md                 # 中文说明
├── README.en.md              # English README
├── BUILD.md                  # 构建、签名、打包说明
├── LICENSE                   # 根项目许可证
├── NOTICE.md                 # 第三方版权与许可证说明
├── Makefile                  # 根目录构建入口
├── script/build_and_run.sh   # 本地构建和启动脚本
├── scripts/bootstrap_sources.sh
├── squirrel/                 # 定制版 Squirrel 输入法
│   ├── Squirrel.xcodeproj/
│   ├── sources/              # Swift 和 AppKit/SwiftUI 源码
│   ├── data/                 # 内置 Rime 配置和资源
│   ├── themes/               # 内置主题
│   ├── librime/              # Rime 核心引擎
│   ├── plum/                 # Rime 配置管理工具
│   └── Sparkle/              # 自动更新框架
└── vendor/rime-ice/          # 上游 rime-ice 配置参考
```

## 配置目录

首次启动后，内置配置会部署到：

```text
~/Library/Rime/
├── .wusong_version
├── squirrel.custom.yaml
├── default.custom.yaml
├── rime_ice.dict.custom.yaml
├── cn_dicts/
├── en_dicts/
├── lua/
├── opencc/
└── themes/
```

用户可以继续用 Rime 的方式编辑 YAML，也可以通过设置面板完成常见配置。

## 开发命令

```bash
# 快速构建
make debug

# 构建并启动本地 App
./script/build_and_run.sh

# 构建 Release 后启动
./script/build_and_run.sh --release

# 构建、启动并确认进程存在
./script/build_and_run.sh --verify
```

## 发布检查清单

- [ ] `make package` 可以生成 `squirrel/package/Squirrel.pkg`
- [ ] App 和 pkg 已使用 Developer ID 签名
- [ ] pkg 已完成 notarization，并通过 Gatekeeper 验证
- [ ] 如发布通用二进制，librime、Sparkle 和插件均包含 `arm64` 与 `x86_64`
- [ ] README 截图、版本号、变更记录与 Release notes 已更新
- [ ] 发布包包含 `LICENSE` 和必要的第三方版权说明

## 上游项目

本项目建立在以下开源项目之上：

- [rime/squirrel](https://github.com/rime/squirrel)
- [iDvel/rime-ice](https://github.com/iDvel/rime-ice)
- [rime/librime](https://github.com/rime/librime)
- [sparkle-project/Sparkle](https://github.com/sparkle-project/Sparkle)

## 许可证

本仓库的根项目采用 [GNU General Public License v3.0](LICENSE)。部分第三方组件保留其原始许可证和版权声明，详见 [NOTICE.md](NOTICE.md) 以及各子目录中的 `LICENSE` 文件。

如果分发修改版或二进制包，请保留相应许可证文本、版权声明，并遵守 GPL-3.0 对源代码提供和修改标识的要求。
