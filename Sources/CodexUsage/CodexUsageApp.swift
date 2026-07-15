import SwiftUI

@main
struct CodexUsageApp: App {
  @StateObject private var model = UsageViewModel()

  var body: some Scene {
    MenuBarExtra {
      UsagePanelView(model: model)
    } label: {
      MenuBarUsageIcon(
        remainingPercent: model.menuBarRemainingPercent,
        showsPercentage: model.showsMenuBarPercentage
      )
      .accessibilityLabel(model.menuBarAccessibilityLabel)
      .help(model.menuBarAccessibilityLabel)
      .task {
        model.start()
      }
    }
    .menuBarExtraStyle(.window)
  }
}
