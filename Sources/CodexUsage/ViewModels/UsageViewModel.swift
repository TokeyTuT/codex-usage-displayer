import AppKit
import Combine
import Foundation
import ServiceManagement
import SwiftUI

@MainActor
final class UsageViewModel: ObservableObject {
  enum ConnectionState: Equatable {
    case connecting
    case connected
    case failed(String)
  }

  @Published private(set) var snapshot = RateLimitSnapshot.empty
  @Published private(set) var connectionState: ConnectionState = .connecting
  @Published private(set) var isRefreshing = false
  @Published var launchAtLogin = SMAppService.mainApp.status == .enabled
  @Published var showsMenuBarPercentage: Bool {
    didSet {
      UserDefaults.standard.set(
        showsMenuBarPercentage,
        forKey: Self.showsMenuBarPercentageKey
      )
    }
  }

  private static let showsMenuBarPercentageKey = "showsMenuBarPercentage"
  private let client: CodexRateLimitClient
  private var refreshTimer: Timer?
  private var refreshEndTask: Task<Void, Never>?

  init(client: CodexRateLimitClient = CodexRateLimitClient()) {
    let defaults = UserDefaults.standard
    showsMenuBarPercentage =
      defaults.object(forKey: Self.showsMenuBarPercentageKey) == nil
      ? true
      : defaults.bool(forKey: Self.showsMenuBarPercentageKey)
    self.client = client

    client.onSnapshot = { [weak self] snapshot in
      Task { @MainActor in
        guard let self else { return }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
          self.snapshot = snapshot
          self.connectionState = .connected
          self.isRefreshing = false
        }
      }
    }

    client.onError = { [weak self] error in
      Task { @MainActor in
        guard let self else { return }
        self.connectionState = .failed(error.localizedDescription)
        self.isRefreshing = false
      }
    }
  }

  var menuBarRemainingPercent: Int? {
    snapshot.preferredMenuBarWindow?.window.remainingPercent
  }

  var menuBarAccessibilityLabel: String {
    guard let preferred = snapshot.preferredMenuBarWindow else {
      return "正在读取 Codex 剩余用量"
    }
    let title = preferred.kind == .fiveHour ? "五小时" : "每周"
    return "Codex \(title)剩余用量 \(preferred.window.remainingPercent) 百分比"
  }

  var planLabel: String {
    guard let plan = snapshot.planName else { return "CODEX" }
    return
      plan
      .replacingOccurrences(of: "self_serve_", with: "")
      .replacingOccurrences(of: "_usage_based", with: "")
      .replacingOccurrences(of: "_", with: " ")
      .uppercased()
  }

  func start() {
    client.connect()
    refreshTimer?.invalidate()
    refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
      Task { @MainActor in
        self?.client.refresh()
      }
    }
  }

  func refresh() {
    guard !isRefreshing else { return }
    isRefreshing = true
    client.refresh()

    refreshEndTask?.cancel()
    refreshEndTask = Task { [weak self] in
      try? await Task.sleep(for: .seconds(4))
      guard !Task.isCancelled else { return }
      await MainActor.run {
        self?.isRefreshing = false
      }
    }
  }

  func setLaunchAtLogin(_ enabled: Bool) {
    do {
      if enabled {
        try SMAppService.mainApp.register()
      } else {
        try SMAppService.mainApp.unregister()
      }
      launchAtLogin = SMAppService.mainApp.status == .enabled
    } catch {
      launchAtLogin = SMAppService.mainApp.status == .enabled
      connectionState = .failed("无法更新登录启动设置：\(error.localizedDescription)")
    }
  }

  func quit() {
    client.disconnect()
    NSApplication.shared.terminate(nil)
  }
}
