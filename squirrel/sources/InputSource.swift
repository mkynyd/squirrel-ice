//
//  InputSource.swift
//  Squirrel
//
//  Created by Leo Liu on 5/10/24.
//

import Foundation
import InputMethodKit

final class SquirrelInstaller {
  enum InputMode: String, CaseIterable {
    static let primary = Self.hans
    case hans = "im.rime.inputmethod.Squirrel.Hans"
    case hant = "im.rime.inputmethod.Squirrel.Hant"
  }

  private func inputSources() -> [String: [TISInputSource]] {
    var inputSources = [String: [TISInputSource]]()
    let sourceList = TISCreateInputSourceList(nil, true).takeRetainedValue() as! [TISInputSource]
    for inputSource in sourceList {
      let sourceIDRef = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID)
      guard let sourceID = unsafeBitCast(sourceIDRef, to: CFString?.self) as String? else { continue }
      // print("[DEBUG] Examining input source: \(sourceID)")
      inputSources[sourceID, default: []].append(inputSource)
    }
    return inputSources
  }

  func enabledModes() -> [InputMode] {
    var enabledModes = Set<InputMode>()
    for (mode, inputSource) in getInputSources(modes: InputMode.allCases) {
      if let enabled = getBool(for: inputSource, key: kTISPropertyInputSourceIsEnabled), enabled {
        enabledModes.insert(mode)
      }
      if enabledModes.count == InputMode.allCases.count {
        break
      }
    }
    return Array(enabledModes)
  }

  func register() {
    let error = TISRegisterInputSource(SquirrelApp.appDir as CFURL)
    print("Register \(error == noErr ? "succeeds" : "fails") for input source from \(SquirrelApp.appDir.path())")

    let enabledInputModes = enabledModes()
    if !enabledInputModes.isEmpty {
      print("User already registered Squirrel method(s): \(enabledInputModes.map { $0.rawValue })")
      // Already registered.
      return
    }
  }

  func enable(modes: [InputMode] = []) {
    let enabledInputModes = enabledModes()
    if !enabledInputModes.isEmpty && modes.isEmpty {
      print("User already enabled Squirrel method(s): \(enabledInputModes.map { $0.rawValue })")
      // keep user's manually enabled input modes.
      return
    }
    let modesToEnable = modes.isEmpty ? [.primary] : modes
    var enabledMode = Set<InputMode>()
    for (mode, inputSource) in getInputSources(modes: modesToEnable) {
      if enabledMode.contains(mode) {
        continue
      }
      if let enabled = getBool(for: inputSource, key: kTISPropertyInputSourceIsEnabled), !enabled {
        let error = TISEnableInputSource(inputSource)
        print("Enable \(error == noErr ? "succeeds" : "fails") for input source: \(mode.rawValue)")
      }
      enabledMode.insert(mode)
    }
  }

  func select(mode: InputMode? = nil) {
    let enabledInputModes = enabledModes()
    let modeToSelect = mode ?? .primary
    if !enabledInputModes.contains(modeToSelect) {
      if mode != nil {
        enable(modes: [modeToSelect])
      } else {
        print("Default method not enabled yet: \(modeToSelect.rawValue)")
        return
      }
    }
    for (mode, inputSource) in getInputSources(modes: [modeToSelect]) {
      if let enabled = getBool(for: inputSource, key: kTISPropertyInputSourceIsEnabled),
         let selectable = getBool(for: inputSource, key: kTISPropertyInputSourceIsSelectCapable),
         let selected = getBool(for: inputSource, key: kTISPropertyInputSourceIsSelected),
         enabled && selectable && !selected {
        let error = TISSelectInputSource(inputSource)
        print("Selection \(error == noErr ? "succeeds" : "fails") for input source: \(mode.rawValue)")
        break
      } else {
        print("Failed to select \(mode.rawValue)")
      }
    }
  }

  func disable(modes: [InputMode] = []) {
    let modesToDisable = modes.isEmpty ? InputMode.allCases : modes
    for (mode, inputSource) in getInputSources(modes: modesToDisable) {
      if let enabled = getBool(for: inputSource, key: kTISPropertyInputSourceIsEnabled), enabled {
        let error = TISDisableInputSource(inputSource)
        print("Disable \(error == noErr ? "succeeds" : "fails") for input source: \(mode.rawValue)")
      }
    }
  }

  private func getInputSources(modes: [InputMode]) -> [(InputMode, TISInputSource)] {
    let sourcesByID = inputSources()
    var matchingSources = [(InputMode, TISInputSource)]()
    for mode in modes {
      if let inputSources = sourcesByID[mode.rawValue] {
        for inputSource in inputSources {
          matchingSources.append((mode, inputSource))
        }
      }
    }
    return matchingSources
  }

  private func getBool(for inputSource: TISInputSource, key: CFString!) -> Bool? {
    let enabledRef = TISGetInputSourceProperty(inputSource, key)
    guard let enabled = unsafeBitCast(enabledRef, to: CFBoolean?.self) else { return nil }
    return CFBooleanGetValue(enabled)
  }
}
