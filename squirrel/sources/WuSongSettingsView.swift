//
//  WuSongSettingsView.swift
//  Squirrel
//

import SwiftUI

struct WuSongSettingsView: View {
  @ObservedObject var manager: WuSongConfigManager

  var body: some View {
    TabView {
      appearance
        .tabItem { Label("外观", systemImage: "paintpalette") }
      schemas
        .tabItem { Label("输入方案", systemImage: "keyboard") }
      dictionaries
        .tabItem { Label("词库", systemImage: "books.vertical") }
      keyboard
        .tabItem { Label("键盘", systemImage: "command") }
      userDictionary
        .tabItem { Label("用户词典", systemImage: "text.book.closed") }
      about
        .tabItem { Label("关于", systemImage: "info.circle") }
    }
    .padding(20)
    .frame(minWidth: 720, minHeight: 480)
  }

  private var appearance: some View {
    Form {
      Picker("主题", selection: Binding(get: {
        manager.selectedThemeID
      }, set: {
        manager.selectedThemeID = $0
        manager.applyAppearance()
      })) {
        ForEach(manager.themes) { theme in
          Text(theme.name).tag(theme.id)
        }
      }
      Picker("候选方向", selection: Binding(get: {
        manager.candidateLayout
      }, set: {
        manager.candidateLayout = $0
        manager.applyAppearance()
      })) {
        Text("横向").tag("linear")
        Text("纵向").tag("stacked")
      }
      Stepper(value: Binding(get: {
        manager.fontPoint
      }, set: {
        manager.fontPoint = $0
        manager.applyAppearance()
      }), in: 12...28, step: 1) {
        Text("字体大小 \(Int(manager.fontPoint)) pt")
      }
      candidatePreview
    }
  }

  private var candidatePreview: some View {
    HStack(spacing: 14) {
      Text("1. 雾凇")
        .font(.system(size: manager.fontPoint))
        .foregroundStyle(.primary)
      Text("2. 输入法")
        .font(.system(size: manager.fontPoint))
        .foregroundStyle(.secondary)
      Text("3. macOS")
        .font(.system(size: manager.fontPoint))
        .foregroundStyle(.secondary)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(nsColor: .controlBackgroundColor))
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }

  private var schemas: some View {
    Form {
      ForEach(manager.schemas) { schema in
        Toggle(schema.name, isOn: Binding(get: {
          manager.enabledSchemas.contains(schema.id)
        }, set: {
          manager.setSchema(schema.id, enabled: $0)
        }))
        .disabled(schema.id == "rime_ice")
      }
    }
  }

  private var dictionaries: some View {
    Form {
      ForEach(manager.dictionaries) { dictionary in
        Toggle(dictionary.name, isOn: Binding(get: {
          manager.enabledDictionaries.contains(dictionary.id)
        }, set: {
          manager.setDictionary(dictionary.id, enabled: $0)
        }))
        .disabled(dictionary.id == "cn_dicts/8105")
      }
    }
  }

  private var keyboard: some View {
    Form {
      Picker("英文键盘布局", selection: Binding(get: {
        manager.keyboardLayout
      }, set: {
        manager.keyboardLayout = $0
        manager.applyAppearance()
      })) {
        Text("沿用上次").tag("last")
        Text("ABC").tag("default")
        Text("ABC Extended").tag("USExtended")
      }
    }
  }

  private var userDictionary: some View {
    VStack(alignment: .leading, spacing: 12) {
      Button {
        manager.openUserDictionary()
      } label: {
        Label("打开自定义短语", systemImage: "square.and.pencil")
      }
      Button {
        manager.openUserRimeFolder()
      } label: {
        Label("打开 Rime 文件夹", systemImage: "folder")
      }
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  private var about: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("雾凇输入法")
        .font(.title2)
      Text("Squirrel + rime-ice")
        .foregroundStyle(.secondary)
      Text(Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "")
        .foregroundStyle(.secondary)
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}
