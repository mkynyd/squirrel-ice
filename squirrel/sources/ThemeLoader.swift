//
//  ThemeLoader.swift
//  Squirrel
//

import Foundation

struct WuSongTheme: Identifiable, Hashable {
  let id: String
  let name: String
  let author: String
  let colorScheme: [String: String]
  let style: [String: String]
}

final class ThemeLoader {
  static let shared = ThemeLoader()

  func loadBuiltInThemes() -> [WuSongTheme] {
    guard let sharedSupportURL = Bundle.main.sharedSupportURL else {
      return Self.fallbackThemes
    }
    let themeDirectory = sharedSupportURL.appendingPathComponent("themes", isDirectory: true)
    let themes = loadThemes(from: themeDirectory)
    return themes.isEmpty ? Self.fallbackThemes : themes
  }

  func loadUserThemes() -> [WuSongTheme] {
    let themeDirectory = SquirrelApp.userDir.appendingPathComponent("themes", isDirectory: true)
    return loadThemes(from: themeDirectory)
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
    guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
      return nil
    }
    var name = url.deletingPathExtension().lastPathComponent
    var author = ""
    var colorScheme: [String: String] = [:]
    var style: [String: String] = [:]
    var section = ""

    for rawLine in contents.components(separatedBy: .newlines) {
      let withoutComment = rawLine.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? ""
      let line = withoutComment.trimmingCharacters(in: .whitespaces)
      if line.isEmpty {
        continue
      }
      if !rawLine.hasPrefix(" ") && !rawLine.hasPrefix("\t") {
        if line == "color_scheme:" || line == "style:" {
          section = String(line.dropLast())
          continue
        }
        section = ""
      }
      guard let colon = line.firstIndex(of: ":") else {
        continue
      }
      let key = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
      let value = cleanValue(String(line[line.index(after: colon)...]))
      if section == "color_scheme" {
        colorScheme[key] = value
      } else if section == "style" {
        style[key] = value
      } else if key == "name" {
        name = value
      } else if key == "author" {
        author = value
      }
    }

    if colorScheme.isEmpty && style.isEmpty {
      return nil
    }
    return WuSongTheme(id: url.deletingPathExtension().lastPathComponent,
                       name: name,
                       author: author,
                       colorScheme: colorScheme,
                       style: style)
  }

  func cleanValue(_ raw: String) -> String {
    let value = raw.trimmingCharacters(in: .whitespaces)
    if value.count >= 2,
       let first = value.first,
       let last = value.last,
       (first == "\"" && last == "\"") || (first == "'" && last == "'") {
      return String(value.dropFirst().dropLast())
    }
    return value
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
