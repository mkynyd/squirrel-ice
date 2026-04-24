//
//  WuSongConfigManager.swift
//  Squirrel
//

import AppKit
import Combine
import Foundation
import SwiftUI

struct WuSongSchemaOption: Identifiable, Hashable {
  let id: String
  let name: String
}

struct WuSongDictionaryOption: Identifiable, Hashable {
  let id: String
  let name: String
}

final class WuSongConfigManager: ObservableObject {
  static let shared = WuSongConfigManager()
  static let configChangedNotificationName = "WuSongConfigChanged"

  @Published private(set) var themes: [WuSongTheme] = []
  @Published var selectedThemeID = "macos_light"
  @Published var keyboardLayout = "last"
  @Published var candidateLayout = "linear"
  @Published var fontPoint = 16.0
  @Published var enabledSchemas: Set<String> = []
  @Published var enabledDictionaries: Set<String> = []
  @Published var customizingTheme = false
  @Published var editingTheme: WuSongTheme?

  let schemas: [WuSongSchemaOption] = [
    .init(id: "rime_ice", name: "雾凇拼音"),
    .init(id: "t9", name: "中文九键"),
    .init(id: "double_pinyin", name: "自然码双拼"),
    .init(id: "double_pinyin_abc", name: "智能 ABC 双拼"),
    .init(id: "double_pinyin_mspy", name: "微软双拼"),
    .init(id: "double_pinyin_sogou", name: "搜狗双拼"),
    .init(id: "double_pinyin_flypy", name: "小鹤双拼"),
    .init(id: "double_pinyin_ziguang", name: "紫光双拼"),
    .init(id: "double_pinyin_jiajia", name: "拼音加加双拼")
  ]

  let dictionaries: [WuSongDictionaryOption] = [
    .init(id: "cn_dicts/8105", name: "基础字表"),
    .init(id: "cn_dicts/41448", name: "大字表"),
    .init(id: "cn_dicts/base", name: "基础词库"),
    .init(id: "cn_dicts/ext", name: "扩展词库"),
    .init(id: "cn_dicts/tencent", name: "腾讯词向量"),
    .init(id: "cn_dicts/others", name: "杂项词库"),
    .init(id: "en_dicts/en", name: "英文词库"),
    .init(id: "en_dicts/en_ext", name: "英文扩展")
  ]

  private let fileManager = FileManager.default
  private var userRimeDir: URL { SquirrelApp.userDir }
  private var markerURL: URL { userRimeDir.appendingPathComponent(".wusong_version") }
  private var squirrelCustomURL: URL { userRimeDir.appendingPathComponent("squirrel.custom.yaml") }
  private var defaultCustomURL: URL { userRimeDir.appendingPathComponent("default.custom.yaml") }
  private var dictionaryCustomURL: URL { userRimeDir.appendingPathComponent("rime_ice.dict.custom.yaml") }

  private init() {
    enabledSchemas = Set(schemas.map(\.id))
    enabledDictionaries = ["cn_dicts/8105", "cn_dicts/base", "cn_dicts/ext", "cn_dicts/tencent", "cn_dicts/others"]
    reload()
  }

  func reload() {
    themes = ThemeLoader.shared.loadBuiltInThemes() + ThemeLoader.shared.loadUserThemes()
    if !themes.contains(where: { $0.id == selectedThemeID }), let first = themes.first {
      selectedThemeID = first.id
    }
  }

  func currentTheme() -> WuSongTheme? {
    themes.first { $0.id == selectedThemeID }
  }

  func selectedThemeBinding() -> Binding<String> {
    Binding(
      get: { self.selectedThemeID },
      set: { newID in
        self.selectedThemeID = newID
        self.applyAppearance()
      }
    )
  }

  func candidateLayoutBinding() -> Binding<String> {
    Binding(
      get: { self.candidateLayout },
      set: { self.candidateLayout = $0; self.applyAppearance() }
    )
  }

  func fontPointBinding() -> Binding<Double> {
    Binding(
      get: { self.fontPoint },
      set: { self.fontPoint = $0; self.applyAppearance() }
    )
  }

  func keyboardLayoutBinding() -> Binding<String> {
    Binding(
      get: { self.keyboardLayout },
      set: { self.keyboardLayout = $0; self.applyAppearance() }
    )
  }

  func schemaBinding(for id: String) -> Binding<Bool> {
    Binding(
      get: { self.enabledSchemas.contains(id) },
      set: { self.setSchema(id, enabled: $0) }
    )
  }

  func dictionaryBinding(for id: String) -> Binding<Bool> {
    Binding(
      get: { self.enabledDictionaries.contains(id) },
      set: { self.setDictionary(id, enabled: $0) }
    )
  }

  func startCustomizingTheme() {
    guard let theme = currentTheme() else { return }
    editingTheme = theme
    customizingTheme = true
  }

  func updateEditingThemeColor(_ color: Color, for key: String) {
    editingTheme?.colorScheme[key] = WuSongTheme.abgrrString(from: color)
  }

  func saveCustomizedTheme() {
    guard let theme = editingTheme else { return }
    let newTheme = WuSongTheme(
      id: theme.id + "_custom",
      name: theme.name + "（自定义）",
      author: theme.author,
      colorScheme: theme.colorScheme,
      style: theme.style
    )
    ThemeLoader.shared.saveUserTheme(newTheme)
    reload()
    if themes.contains(where: { $0.id == newTheme.id }) {
      selectedThemeID = newTheme.id
      applyAppearance()
    }
    editingTheme = nil
    customizingTheme = false
  }

  func cancelCustomizing() {
    editingTheme = nil
    customizingTheme = false
  }

  func deployBundledConfigIfNeeded(currentVersion: String) -> Bool {
    guard let sharedSupportURL = Bundle.main.sharedSupportURL,
          fileManager.fileExists(atPath: sharedSupportURL.appendingPathComponent("rime_ice.schema.yaml").path) else {
      return false
    }
    try? fileManager.createDirectory(at: userRimeDir, withIntermediateDirectories: true)
    let marker = (try? String(contentsOf: markerURL, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
    guard marker != currentVersion else { return false }

    var copiedAnyFile = false
    let entries = (try? fileManager.contentsOfDirectory(at: sharedSupportURL, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
    for sourceURL in entries where shouldCopyBundledRimeEntry(sourceURL) {
      let destinationURL = userRimeDir.appendingPathComponent(sourceURL.lastPathComponent)
      if fileManager.fileExists(atPath: destinationURL.path) { continue }
      do {
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        copiedAnyFile = true
      } catch {
        print("Failed to copy bundled Rime data \(sourceURL.lastPathComponent): \(error.localizedDescription)")
      }
    }
    do {
      try currentVersion.write(to: markerURL, atomically: true, encoding: .utf8)
    } catch {
      print("Failed to write WuSong version marker: \(error.localizedDescription)")
    }
    return copiedAnyFile || marker.isEmpty
  }

  func setSchema(_ id: String, enabled: Bool) {
    if enabled { enabledSchemas.insert(id) }
    else if id != "rime_ice" { enabledSchemas.remove(id) }
    writeDefaultCustom()
    redeploy()
  }

  func setDictionary(_ id: String, enabled: Bool) {
    if enabled { enabledDictionaries.insert(id) }
    else if id != "cn_dicts/8105" { enabledDictionaries.remove(id) }
    writeDictionaryCustom()
    redeploy()
  }

  func applyAppearance() {
    writeSquirrelCustom()
    redeploy()
  }

  func openUserDictionary() {
    let url = userRimeDir.appendingPathComponent("custom_phrase.txt")
    if !fileManager.fileExists(atPath: url.path) {
      try? "# Rime custom phrases\n".write(to: url, atomically: true, encoding: .utf8)
    }
    NSWorkspace.shared.open(url)
  }

  func openUserRimeFolder() {
    NSWorkspace.shared.open(userRimeDir)
  }
}

private extension WuSongConfigManager {
  func shouldCopyBundledRimeEntry(_ url: URL) -> Bool {
    let name = url.lastPathComponent
    if ["cn_dicts", "en_dicts", "lua", "opencc"].contains(name) { return true }
    return url.pathExtension == "yaml" || url.pathExtension == "txt"
  }

  func writeSquirrelCustom() {
    try? fileManager.createDirectory(at: userRimeDir, withIntermediateDirectories: true)
    let theme = themes.first { $0.id == selectedThemeID } ?? themes.first
    var lines = [
      "# WuSong generated settings. Edit through the settings window when possible.",
      "patch:",
      "  keyboard_layout: \(yamlScalar(keyboardLayout))",
      "  style/color_scheme: \(yamlScalar(selectedThemeID))",
      "  style/color_scheme_dark: \(yamlScalar(selectedThemeID))",
      "  style/candidate_list_layout: \(yamlScalar(candidateLayout))",
      "  style/font_point: \(fontPoint)"
    ]
    if let theme = theme {
      lines.append("  \"preset_color_schemes/\(theme.id)\":")
      lines.append("    name: \(yamlScalar(theme.name))")
      if !theme.author.isEmpty {
        lines.append("    author: \(yamlScalar(theme.author))")
      }
      let merged = theme.style.merging(theme.colorScheme) { _, new in new }
      for key in merged.keys.sorted() {
        lines.append("    \(key): \(yamlScalar(merged[key] ?? ""))")
      }
    }
    write(lines: lines, to: squirrelCustomURL)
  }

  func writeDefaultCustom() {
    try? fileManager.createDirectory(at: userRimeDir, withIntermediateDirectories: true)
    let selected = schemas.map(\.id).filter { enabledSchemas.contains($0) }
    var lines = [
      "# WuSong generated schema settings.",
      "patch:",
      "  schema_list:"
    ]
    for schema in selected { lines.append("    - schema: \(schema)") }
    write(lines: lines, to: defaultCustomURL)
  }

  func writeDictionaryCustom() {
    try? fileManager.createDirectory(at: userRimeDir, withIntermediateDirectories: true)
    let selected = dictionaries.map(\.id).filter { enabledDictionaries.contains($0) }
    var lines = [
      "# WuSong generated dictionary settings.",
      "patch:",
      "  import_tables:"
    ]
    for dictionary in selected { lines.append("    - \(dictionary)") }
    write(lines: lines, to: dictionaryCustomURL)
  }

  func redeploy() {
    DistributedNotificationCenter.default().postNotificationName(.init(Self.configChangedNotificationName), object: nil)
  }

  func write(lines: [String], to url: URL) {
    do {
      try (lines.joined(separator: "\n") + "\n").write(to: url, atomically: true, encoding: .utf8)
    } catch {
      print("Failed to write \(url.lastPathComponent): \(error.localizedDescription)")
    }
  }

  func yamlScalar(_ value: String) -> String {
    if value.range(of: #"^[A-Za-z0-9_./:-]+$"#, options: .regularExpression) != nil { return value }
    return "\"" + value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
  }
}
