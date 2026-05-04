//
//  WuSongSettingsView.swift
//  Squirrel
//

import SwiftUI

struct WuSongSettingsView: View {
  @ObservedObject var manager: WuSongConfigManager
  @State private var selection: SettingsSection = .overview

  var body: some View {
    HStack(spacing: 0) {
      SettingsSidebar(selection: $selection)

      Divider()

      SettingsDetailView(selection: selection, manager: manager)
    }
    .background(Color.wuSongWindowBackground)
    .frame(minWidth: 860, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
  }
}

// MARK: - Navigation

private enum SettingsSection: String, CaseIterable, Identifiable {
  case overview
  case schemas
  case candidates
  case theme
  case typography
  case inputBehavior
  case shortcuts
  case appRules
  case dictionaries
  case backup

  var id: String { rawValue }

  var title: String {
    switch self {
    case .overview: "总览"
    case .schemas: "输入方案"
    case .candidates: "候选框"
    case .theme: "主题颜色"
    case .typography: "字体排版"
    case .inputBehavior: "输入行为"
    case .shortcuts: "快捷键"
    case .appRules: "应用规则"
    case .dictionaries: "词库短语"
    case .backup: "备份诊断"
    }
  }

  var subtitle: String {
    switch self {
    case .overview: "查看配置状态与快速入口"
    case .schemas: "管理输入方案与切换顺序"
    case .candidates: "自定义候选框外观与行为"
    case .theme: "设置主题色、配色与透明度"
    case .typography: "配置字体、字号与间距"
    case .inputBehavior: "设置输入习惯与智能功能"
    case .shortcuts: "自定义快捷键与功能"
    case .appRules: "按应用/场景配置输入规则"
    case .dictionaries: "管理词库与用户短语"
    case .backup: "备份恢复与系统诊断"
    }
  }

  var symbol: String {
    switch self {
    case .overview: "square.grid.2x2"
    case .schemas: "keyboard"
    case .candidates: "rectangle.on.rectangle"
    case .theme: "paintpalette"
    case .typography: "textformat.size"
    case .inputBehavior: "command"
    case .shortcuts: "display"
    case .appRules: "macwindow"
    case .dictionaries: "text.book.closed"
    case .backup: "lifepreserver"
    }
  }
}

private struct SettingsSidebar: View {
  @Binding var selection: SettingsSection

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Rime / Squirrel 配置")
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(.primary)
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 14)

      ForEach(SettingsSection.allCases) { section in
        SidebarRow(section: section, isSelected: selection == section) {
          selection = section
        }
      }

      Spacer()
    }
    .frame(width: 220)
    .background(.bar)
  }
}

private struct SidebarRow: View {
  let section: SettingsSection
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Label {
        Text(section.title)
          .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
      } icon: {
        Image(systemName: section.symbol)
          .font(.system(size: 13, weight: .medium))
          .frame(width: 18)
      }
      .foregroundStyle(isSelected ? Color.wuSongAccent : Color.primary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 14)
      .padding(.vertical, 9)
      .background {
        if isSelected {
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.wuSongAccent.opacity(0.16))
        }
      }
      .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    .buttonStyle(.plain)
    .padding(.horizontal, 12)
  }
}

// MARK: - Detail

private struct SettingsDetailView: View {
  let selection: SettingsSection
  @ObservedObject var manager: WuSongConfigManager

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        VStack(alignment: .leading, spacing: 6) {
          Text(selection.title)
            .font(.system(size: 22, weight: .semibold))
          Text(selection.subtitle)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)

        switch selection {
        case .overview:
          OverviewPane(manager: manager)
        case .schemas:
          SchemasPane(manager: manager)
        case .candidates:
          CandidatePane(manager: manager)
        case .theme:
          ThemePane(manager: manager)
        case .typography:
          TypographyPane(manager: manager)
        case .inputBehavior:
          InputBehaviorPane(manager: manager)
        case .shortcuts:
          ShortcutPane()
        case .appRules:
          AppRulesPane(manager: manager)
        case .dictionaries:
          DictionariesPane(manager: manager)
        case .backup:
          BackupPane(manager: manager)
        }
      }
      .padding(.horizontal, 26)
      .padding(.vertical, 22)
      .frame(maxWidth: 720, alignment: .leading)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.wuSongContentBackground)
  }
}

// MARK: - Overview

private struct OverviewPane: View {
  @ObservedObject var manager: WuSongConfigManager

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      SettingsCard("当前状态") {
        StatusLine(label: "输入方案", value: "微软拼音 · 双拼")
        StatusLine(label: "同步状态", value: "已同步")
        HStack {
          StatusLine(label: "配置版本", value: "1.2.3")
          Spacer()
          Button("检查更新") {}
            .controlSize(.small)
        }
      }

      SettingsCard("快速入口") {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
          QuickActionButton(title: "输入方案", symbol: "keyboard") {}
          QuickActionButton(title: "候选框", symbol: "rectangle.on.rectangle") {}
          QuickActionButton(title: "主题颜色", symbol: "paintpalette") {}
          QuickActionButton(title: "字体排版", symbol: "textformat.size") {}
          QuickActionButton(title: "应用规则", symbol: "briefcase") {
            manager.openUserRimeFolder()
          }
          QuickActionButton(title: "词库短语", symbol: "book") {
            manager.openUserDictionary()
          }
        }
      }

      SettingsCard("最近使用") {
        RecentLine(title: "微信输入法方案", time: "刚刚")
        RecentLine(title: "个性化候选框设置", time: "10 分钟前")
        RecentLine(title: "工作环境应用规则", time: "1 小时前")
      }

      SettingsCard("备份与恢复") {
        HStack {
          Text("上次备份")
            .foregroundStyle(.secondary)
          Text("2 天前")
          Spacer()
          Button("立即备份") {}
            .controlSize(.small)
            .buttonStyle(.borderedProminent)
            .tint(Color.wuSongAccent.opacity(0.18))
            .foregroundStyle(Color.wuSongAccent)
          Button("恢复配置") {}
            .controlSize(.small)
        }
      }
    }
  }
}

private struct StatusLine: View {
  let label: String
  let value: String

  var body: some View {
    HStack(spacing: 10) {
      Text(label)
        .foregroundStyle(.secondary)
        .frame(width: 68, alignment: .leading)
      Circle()
        .fill(Color.wuSongAccent)
        .frame(width: 7, height: 7)
      Text(value)
    }
    .font(.system(size: 12))
    .padding(.vertical, 3)
  }
}

private struct QuickActionButton: View {
  let title: String
  let symbol: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 6) {
        Image(systemName: symbol)
          .font(.system(size: 17, weight: .medium))
          .frame(width: 34, height: 34)
          .background(Color.wuSongControlBackground)
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .stroke(Color.wuSongSeparator, lineWidth: 1)
          )
        Text(title)
          .font(.system(size: 11))
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
      .frame(maxWidth: .infinity)
    }
    .buttonStyle(.plain)
  }
}

private struct RecentLine: View {
  let title: String
  let time: String

  var body: some View {
    HStack {
      Label(title, systemImage: "clock")
      Spacer()
      Text(time)
        .foregroundStyle(.secondary)
    }
    .font(.system(size: 12))
    .padding(.vertical, 3)
  }
}

// MARK: - Candidate Preview

private struct CandidatePane: View {
  @ObservedObject var manager: WuSongConfigManager

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      SettingsCard("候选栏预览") {
        CandidatePreview(
          theme: manager.currentTheme(),
          count: manager.candidateCount,
          layout: manager.candidateLayout,
          fontPoint: manager.fontPoint
        )
        .padding(.vertical, 4)
      }

      SettingsCard("布局") {
        SettingRow("候选方向") {
          Picker("", selection: manager.candidateLayoutBinding()) {
            Text("横向").tag("linear")
            Text("纵向").tag("stacked")
          }
          .labelsHidden()
          .pickerStyle(.segmented)
          .frame(width: 180)
        }

        SettingRow("字体大小") {
          FontSizeControl(manager: manager)
        }

        SettingRow("候选词数量") {
          CandidateCountControl(manager: manager)
        }
      }
    }
  }
}

struct CandidatePreview: View {
  var theme: WuSongTheme?
  var count = 5
  var layout = "linear"
  var fontPoint = 14.0

  private let items = [
    CandidatePreviewEntry(id: "1", text: "参考这个设计"),
    CandidatePreviewEntry(id: "2", text: "参考者"),
    CandidatePreviewEntry(id: "3", text: "参考"),
    CandidatePreviewEntry(id: "4", text: "餐卡"),
    CandidatePreviewEntry(id: "5", text: "餐"),
    CandidatePreviewEntry(id: "6", text: "惨"),
    CandidatePreviewEntry(id: "7", text: "参"),
    CandidatePreviewEntry(id: "8", text: "残"),
    CandidatePreviewEntry(id: "9", text: "灿")
  ]

  var body: some View {
    Group {
      if layout == "stacked" {
        verticalPreview
      } else {
        horizontalPreview
      }
    }
    .padding(6)
    .background {
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(backgroundColor)
        .shadow(color: .black.opacity(isDarkPreview ? 0.35 : 0.12), radius: 12, x: 0, y: 4)
    }
    .overlay {
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .stroke(borderColor, lineWidth: borderWidth)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var horizontalPreview: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 0) {
        ForEach(items.prefix(count)) { item in
          CandidatePreviewItem(
            number: item.id,
            text: item.text,
            isSelected: item.id == "1",
            style: style
          )
        }

        pagingControls
      }
      .fixedSize(horizontal: true, vertical: true)
    }
  }

  private var verticalPreview: some View {
    HStack(alignment: .top, spacing: 8) {
      VStack(alignment: .leading, spacing: 2) {
        ForEach(items.prefix(count)) { item in
          CandidatePreviewItem(
            number: item.id,
            text: item.text,
            isSelected: item.id == "1",
            style: style
          )
        }
      }
      pagingControls
    }
    .fixedSize(horizontal: false, vertical: true)
  }

  private var pagingControls: some View {
    HStack(spacing: 0) {
      Divider()
        .frame(height: layout == "stacked" ? max(30, CGFloat(count) * (fontPoint + 12)) : 24)
        .padding(.horizontal, 8)

      Image(systemName: "chevron.down")
        .font(.system(size: max(12, fontPoint - 1), weight: .medium))
        .foregroundStyle(secondaryColor)
        .frame(width: 28)

      Divider()
        .frame(height: layout == "stacked" ? max(30, CGFloat(count) * (fontPoint + 12)) : 24)
        .padding(.horizontal, 6)

      Image(systemName: "command")
        .font(.system(size: fontPoint))
        .foregroundStyle(secondaryColor)
        .frame(width: 24)
    }
  }

  private var style: CandidatePreviewStyle {
    CandidatePreviewStyle(
      fontPoint: fontPoint,
      selectedBackground: selectedBackground,
      selectedForeground: selectedForeground,
      foreground: foregroundColor,
      secondaryForeground: secondaryColor,
      highlightRadius: highlightRadius,
      selectedNeedsStroke: selectedNeedsStroke
    )
  }

  private var isDarkPreview: Bool {
    backgroundColor.isPerceptuallyDark
  }

  private var backgroundColor: Color {
    theme?.colorValue(for: "back_color") ?? Color(nsColor: .textBackgroundColor)
  }

  private var foregroundColor: Color {
    theme?.colorValue(for: "candidate_text_color") ?? .primary
  }

  private var secondaryColor: Color {
    theme?.colorValue(for: "label_color") ?? .secondary
  }

  private var selectedBackground: Color {
    theme?.colorValue(for: "hilited_candidate_back_color") ?? Color.wuSongAccent
  }

  private var selectedForeground: Color {
    theme?.colorValue(for: "hilited_candidate_text_color") ?? .white
  }

  private var borderColor: Color {
    theme?.colorValue(for: "border_color") ?? Color.wuSongSeparator
  }

  private var cornerRadius: CGFloat {
    CGFloat(Double(theme?.style["corner_radius"] ?? "10") ?? 10)
  }

  private var highlightRadius: CGFloat {
    CGFloat(Double(theme?.style["hilited_corner_radius"] ?? "6") ?? 6)
  }

  private var borderWidth: CGFloat {
    CGFloat(Double(theme?.style["border_width"] ?? "1") ?? 1)
  }

  private var selectedNeedsStroke: Bool {
    selectedBackground.opacityValue < 0.08
  }
}

private struct CandidatePreviewEntry: Identifiable {
  let id: String
  let text: String
}

private struct CandidatePreviewItem: View {
  let number: String
  let text: String
  let isSelected: Bool
  let style: CandidatePreviewStyle

  var body: some View {
    HStack(spacing: 5) {
      Text(number)
        .font(.system(size: max(12, style.fontPoint - 1), weight: .semibold, design: .rounded))
      Text(text)
        .font(.system(size: style.fontPoint, weight: isSelected ? .semibold : .regular))
    }
    .foregroundStyle(isSelected ? style.selectedForeground : style.foreground)
    .padding(.horizontal, isSelected ? 12 : 10)
    .padding(.vertical, 6)
    .background {
      if isSelected {
        RoundedRectangle(cornerRadius: style.highlightRadius, style: .continuous)
          .fill(style.selectedBackground)
      }
    }
    .overlay {
      if isSelected && style.selectedNeedsStroke {
        RoundedRectangle(cornerRadius: style.highlightRadius, style: .continuous)
          .stroke(style.selectedForeground, lineWidth: 1.2)
      }
    }
  }
}

private struct CandidatePreviewStyle {
  let fontPoint: Double
  let selectedBackground: Color
  let selectedForeground: Color
  let foreground: Color
  let secondaryForeground: Color
  let highlightRadius: CGFloat
  let selectedNeedsStroke: Bool
}

// MARK: - Theme

private struct ThemePane: View {
  @ObservedObject var manager: WuSongConfigManager

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      SettingsCard("主题") {
        SettingRow("当前主题") {
          Picker("", selection: manager.selectedThemeBinding()) {
            ForEach(manager.themes) { theme in
              Text(theme.name).tag(theme.id)
            }
          }
          .labelsHidden()
          .pickerStyle(.menu)
          .frame(width: 240)
        }

        HStack {
          Spacer().frame(width: 92)
          Button("自定义颜色...") { manager.startCustomizingTheme() }
            .buttonStyle(.link)
            .font(.system(size: 12))
        }
      }

      if manager.customizingTheme {
        ColorCustomizationView(manager: manager)
      } else {
        SettingsCard("候选栏配色参考") {
          VStack(alignment: .leading, spacing: 8) {
            Text("当前配置")
              .font(.system(size: 12, weight: .medium))
            CandidatePreview(
              theme: manager.currentTheme(),
              count: manager.candidateCount,
              layout: manager.candidateLayout,
              fontPoint: manager.fontPoint
            )
          }
        }
      }
    }
  }
}

private struct ColorCustomizationView: View {
  @ObservedObject var manager: WuSongConfigManager

  var body: some View {
    SettingsCard("自定义颜色") {
      if let theme = manager.editingTheme {
        CandidatePreview(
          theme: theme,
          count: manager.candidateCount,
          layout: manager.candidateLayout,
          fontPoint: manager.fontPoint
        )
        .padding(.bottom, 8)

        ForEach(WuSongTheme.colorKeys, id: \.key) { item in
          ColorEditRow(
            label: item.label,
            color: theme.colorValue(for: item.key),
            onChange: { newColor in
              manager.updateEditingThemeColor(newColor, for: item.key)
              manager.objectWillChange.send()
            }
          )
          if item.key != WuSongTheme.colorKeys.last?.key {
            Divider()
          }
        }
      }

      HStack {
        Spacer()
        Button("取消") { manager.cancelCustomizing() }
        Button("保存主题") { manager.saveCustomizedTheme() }
          .buttonStyle(.borderedProminent)
      }
      .padding(.top, 10)
    }
  }
}

private struct ColorEditRow: View {
  let label: String
  let color: Color
  let onChange: (Color) -> Void

  var body: some View {
    HStack(spacing: 10) {
      Text(label)
        .frame(width: 92, alignment: .leading)
      ColorPicker("", selection: Binding(get: { color }, set: onChange))
        .labelsHidden()
      RoundedRectangle(cornerRadius: 4, style: .continuous)
        .fill(color)
        .frame(width: 24, height: 24)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(.secondary.opacity(0.3), lineWidth: 1))
      Text(WuSongTheme.abgrrString(from: color))
        .font(.system(size: 11, design: .monospaced))
        .foregroundStyle(.secondary)
      Spacer()
    }
    .font(.system(size: 12))
    .padding(.vertical, 5)
  }
}

// MARK: - Existing Setting Panes

private struct SchemasPane: View {
  @ObservedObject var manager: WuSongConfigManager
  @State private var draftSchemas: Set<String> = []

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      SettingsCard("已启用的输入方案") {
        ForEach(manager.schemas) { schema in
          Toggle(schema.name, isOn: draftBinding(for: schema.id))
            .disabled(schema.id == "rime_ice")
            .padding(.vertical, 4)
          if schema.id != manager.schemas.last?.id {
            Divider()
          }
        }
      }

      HStack(spacing: 10) {
        Button("取消") {
          draftSchemas = manager.enabledSchemas
        }
        .disabled(!hasChanges)

        Button("保存") {
          manager.applySchemas(draftSchemas)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!hasChanges)

        Text(hasChanges ? "保存后才会重新部署输入方案。" : "当前选择已保存。")
          .font(.system(size: 12))
          .foregroundStyle(.secondary)

        Spacer()
      }
    }
    .onAppear {
      draftSchemas = manager.enabledSchemas
    }
    .onChange(of: manager.enabledSchemas) { newValue in
      if !hasChanges {
        draftSchemas = newValue
      }
    }
  }

  private var hasChanges: Bool {
    draftSchemas != manager.enabledSchemas
  }

  private func draftBinding(for id: String) -> Binding<Bool> {
    Binding(
      get: { draftSchemas.contains(id) },
      set: { isEnabled in
        if isEnabled {
          draftSchemas.insert(id)
        } else if id != "rime_ice" {
          draftSchemas.remove(id)
        }
      }
    )
  }
}

private struct DictionariesPane: View {
  @ObservedObject var manager: WuSongConfigManager

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      SettingsCard("已启用的词库") {
        ForEach(manager.dictionaries) { dict in
          Toggle(dict.name, isOn: manager.dictionaryBinding(for: dict.id))
            .disabled(dict.id == "cn_dicts/8105")
            .padding(.vertical, 4)
          if dict.id != manager.dictionaries.last?.id {
            Divider()
          }
        }
      }

      SettingsCard("用户短语") {
        PlainActionButton(title: "打开自定义短语", symbol: "square.and.pencil") {
          manager.openUserDictionary()
        }
        Divider()
        PlainActionButton(title: "打开 Rime 配置文件夹", symbol: "folder") {
          manager.openUserRimeFolder()
        }
      }
    }
  }
}

private struct TypographyPane: View {
  @ObservedObject var manager: WuSongConfigManager

  var body: some View {
    SettingsCard("字体排版") {
      SettingRow("字号") {
        FontSizeControl(manager: manager)
      }

      SettingRow("候选方向") {
        Picker("", selection: manager.candidateLayoutBinding()) {
          Text("横向").tag("linear")
          Text("纵向").tag("stacked")
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .frame(width: 180)
      }
    }
  }
}

private struct InputBehaviorPane: View {
  @ObservedObject var manager: WuSongConfigManager

  var body: some View {
    SettingsCard("英文键盘布局") {
      Picker("", selection: manager.keyboardLayoutBinding()) {
        Text("沿用上次").tag("last")
        Text("ABC").tag("default")
        Text("ABC Extended").tag("USExtended")
      }
      .labelsHidden()
      .pickerStyle(.radioGroup)
      .padding(.vertical, 4)
    }
  }
}

private struct ShortcutPane: View {
  var body: some View {
    SettingsCard("快捷键") {
      ShortcutRow(title: "上一页", shortcut: "Page Up")
      ShortcutRow(title: "下一页", shortcut: "Page Down")
      ShortcutRow(title: "切换中英文", shortcut: "Shift")
      ShortcutRow(title: "展开功能菜单", shortcut: "⌘")
    }
  }
}

private struct ShortcutRow: View {
  let title: String
  let shortcut: String

  var body: some View {
    HStack {
      Text(title)
      Spacer()
      Text(shortcut)
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Color.wuSongControlBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.wuSongSeparator, lineWidth: 1))
    }
    .font(.system(size: 12))
    .padding(.vertical, 5)
  }
}

private struct AppRulesPane: View {
  @ObservedObject var manager: WuSongConfigManager

  var body: some View {
    SettingsCard("应用规则") {
      PlainActionButton(title: "打开 Rime 配置文件夹", symbol: "folder") {
        manager.openUserRimeFolder()
      }
      Divider()
      Text("可在 squirrel.custom.yaml 中按应用 Bundle ID 配置 ascii_mode、inline 等规则。")
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
        .padding(.vertical, 6)
    }
  }
}

private struct BackupPane: View {
  @ObservedObject var manager: WuSongConfigManager

  var body: some View {
    SettingsCard("备份与诊断") {
      PlainActionButton(title: "打开 Rime 配置文件夹", symbol: "folder") {
        manager.openUserRimeFolder()
      }
      Divider()
      PlainActionButton(title: "打开自定义短语", symbol: "text.book.closed") {
        manager.openUserDictionary()
      }
      Divider()
      HStack {
        Text("配置版本")
          .foregroundStyle(.secondary)
        Spacer()
        Text("1.2.3")
          .font(.system(.body, design: .monospaced))
      }
      .font(.system(size: 12))
      .padding(.vertical, 6)
    }
  }
}

// MARK: - Shared Controls

private struct SettingsCard<Content: View>: View {
  let title: String
  let content: Content

  init(_ title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.system(size: 13, weight: .semibold))
      content
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(Color.wuSongCardBackground)
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .stroke(Color.wuSongSeparator, lineWidth: 1)
    )
  }
}

private struct SettingRow<Content: View>: View {
  let label: String
  let content: Content

  init(_ label: String, @ViewBuilder content: () -> Content) {
    self.label = label
    self.content = content()
  }

  var body: some View {
    HStack(spacing: 12) {
      Text(label)
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
        .frame(width: 80, alignment: .leading)
      content
      Spacer()
    }
    .padding(.vertical, 5)
  }
}

private struct FontSizeControl: View {
  @ObservedObject var manager: WuSongConfigManager

  var body: some View {
    HStack(spacing: 8) {
      Slider(value: manager.fontPointBinding(), in: 12...28, step: 1)
        .frame(width: 160)
      Text("\(Int(manager.fontPoint)) pt")
        .font(.system(size: 12, design: .monospaced))
        .foregroundStyle(.secondary)
        .frame(width: 44, alignment: .trailing)
    }
  }
}

private struct CandidateCountControl: View {
  @ObservedObject var manager: WuSongConfigManager

  var body: some View {
    HStack(spacing: 8) {
      Stepper("", value: manager.candidateCountBinding(), in: 3...9)
        .labelsHidden()
      Text("\(manager.candidateCount) 个")
        .font(.system(size: 12, design: .monospaced))
        .foregroundStyle(.secondary)
        .frame(width: 36, alignment: .trailing)
    }
  }
}

private struct PlainActionButton: View {
  let title: String
  let symbol: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Label(title, systemImage: symbol)
        .font(.system(size: 12))
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .padding(.vertical, 6)
  }
}

// MARK: - Colors

private extension Color {
  static let wuSongAccent = Color(red: 0.05, green: 0.62, blue: 0.36)
  static let wuSongWindowBackground = Color(nsColor: .windowBackgroundColor)
  static let wuSongContentBackground = Color(nsColor: .controlBackgroundColor)
  static let wuSongCardBackground = Color(nsColor: .textBackgroundColor).opacity(0.72)
  static let wuSongControlBackground = Color(nsColor: .controlBackgroundColor)
  static let wuSongSeparator = Color(nsColor: .separatorColor).opacity(0.65)

  var opacityValue: Double {
    guard let rgba = rgbaComponents else { return 1 }
    return rgba.alpha
  }

  var isPerceptuallyDark: Bool {
    guard let rgba = rgbaComponents else { return false }
    let luminance = 0.2126 * rgba.red + 0.7152 * rgba.green + 0.0722 * rgba.blue
    return luminance < 0.45
  }

  private var rgbaComponents: (red: Double, green: Double, blue: Double, alpha: Double)? {
    let nsColor = NSColor(self)
    guard let rgb = nsColor.usingColorSpace(.deviceRGB) else { return nil }
    return (
      Double(rgb.redComponent),
      Double(rgb.greenComponent),
      Double(rgb.blueComponent),
      Double(rgb.alphaComponent)
    )
  }
}
