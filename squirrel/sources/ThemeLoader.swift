//
//  ThemeLoader.swift
//  Squirrel
//

import AppKit
import Foundation
import SwiftUI

struct WuSongTheme: Identifiable, Hashable {
  let id: String
  let name: String
  let author: String
  var colorScheme: [String: String]
  let style: [String: String]

  func hash(into hasher: inout Hasher) { hasher.combine(id) }
  static func == (lhs: WuSongTheme, rhs: WuSongTheme) -> Bool { lhs.id == rhs.id }
}

extension WuSongTheme {
  static let colorKeys: [(key: String, label: String)] = [
    ("back_color", "背景色"),
    ("candidate_back_color", "候选背景色"),
    ("candidate_text_color", "候选文字色"),
    ("hilited_candidate_back_color", "高亮背景色"),
    ("hilited_candidate_text_color", "高亮文字色"),
    ("label_color", "标签色"),
    ("comment_text_color", "注释色"),
    ("border_color", "边框色")
  ]

  func colorValue(for key: String) -> Color {
    guard let hex = colorScheme[key] else { return .gray }
    return Self.color(fromABGGRR: hex)
  }

  static func color(fromABGGRR hex: String) -> Color {
    let raw = hex.trimmingCharacters(in: .whitespaces)
    let cleaned = raw.hasPrefix("0x") || raw.hasPrefix("0X")
      ? String(raw.dropFirst(2)) : raw
    guard cleaned.count == 8,
          let value = UInt32(cleaned, radix: 16) else { return .gray }
    let a = CGFloat((value >> 24) & 0xFF) / 255.0
    let b = CGFloat((value >> 16) & 0xFF) / 255.0
    let g = CGFloat((value >> 8) & 0xFF) / 255.0
    let r = CGFloat(value & 0xFF) / 255.0
    return Color(nsColor: NSColor(red: r, green: g, blue: b, alpha: a))
  }

  static func abgrrString(from color: Color) -> String {
    let nsColor = NSColor(color)
    guard let rgb = nsColor.usingColorSpace(.deviceRGB) else { return "0xFFFFFFFF" }
    let r = UInt8(clamping: Int(round(rgb.redComponent * 255)))
    let g = UInt8(clamping: Int(round(rgb.greenComponent * 255)))
    let b = UInt8(clamping: Int(round(rgb.blueComponent * 255)))
    let a = UInt8(clamping: Int(round(rgb.alphaComponent * 255)))
    return String(format: "0x%02X%02X%02X%02X", a, b, g, r)
  }

  static func abgrrNSColor(from hex: String) -> NSColor {
    let raw = hex.trimmingCharacters(in: .whitespaces)
    let cleaned = raw.hasPrefix("0x") || raw.hasPrefix("0X")
      ? String(raw.dropFirst(2)) : raw
    guard cleaned.count == 8,
          let value = UInt32(cleaned, radix: 16) else { return .gray }
    let a = CGFloat((value >> 24) & 0xFF) / 255.0
    let b = CGFloat((value >> 16) & 0xFF) / 255.0
    let g = CGFloat((value >> 8) & 0xFF) / 255.0
    let r = CGFloat(value & 0xFF) / 255.0
    return NSColor(red: r, green: g, blue: b, alpha: a)
  }
}

final class ThemeLoader {
  static let shared = ThemeLoader()

  func loadBuiltInThemes() -> [WuSongTheme] {
    guard let sharedSupportURL = Bundle.main.sharedSupportURL else { return Self.fallbackThemes }
    let themeDirectory = sharedSupportURL.appendingPathComponent("themes", isDirectory: true)
    let themes = loadThemes(from: themeDirectory)
    return themes.isEmpty ? Self.fallbackThemes : themes
  }

  func loadUserThemes() -> [WuSongTheme] {
    let themeDirectory = SquirrelApp.userDir.appendingPathComponent("themes", isDirectory: true)
    return loadThemes(from: themeDirectory)
  }

  func saveUserTheme(_ theme: WuSongTheme) {
    let themeDirectory = SquirrelApp.userDir.appendingPathComponent("themes", isDirectory: true)
    try? FileManager.default.createDirectory(at: themeDirectory, withIntermediateDirectories: true)
    let output = themeYAML(theme)
    let fileURL = themeDirectory.appendingPathComponent("\(theme.id).yaml")
    try? output.write(to: fileURL, atomically: true, encoding: .utf8)
  }
}

private extension ThemeLoader {
  func loadThemes(from directory: URL) -> [WuSongTheme] {
    let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
    return files
      .filter { $0.pathExtension == "yaml" || $0.pathExtension == "yml" }
      .compactMap(parseTheme)
      .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  }

  func parseTheme(url: URL) -> WuSongTheme? {
    guard let contents = try? String(contentsOf: url, encoding: .utf8) else { return nil }
    return parseThemeYAML(contents, id: url.deletingPathExtension().lastPathComponent)
  }

  func parseThemeYAML(_ contents: String, id: String) -> WuSongTheme? {
    var name = id
    var author = ""
    var colorScheme: [String: String] = [:]
    var style: [String: String] = [:]
    var section = ""

    for rawLine in contents.components(separatedBy: .newlines) {
      let withoutComment = rawLine.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? ""
      let line = withoutComment.trimmingCharacters(in: .whitespaces)
      if line.isEmpty { continue }
      if !rawLine.hasPrefix(" ") && !rawLine.hasPrefix("\t") {
        section = ""
        if line == "color_scheme:" || line == "style:" {
          section = String(line.dropLast())
          continue
        }
      }
      guard let colon = line.firstIndex(of: ":") else { continue }
      let key = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
      let value = cleanValue(String(line[line.index(after: colon)...]))
      switch section {
      case "color_scheme": colorScheme[key] = value
      case "style": style[key] = value
      default:
        if key == "name" { name = value }
        else if key == "author" { author = value }
      }
    }
    if colorScheme.isEmpty && style.isEmpty { return nil }
    return WuSongTheme(id: id, name: name, author: author, colorScheme: colorScheme, style: style)
  }

  func cleanValue(_ raw: String) -> String {
    let value = raw.trimmingCharacters(in: .whitespaces)
    if value.count >= 2,
       let first = value.first, let last = value.last,
       (first == "\"" && last == "\"") || (first == "'" && last == "'") {
      return String(value.dropFirst().dropLast())
    }
    return value
  }

  func themeYAML(_ theme: WuSongTheme) -> String {
    var lines: [String] = ["name: \(theme.name)"]
    if !theme.author.isEmpty { lines.append("author: \(theme.author)") }
    lines.append("color_scheme:")
    for key in theme.colorScheme.keys.sorted() {
      lines.append("  \(key): \(theme.colorScheme[key] ?? "")")
    }
    lines.append("style:")
    for key in theme.style.keys.sorted() {
      lines.append("  \(key): \(theme.style[key] ?? "")")
    }
    return lines.joined(separator: "\n") + "\n"
  }

  static let fallbackThemes = [
    WuSongTheme(id: "macos_light",
                name: "macOS Light",
                author: "WuSong",
                colorScheme: [
                  "back_color": "0xFFFFFF",
                  "candidate_text_color": "0x1D1D1F",
                  "hilited_candidate_back_color": "0x007AFF",
                  "hilited_candidate_text_color": "0xFFFFFF"
                ],
                style: [
                  "candidate_list_layout": "linear",
                  "text_orientation": "horizontal",
                  "font_point": "16",
                  "label_font_point": "12"
                ])
  ]
}
