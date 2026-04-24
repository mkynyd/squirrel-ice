//
//  WuSongSettingsWindowController.swift
//  Squirrel
//

import AppKit
import SwiftUI

final class WuSongSettingsWindowController {
  static let shared = WuSongSettingsWindowController()

  private var window: NSWindow?

  func show() {
    let contentView = WuSongSettingsView(manager: .shared)
    if window == nil {
      let hostingController = NSHostingController(rootView: contentView)
      let settingsWindow = NSWindow(contentViewController: hostingController)
      settingsWindow.title = "雾凇输入法设置"
      settingsWindow.setContentSize(NSSize(width: 760, height: 520))
      settingsWindow.styleMask = [.titled, .closable, .miniaturizable, .resizable]
      settingsWindow.isReleasedWhenClosed = false
      settingsWindow.center()
      window = settingsWindow
    } else if let hostingController = window?.contentViewController as? NSHostingController<WuSongSettingsView> {
      hostingController.rootView = contentView
    }

    NSApp.setActivationPolicy(.regular)
    window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
}
