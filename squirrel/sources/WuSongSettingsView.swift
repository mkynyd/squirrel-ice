//
//  WuSongSettingsView.swift
//  Squirrel
//

import SwiftUI

struct WuSongSettingsView: View {
  @ObservedObject var manager: WuSongConfigManager

  var body: some View {
    TabView {
      AppearanceTab(manager: manager)
        .tabItem { Label("外观", systemImage: "paintpalette") }
        .tag(0)
      SchemasTab(manager: manager)
        .tabItem { Label("输入方案", systemImage: "keyboard") }
        .tag(1)
      DictionariesTab(manager: manager)
        .tabItem { Label("词库", systemImage: "books.vertical") }
        .tag(2)
      KeyboardTab(manager: manager)
        .tabItem { Label("键盘", systemImage: "command") }
        .tag(3)
      UserDictionaryTab(manager: manager)
        .tabItem { Label("用户词典", systemImage: "text.book.closed") }
        .tag(4)
      AboutTab()
        .tabItem { Label("关于", systemImage: "info.circle") }
        .tag(5)
    }
    .tabViewStyle(.automatic)
    .padding(.horizontal, 40)
    .padding(.vertical, 20)
    .frame(minWidth: 680, maxWidth: .infinity, minHeight: 480, maxHeight: .infinity)
  }
}

// MARK: - Shared Styles

private struct SectionHeader: View {
  let title: String
  var body: some View {
    Text(title)
      .font(.system(size: 11, weight: .semibold))
      .foregroundStyle(.secondary)
      .textCase(.uppercase)
      .padding(.top, 16)
      .padding(.bottom, 8)
  }
}

private struct SettingsGroup<Content: View>: View {
  let content: Content
  init(@ViewBuilder content: () -> Content) { self.content = content() }
  var body: some View {
    VStack(alignment: .leading, spacing: 0) { content }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, 6)
      .padding(.horizontal, 12)
      .background(.quaternary.opacity(0.5))
      .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}

private struct SettingsRow<Content: View>: View {
  let label: String
  let isLast: Bool
  let content: Content
  init(_ label: String, isLast: Bool = false, @ViewBuilder content: () -> Content) {
    self.label = label
    self.isLast = isLast
    self.content = content()
  }
  var body: some View {
    HStack {
      Text(label)
        .frame(width: 120, alignment: .leading)
      content
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.vertical, 6)
    if !isLast {
      Divider()
    }
  }
}

// MARK: - Candidate Preview

struct CandidatePreview: View {
  @ObservedObject var manager: WuSongConfigManager

  var body: some View {
    let theme = manager.currentTheme()
    let backColor = theme?.colorValue(for: "back_color") ?? Color(nsColor: .windowBackgroundColor)
    let textColor = theme?.colorValue(for: "candidate_text_color") ?? .primary
    let labelColor = theme?.colorValue(for: "label_color") ?? .secondary
    let hilitedBack = theme?.colorValue(for: "hilited_candidate_back_color") ?? .blue
    let hilitedText = theme?.colorValue(for: "hilited_candidate_text_color") ?? .white
    let borderColor = theme?.colorValue(for: "border_color") ?? Color(nsColor: .separatorColor)
    let radius = CGFloat(Double(theme?.style["corner_radius"] ?? "8") ?? 8)

    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 14) {
        Text("1.")
          .font(.system(size: 12))
          .foregroundStyle(labelColor)
        Text("雾凇")
          .font(.system(size: manager.fontPoint))
          .foregroundStyle(hilitedText)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(hilitedBack)
          .clipShape(RoundedRectangle(cornerRadius: 4))
        Text("2. 输入法")
          .font(.system(size: manager.fontPoint))
          .foregroundStyle(textColor)
        Text("3. macOS")
          .font(.system(size: manager.fontPoint))
          .foregroundStyle(labelColor)
      }
      .padding(10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(backColor)
      .overlay(
        RoundedRectangle(cornerRadius: radius)
          .stroke(borderColor, lineWidth: 1)
      )
      .clipShape(RoundedRectangle(cornerRadius: radius))
    }
    .padding(.top, 8)
  }
}

// MARK: - Appearance Tab

private struct AppearanceTab: View {
  @ObservedObject var manager: WuSongConfigManager

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        if manager.customizingTheme, let _ = manager.editingTheme {
          ColorCustomizationView(manager: manager)
        } else {
          SectionHeader(title: "主题")
          SettingsGroup {
            SettingsRow("当前主题") {
              Picker("", selection: manager.selectedThemeBinding()) {
                ForEach(manager.themes) { theme in
                  Text(theme.name).tag(theme.id)
                }
              }
              .labelsHidden()
              .pickerStyle(.menu)
              .frame(maxWidth: 220)
            }
Divider()
            HStack {
Text("").frame(width: 120, alignment: .leading)
              Button("自定义颜色...") { manager.startCustomizingTheme() }
                .buttonStyle(.link)
                .font(.system(size: 12))
            }
            .padding(.vertical, 6)
          }

          SectionHeader(title: "布局")
          SettingsGroup {
            SettingsRow("候选方向") {
              Picker("", selection: manager.candidateLayoutBinding()) {
                Text("横向").tag("linear")
                Text("纵向").tag("stacked")
              }
              .labelsHidden()
              .pickerStyle(.segmented)
              .frame(maxWidth: 180)
            }
            SettingsRow("字体大小") {
              HStack(spacing: 8) {
                Slider(value: manager.fontPointBinding(), in: 12...28, step: 1)
                  .frame(maxWidth: 140)
                Text("\(Int(manager.fontPoint)) pt")
                  .font(.system(.body, design: .monospaced))
                  .foregroundStyle(.secondary)
                  .frame(minWidth: 36, alignment: .trailing)
              }
            }
          }

          SectionHeader(title: "预览")
          CandidatePreview(manager: manager)

          Spacer().frame(height: 24)
        }
      }
      .padding(.bottom, 30)
    }
  }
}

// MARK: - Color Customization

private struct ColorCustomizationView: View {
  @ObservedObject var manager: WuSongConfigManager

  var body: some View {
    SectionHeader(title: "自定义颜色")

    if let theme = manager.editingTheme {
      ForEach(WuSongTheme.colorKeys, id: \.key) { item in
        ColorEditRow(
          label: item.label,
          color: theme.colorValue(for: item.key),
          onChange: { newColor in
            manager.updateEditingThemeColor(newColor, for: item.key)
            manager.objectWillChange.send()
          }
        )
        Divider().padding(.vertical, 2)
      }
    }

    HStack(spacing: 12) {
      Spacer()
      Button("取消") { manager.cancelCustomizing() }
      Button("保存主题") { manager.saveCustomizedTheme() }
        .buttonStyle(.borderedProminent)
    }
    .padding(.top, 12)

    SectionHeader(title: "实时预览")
    CandidatePreview(manager: manager)
    Spacer().frame(height: 24)
  }
}

private struct ColorEditRow: View {
  let label: String
  let color: Color
  let onChange: (Color) -> Void

  var body: some View {
    HStack(spacing: 10) {
      Text(label)
        .frame(width: 80, alignment: .leading)
      ColorPicker("", selection: Binding(get: { color }, set: onChange))
        .labelsHidden()
      RoundedRectangle(cornerRadius: 4)
        .fill(color)
        .frame(width: 24, height: 24)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(.secondary.opacity(0.3), lineWidth: 1))
      Text(WuSongTheme.abgrrString(from: color))
        .font(.system(size: 11, design: .monospaced))
        .foregroundStyle(.secondary)
      Spacer()
    }
    .padding(.vertical, 3)
  }
}

// MARK: - Other Tabs

private struct SchemasTab: View {
  @ObservedObject var manager: WuSongConfigManager

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        SectionHeader(title: "已启用的输入方案")
        SettingsGroup {
          ForEach(manager.schemas) { schema in
            Toggle(schema.name, isOn: manager.schemaBinding(for: schema.id))
              .disabled(schema.id == "rime_ice")
              .padding(.vertical, 3)
            if schema.id != manager.schemas.last?.id {
              Divider()
            }
          }
        }
      }
    }
  }
}

private struct DictionariesTab: View {
  @ObservedObject var manager: WuSongConfigManager

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        SectionHeader(title: "已启用的词库")
        SettingsGroup {
          ForEach(manager.dictionaries) { dict in
            Toggle(dict.name, isOn: manager.dictionaryBinding(for: dict.id))
              .disabled(dict.id == "cn_dicts/8105")
              .padding(.vertical, 3)
            if dict.id != manager.dictionaries.last?.id {
              Divider()
            }
          }
        }
      }
    }
  }
}

private struct KeyboardTab: View {
  @ObservedObject var manager: WuSongConfigManager

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        SectionHeader(title: "英文键盘布局")
        SettingsGroup {
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
  }
}

private struct UserDictionaryTab: View {
  @ObservedObject var manager: WuSongConfigManager

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      SectionHeader(title: "管理")
      SettingsGroup {
        Button {
          manager.openUserDictionary()
        } label: {
          Label("打开自定义短语", systemImage: "square.and.pencil")
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
        Divider()
        Button {
          manager.openUserRimeFolder()
        } label: {
          Label("打开 Rime 配置文件夹", systemImage: "folder")
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
      }
      Spacer()
    }
  }
}

private struct AboutTab: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      SectionHeader(title: "关于")
      SettingsGroup {
        VStack(alignment: .leading, spacing: 4) {
          Text("雾凇输入法")
            .font(.title3)
            .fontWeight(.semibold)
          Text("Squirrel + rime-ice")
            .foregroundStyle(.secondary)
          Text("版本 \(Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "-")")
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
      }
      Spacer()
    }
  }
}
