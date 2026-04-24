# 雾凇输入法 macOS 构建文档

## 1. 项目概述

本项目的目标是在 **rime-ice（雾凇拼音）** 算法框架和 **Squirrel（鼠须管）** 输入法的基础上，构建一个面向 macOS 的原生输入法产品。核心差异点：

- **开箱即用**：内置雾凇拼音全套配置和词库，用户无需手动部署 YAML 文件
- **可视化配置界面**：皮肤切换、词库管理、输入方案选择等全部图形化操作，对标微信输入法 for macOS
- **macOS 原生体验**：SwiftUI 编写配置面板，AppKit 实现候选窗，与 macOS 设计语言深度融合
- **轻量高性能**：不引入 Electron/Chromium，完全使用系统原生组件

### 技术栈选型

| 层次 | 技术 | 理由 |
|------|------|------|
| 核心引擎 | librime (C++) | Rime 标准引擎，已稳定运行十余年 |
| 输入法前端 | Squirrel (Swift + AppKit) | macOS Input Method Kit 的标准实现 |
| 配置界面 | SwiftUI + Settings | macOS Ventura+ 原生设置窗口风格 |
| 配置存储 | YAML (Rime 原生格式) | 保持与 Rime 生态兼容 |
| 插件系统 | librime-lua | 日期、计算器、Unicode 等扩展功能 |
| 自动更新 | Sparkle 2 | macOS 应用的事实标准更新框架 |

---

## 2. 架构设计

```
┌─────────────────────────────────────────────────────────┐
│                    用户交互层                              │
│  ┌──────────────────┐  ┌──────────────────────────────┐ │
│  │ 配置面板 App      │  │ Squirrel 输入法               │ │
│  │ (SwiftUI)         │  │ (AppKit Input Method)         │ │
│  │ - 皮肤/主题管理   │  │ - 候选窗渲染                 │ │
│  │ - 词库管理        │  │ - 按键处理                    │ │
│  │ - 输入方案切换    │  │ - 内嵌提示                    │ │
│  │ - 用户词典        │  │ - 状态栏图标                  │ │
│  └────────┬─────────┘  └─────────────┬────────────────┘ │
│           │ XPC / File               │ C API               │
├───────────┼──────────────────────────┼─────────────────────┤
│           ▼                          ▼                      │
│  ┌────────────────────────────────────────────────────┐  │
│  │              配置管理层 (Swift)                      │  │
│  │  - YAML 读写 (yaml-cpp / swift-yaml)               │  │
│  │  - 配置校验与热重载                                  │  │
│  │  - Rime Deploy API 调用                             │  │
│  └────────────────────┬───────────────────────────────┘  │
│                       │                                    │
├───────────────────────┼────────────────────────────────────┤
│                       ▼                   核心引擎层         │
│  ┌────────────────────────────────────────────────────┐  │
│  │              librime (C++)                           │  │
│  │  - 拼音切分 (Speller)                                │  │
│  │  - 词典查询 (Translator)                             │  │
│  │  - 候选排序 (Filter)                                 │  │
│  │  - 用户词典学习                                      │  │
│  ├────────────────────────────────────────────────────┤  │
│  │  librime-lua 插件                                    │  │
│  │  - 日期/农历/计算器/UUID/Unicode                     │  │
│  ├────────────────────────────────────────────────────┤  │
│  │  OpenCC 简繁转换                                     │  │
│  └────────────────────────────────────────────────────┘  │
│                                                           │
│  ┌────────────────────────────────────────────────────┐  │
│  │              数据层 (YAML + 词典文件)                  │  │
│  │  - rime_ice 配置 (schema / default / squirrel)      │  │
│  │  - cn_dicts / en_dicts 词典                          │  │
│  │  - lua 脚本                                           │  │
│  │  - 用户数据 (~/Library/Application Support/Rime/)    │  │
│  └────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 组件通信方式

- **Squirrel → librime**：直接调用 C API（`rime_api.h`），同一进程内调用，零开销
- **配置面板 → 配置文件**：Swift 直接读写 YAML 文件，修改后触发 `rime_deploy()` 重部署
- **配置面板 → Squirrel**：通过 Distributed NotificationCenter 通知输入法重新加载配置

---

## 3. 开发环境准备

### 3.1 硬件与系统要求

- macOS 13.0 (Ventura) 或更高版本
- Apple Silicon (arm64) 或 Intel (x86_64)
- Xcode 14.0+
- 约 3GB 磁盘空间（含依赖编译）

### 3.2 安装依赖

```bash
# 1. Xcode Command Line Tools
xcode-select --install

# 2. Homebrew 包管理
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. 编译工具链
brew install cmake
brew install boost        # C++ 库，librime 依赖
brew install capnp        # 序列化框架 (Cap'n Proto)
brew install leveldb      # 键值数据库，用户词典存储

# 4. 可选：代码质量工具
brew install swiftlint
```

### 3.3 克隆源码

```bash
# 创建工作目录
mkdir -p ~/Developer/WuSongIME
cd ~/Developer/WuSongIME

# 克隆 Squirrel（含子模块）
git clone --recursive https://github.com/rime/squirrel.git
cd squirrel

# 子模块说明：
#   librime/   → 核心输入法引擎
#   plum/      → Rime 配置包管理器
#   Sparkle/   → 应用更新框架

# 克隆雾凇拼音配置（独立仓库，后续集成到 App Bundle）
cd ..
git clone --depth 1 https://github.com/iDvel/rime-ice.git
```

### 3.4 验证环境

```bash
# 确认 cmake 可用
cmake --version  # 需要 3.15+

# 确认 Boost 安装路径
echo $BOOST_ROOT  # 或 brew --prefix boost

# 确认 Xcode 版本
xcodebuild -version

# 确认 Swift 版本
swift --version
```

---

## 4. 构建流程

### 4.1 构建 librime（核心引擎）

构建 Squirrel 时会自动构建 librime 子模块，但首次建议单独验证：

```bash
cd ~/Developer/WuSongIME/squirrel/librime

# 安装 librime 额外插件
bash install-plugins.sh rime/librime-lua        # Lua 脚本支持
bash install-plugins.sh rime/librime-octagram   # 八股文语法模型（可选）
bash install-plugins.sh rime/librime-predict    # 预测输入（可选）

# 返回 Squirrel 根目录，通过 Makefile 统编
cd ..
```

### 4.2 构建 Squirrel.app（输入法）

```bash
cd ~/Developer/WuSongIME/squirrel

# 设置环境变量
export BOOST_ROOT=$(brew --prefix boost)
export BUILD_UNIVERSAL=1    # 构建通用二进制 (arm64 + x86_64)

# 构建 Debug 版本（开发阶段）
make debug ARCHS='arm64'

# 构建 Release 版本（发布阶段）
make ARCHS='arm64 x86_64' BUILD_UNIVERSAL=1
```

构建产物：`build/Release/Squirrel.app`（或 `build/Debug/Squirrel.app`）

### 4.3 集成雾凇拼音配置

将 rime-ice 的所有配置文件打包进 Squirrel.app 的资源目录，使其成为内置默认配置：

```bash
cd ~/Developer/WuSongIME/squirrel

# Squirrel 的内置数据目录
RIME_DATA_DIR="data"

# 复制 rime-ice 的全部配置文件
cp -r ../rime-ice/cn_dicts/         "$RIME_DATA_DIR/"
cp -r ../rime-ice/en_dicts/         "$RIME_DATA_DIR/"
cp -r ../rime-ice/lua/              "$RIME_DATA_DIR/"
cp -r ../rime-ice/opencc/           "$RIME_DATA_DIR/"
cp    ../rime-ice/*.yaml            "$RIME_DATA_DIR/"
cp    ../rime-ice/*.txt             "$RIME_DATA_DIR/"
cp    ../rime-ice/*.schema.yaml     "$RIME_DATA_DIR/"
cp    ../rime-ice/*.dict.yaml       "$RIME_DATA_DIR/"
```

### 4.4 修改 Squirrel 初始化逻辑

在 `SquirrelInputController.swift` 的 Rime 初始化阶段，确保内置配置自动部署到用户目录：

```swift
// SquirrelInputController.swift（关键修改片段）

func deployBundledConfigIfNeeded() {
    let userRimeDir = NSHomeDirectory() + "/Library/Rime"
    let bundledRimeDir = Bundle.main.resourcePath! + "/data"

    // 首次启动：将内置 rime-ice 配置同步到用户目录
    let versionFile = userRimeDir + "/.wusong_version"
    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"

    if !FileManager.default.fileExists(atPath: versionFile) {
        try? FileManager.default.copyItem(atPath: bundledRimeDir, toPath: userRimeDir)
        try? currentVersion.write(toFile: versionFile, atomically: true, encoding: .utf8)
        // 触发 Rime 部署
        rime_deploy()
    }
}
```

### 4.5 构建说明总结

| 步骤 | 命令 | 产物 |
|------|------|------|
| 环境准备 | `brew install cmake boost capnp leveldb` | 编译工具链 |
| 克隆仓库 | `git clone --recursive <squirrel-url>` | 完整源码 |
| 安装插件 | `bash librime/install-plugins.sh ...` | librime-lua 等 |
| 集成配置 | 复制 rime-ice 文件到 `data/` | 内置配置 |
| 编译 | `make ARCHS='arm64'` | `Squirrel.app` |
| 打包 | `make package` | `.pkg` 安装包 |

---

## 5. 可视化配置界面

这是本项目相对于原始 Squirrel 最大的新增部分。设计为一个独立的 **SwiftUI App**（嵌入在 Squirrel.app 中作为配套应用），用户可通过菜单栏图标或系统设置打开。

### 5.1 配置面板架构

```
Squirrel.app/
├── Contents/
│   ├── MacOS/
│   │   ├── Squirrel          # 输入法主程序 (AppKit)
│   │   └── WuSongConfig      # 配置面板 (SwiftUI, 新增)
│   ├── Resources/
│   │   ├── data/             # rime-ice 内置配置
│   │   ├── Assets.xcassets/  # 图标资源
│   │   └── themes/           # 内置皮肤定义
│   └── Frameworks/
│       ├── librime.dylib
│       └── Sparkle.framework
```

### 5.2 新增 Swift 源文件

在 `sources/` 目录下新增以下文件：

| 文件 | 功能 |
|------|------|
| `ConfigApp.swift` | 配置面板的 `@main` 入口（独立 target 或通过 URL scheme 唤起） |
| `ThemeSettingsView.swift` | 皮肤/主题管理界面 |
| `DictionarySettingsView.swift` | 词库管理界面（启用/禁用词库、导入自定义词典） |
| `SchemaSettingsView.swift` | 输入方案切换（全拼/双拼/英文等） |
| `KeyboardSettingsView.swift` | 按键设置（翻页键、中英切换键等） |
| `UserDictView.swift` | 用户词典查看与编辑 |
| `AboutView.swift` | 关于页面（版本、更新检查） |
| `ConfigManager.swift` | YAML 配置读写引擎 |
| `ThemeLoader.swift` | 主题文件解析与预览渲染 |

### 5.3 主题系统设计

皮肤文件采用 YAML 格式，存放在 `themes/` 目录下：

```yaml
# themes/macos_light.yaml
name: "macOS Light"
author: "WuSong"
color_scheme:
  candidate_text_color: 0x000000
  candidate_background_color: 0xFFFFFF
  candidate_selected_text_color: 0xFFFFFF
  candidate_selected_background_color: 0x007AFF
  label_color: 0x8E8E93
  comment_text_color: 0x8E8E93
  border_color: 0xE5E5EA
  preedit_background_color: 0xF2F2F7
style:
  corner_radius: 8
  border_width: 1
  font_point: 16
  label_font_point: 12
  candidate_spacing: 4
  window_style: "horizontal"  # horizontal | vertical
  blur_radius: 0
```

Swift 侧读取主题并应用到候选窗：

```swift
// ThemeLoader.swift
struct Theme: Codable {
    let name: String
    let colorScheme: ColorScheme
    let style: StyleConfig
}

final class ThemeLoader {
    static let shared = ThemeLoader()

    // 内置主题
    var builtInThemes: [Theme] {
        let themeDir = Bundle.main.resourcePath! + "/themes"
        // 扫描所有 .yaml 文件并解码
    }

    // 用户自定义主题（来自 ~/Library/Rime/themes/）
    var userThemes: [Theme] { ... }

    func apply(_ theme: Theme) {
        // 写入 squirrel.yaml 并调用 rime_deploy()
    }
}
```

### 5.4 配置管理核心

```swift
// ConfigManager.swift
import Foundation

final class ConfigManager {
    static let shared = ConfigManager()

    let userRimeDir = NSHomeDirectory() + "/Library/Rime"
    let bundledRimeDir = Bundle.main.resourcePath! + "/data"

    // 所有配置操作统一通过此类，直接读写 YAML 文件

    func currentSchemas() -> [String] { ... }          // 读取默认启用的输入方案
    func setSchema(_ id: String, enabled: Bool) { ... } // 修改 default.yaml 的 schema_list
    func currentTheme() -> String { ... }               // 读取 squirrel.yaml 的 style/color_scheme
    func setTheme(_ name: String) { ... }               // 写入 squirrel.yaml
    func activeDictionaries() -> [String] { ... }       // 读取 rime_ice.dict.yaml 的 import_tables
    func setDictionary(_ name: String, enabled: Bool) { ... }

    func redeploy() {
        // 调用 librime API 重新部署
        rime_deploy()
        // 通知 Squirrel 重载配置
        DistributedNotificationCenter.default()
            .post(name: NSNotification.Name("WuSongConfigChanged"), object: nil)
    }
}
```

### 5.5 UI 界面原则

遵循 macOS Human Interface Guidelines：

- **设置窗口**：`Settings` scene（SwiftUI），标签页式侧栏导航
- **控件**：使用 `Toggle`、`Picker`、`PopUpButton`、`ColorWell` 等原生控件
- **布局**：`Form` + `Section`，符合 macOS 设置应用标准布局
- **预览**：主题切换时实时渲染候选窗预览
- **本地化**：所有界面文本使用 `LocalizedStringKey`，支持中文/英文

```
┌──────────────────────────────────────────┐
│  雾凇输入法设置                     ◻ ✕  │
├────────────┬─────────────────────────────┤
│  通用      │  外观                        │
│  外观      │  ┌─────────────────────────┐│
│  输入方案  │  │ 主题     mac OS Light  ∨ ││
│  词库      │  │                         ││
│  快捷键    │  │ 字体大小  ──●──── 16pt  ││
│  用户词典  │  │                         ││
│  关于      │  │ 候选方向  ● 横向 ○ 纵向  ││
│            │  │                         ││
│            │  │ [候选窗实时预览区域]      ││
│            │  │ 1. 候选  2. 候选  3.    ││
│            │  └─────────────────────────┘│
└────────────┴─────────────────────────────┘
```

---

## 6. 打包与分发

### 6.1 构建 Release 包

```bash
cd ~/Developer/WuSongIME/squirrel

# 清理旧产物
make clean

# 设置签名（如需公证）
export DEV_ID="Developer ID Application: Your Name (TEAMID)"

# 构建通用二进制 + 打包
make package ARCHS='arm64 x86_64' BUILD_UNIVERSAL=1

# 产物
# build/package/Squirrel-<version>.pkg    → 可分发的安装包
# build/package/Squirrel-<version>.dmg    → DMG 磁盘映像（配置后生成）
```

### 6.2 公证（Notarization）

```bash
# 存储 App 专用密码（仅首次）
xcrun notarytool store-credentials "WuSongNotary"
# 输入: Apple ID, App-Specific Password, Team ID

# Makefile 已集成：定义 DEV_ID 后自动签名+公证

# 手动公证（如需）
xcrun notarytool submit build/package/Squirrel-*.pkg \
  --keychain-profile "WuSongNotary" \
  --wait

# 装订票据
xcrun stapler staple build/package/Squirrel-*.pkg
```

### 6.3 Sparkle 自动更新配置

```swift
// ConfigApp.swift 中添加更新检查入口
import Sparkle

// 在设置面板的关于页面中：
SUUpdater.shared().checkForUpdates(nil)
```

更新用 `appcast.xml` 托管在 GitHub Releases 或其他 CDN 上。

---

## 7. 开发工作流

### 7.1 Xcode 项目配置

```bash
# 打开 Xcode 项目
open ~/Developer/WuSongIME/squirrel/Squirrel.xcodeproj

# 在 Xcode 中：
# 1. 选择 Squirrel target → Signing & Capabilities → 选择 Developer ID
# 2. 新增 WuSongConfig target（SwiftUI App）
# 3. 将 rime-ice 的 data/ 目录加入 Copy Bundle Resources
```

### 7.2 调试输入法

输入法的调试比较特殊，因为它在系统进程中运行：

```bash
# 1. 构建后安装
sudo make install
# 调试安装也使用系统输入法目录；不要同时保留 ~/Library/Input Methods/Squirrel.app，
# 否则 macOS 会把两份同 Bundle ID 的输入法都列出来。
make -C squirrel install-debug ARCHS='arm64'

# 2. 在 Xcode 中：Debug → Attach to Process → Squirrel

# 3. 注销并重新登录（或杀死输入法进程）
killall Squirrel

# 4. 查看日志
log stream --predicate 'subsystem == "com.wusong.inputmethod"' --level debug

# 5. 查看 Rime 日志
tail -f ~/Library/Rime/rime.log
```

### 7.3 推荐的修改流程

```
修改源码 → make debug → killall Squirrel → 切换到输入法触发加载 → 验证
```

每次修改后无需注销，只需重启 Squirrel 进程即可。

### 7.4 配置文件热重载

```bash
# 通过 Rime API 触发（在 Squirrel 菜单中选 "重新部署"）
# 或通过终端
echo "deploy" | /Library/Input\ Methods/Squirrel.app/Contents/MacOS/Squirrel --deploy
```

---

## 8. 微信输入法功能对标清单

| 微信输入法功能 | 本项目实现方式 | 优先级 |
|---------------|---------------|--------|
| 皮肤商城/主题切换 | 内置 6+ 主题 + 自定义主题导入 | P0 |
| 词库管理（启用/禁用） | 在 Settings 中展示词库列表与开关 | P0 |
| 双拼方案选择 | Picker 选择 + 自动更新 schema_list | P0 |
| 模糊音设置 | YAML speller 配置可视化 | P1 |
| 用户词典管理 | 表格视图，支持删除/编辑词条 | P1 |
| 快捷短语（自定义短语） | 编辑 custom_phrase.txt 的图形界面 | P1 |
| 按键设置（翻页键等） | 可视化键位选择器 | P1 |
| 中英混输 | 启用 melt_eng schema | P0 |
| 繁体输出 | 一键切换 OpenCC | P1 |
| 符号输入 | 内置 symbols_v.yaml 无需额外操作 | P0 |
| 表情推荐 | librime-lua emoji filter，自动候选 | P0 |
| 拼写纠错 | 词库中常见错音纠正 | P1 |
| 云端词库同步 | 通过 iCloud 同步 ~/Library/Rime/ | P2 |
| 输入统计 | 本地 SQLite 记录，面板展示 | P2 |
| 隐私模式 | 暂停用户词典学习 | P2 |

---

## 9. 目录结构总览（最终项目）

```
WuSongIME/
├── squirrel/                    # Squirrel 输入法（修改版）
│   ├── Squirrel.xcodeproj/
│   ├── sources/
│   │   ├── Main.swift
│   │   ├── SquirrelInputController.swift   # [修改] 内置配置自动部署
│   │   ├── SquirrelPanel.swift             # [修改] 主题热切换支持
│   │   ├── SquirrelView.swift
│   │   ├── SquirrelTheme.swift
│   │   ├── SquirrelConfig.swift
│   │   ├── ConfigApp.swift                 # [新增] 配置面板入口
│   │   ├── ThemeSettingsView.swift         # [新增]
│   │   ├── DictionarySettingsView.swift    # [新增]
│   │   ├── SchemaSettingsView.swift        # [新增]
│   │   ├── KeyboardSettingsView.swift      # [新增]
│   │   ├── UserDictView.swift              # [新增]
│   │   ├── AboutView.swift                 # [新增]
│   │   ├── ConfigManager.swift             # [新增]
│   │   ├── ThemeLoader.swift               # [新增]
│   │   └── ...
│   ├── data/                               # [修改] 集成 rime-ice 全部配置
│   │   ├── cn_dicts/
│   │   ├── en_dicts/
│   │   ├── lua/
│   │   ├── opencc/
│   │   ├── *.yaml
│   │   └── *.txt
│   ├── themes/                             # [新增] 内置皮肤
│   │   ├── macos_light.yaml
│   │   ├── macos_dark.yaml
│   │   ├── wechat_style.yaml
│   │   └── ...
│   ├── librime/                # 子模块
│   ├── plum/                   # 子模块
│   ├── Sparkle/                # 子模块
│   └── Makefile
└── BUILD.md                    # 本文档
```

---

## 10. 常见问题

### Q: 为什么不直接使用 Squirrel + 手动安装 rime-ice？
A: 普通用户不应接触到 YAML 配置文件。本项目的核心价值就是将 rime-ice 的强大功能通过图形化界面呈现，让配置输入法变得像微信输入法一样简单。

### Q: 为什么选择修改 Squirrel 而不是从头写一个输入法？
A: Squirrel 是 macOS Input Method Kit 的成熟实现，与 librime 的集成经过多年验证。修改而非重写，可以复用已有的稳定性，将精力集中在配置 UI 和用户体验上。

### Q: 配置面板为什么是独立进程？
A: 输入法运行在系统进程中，UI 调试困难。将配置面板独立为 SwiftUI App，可以通过 XPC 或文件系统与输入法通信，开发和调试效率更高。

### Q: 如何处理 librime 版本更新？
A: librime 作为 git 子模块跟随 Squirrel 仓库。更新时拉取上游变更后重新编译即可。雾凇拼音的词库独立更新，通过 Sparkle 分发。

### Q: App 体积目标？
A: 不含词典约 5MB，含全部词典约 15-20MB。词典占据大部分体积（cn_dicts 中 tencent 词库较大），可通过词库管理界面按需启用/下载。
=======


# 雾凇输入法构建调查记录

## 当前第一阻塞点（first real blocker）

仓库目前只包含 `.gitkeep`，没有任何 Squirrel 或 rime-ice 源码、`Makefile`、`xcodeproj`、`Package.swift`。因此**当前无法触发任何真实构建**。

## 实际构建入口（actual build entrypoint）

该项目的构建入口不是仓库根目录的 Xcode 工程（当前也不存在），而是上游 `rime/squirrel` 仓库中的 `Makefile` 目标：

- `make -C squirrel debug ARCHS='arm64'`
- `make -C squirrel package ARCHS='arm64 x86_64' BUILD_UNIVERSAL=1`

## 本次推进（one concrete step further）

为了把仓库从“空目录无法构建”推进到“可一键拉源码并触发上游构建入口”，新增：

1. `scripts/bootstrap_sources.sh`
   - 拉取 `rime/squirrel`（含 submodule）到 `squirrel/`
   - 拉取 `iDvel/rime-ice` 到 `vendor/rime-ice/`
2. 根目录 `Makefile`
   - `make prepare`：准备源码
   - `make debug`：调用 `squirrel/Makefile` 的 debug 目标
   - `make package`：调用 `squirrel/Makefile` 的 package 目标

## 下一步

执行：

```bash
make prepare
make debug
```

若 `make debug` 失败，再根据具体日志定位下一个阻塞（通常是 Xcode/依赖环境或上游子模块版本问题）。
