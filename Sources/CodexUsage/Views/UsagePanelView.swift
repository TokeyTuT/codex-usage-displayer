import SwiftUI

struct UsagePanelView: View {
  @ObservedObject var model: UsageViewModel

  var body: some View {
    ZStack {
      atmosphericBackground

      VStack(spacing: 14) {
        header

        TokenUsageCard(
          snapshot: model.tokenUsage,
          errorMessage: model.tokenUsageError
        )

        UsageGaugeCard(
          eyebrow: "ROLLING WINDOW",
          title: "五小时用量",
          symbol: "timer",
          window: model.snapshot.fiveHour
        )

        UsageGaugeCard(
          eyebrow: "LONG WINDOW",
          title: "每周用量",
          symbol: "calendar",
          window: model.snapshot.weekly
        )

        statusRow
        displaySettings
        footer
      }
      .padding(18)
    }
    .frame(width: 372)
    .fixedSize(horizontal: false, vertical: true)
    .preferredColorScheme(nil)
  }

  private var header: some View {
    HStack(spacing: 12) {
      ZStack {
        RoundedRectangle(cornerRadius: 13, style: .continuous)
          .fill(.primary.opacity(0.07))
        Image(systemName: "waveform.path.ecg")
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(Color.codexMint)
      }
      .frame(width: 42, height: 42)
      .codexGlass(in: RoundedRectangle(cornerRadius: 13, style: .continuous))

      VStack(alignment: .leading, spacing: 2) {
        Text("CODEX PULSE")
          .font(.system(size: 17, weight: .bold, design: .rounded))
          .tracking(0.2)
        Text("用量在菜单栏里，随时可见")
          .font(.system(size: 11, weight: .medium, design: .rounded))
          .foregroundStyle(.secondary)
      }

      Spacer()

      Text(model.planLabel)
        .font(.system(size: 9, weight: .bold, design: .rounded))
        .tracking(0.7)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(.primary.opacity(0.07), in: Capsule())
        .foregroundStyle(.secondary)
    }
  }

  @ViewBuilder
  private var statusRow: some View {
    switch model.connectionState {
    case .connecting:
      statusContent(color: .codexAmber, text: "正在连接 Codex…")
    case .connected:
      statusContent(
        color: .codexMint,
        text: "已同步 · \(model.snapshot.receivedAt.formatted(date: .omitted, time: .shortened))"
      )
    case .failed(let message):
      VStack(alignment: .leading, spacing: 6) {
        statusContent(color: .codexCoral, text: "暂时无法同步")
        Text(message)
          .font(.system(size: 10.5, weight: .medium, design: .rounded))
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private func statusContent(color: Color, text: String) -> some View {
    HStack(spacing: 7) {
      Circle()
        .fill(color)
        .frame(width: 7, height: 7)
        .shadow(color: color.opacity(0.45), radius: 4)
      Text(text)
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .foregroundStyle(.secondary)
      Spacer()
    }
    .padding(.horizontal, 3)
  }

  private var displaySettings: some View {
    HStack(spacing: 14) {
      Toggle("显示数字", isOn: $model.showsMenuBarPercentage)
        .accessibilityHint("控制菜单栏沙漏右侧是否显示剩余百分比")

      Divider()
        .frame(height: 16)

      Toggle(
        "登录时启动",
        isOn: Binding(
          get: { model.launchAtLogin },
          set: { model.setLaunchAtLogin($0) }
        )
      )
    }
    .toggleStyle(.switch)
    .controlSize(.small)
    .font(.system(size: 11, weight: .medium, design: .rounded))
    .padding(.horizontal, 11)
    .padding(.vertical, 9)
    .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
  }

  private var footer: some View {
    HStack(spacing: 8) {
      Button {
        model.refresh()
      } label: {
        Label("刷新", systemImage: "arrow.clockwise")
          .rotationEffect(.degrees(model.isRefreshing ? 360 : 0))
          .animation(
            model.isRefreshing
              ? .linear(duration: 0.8).repeatForever(autoreverses: false)
              : .default,
            value: model.isRefreshing
          )
      }
      .codexGlassButton()
      .disabled(model.isRefreshing)

      Spacer()

      Button("退出") {
        model.quit()
      }
      .buttonStyle(.plain)
      .font(.system(size: 11, weight: .medium, design: .rounded))
      .foregroundStyle(.secondary)
    }
    .padding(.top, 1)
  }

  private var atmosphericBackground: some View {
    ZStack {
      Rectangle()
        .fill(.ultraThinMaterial)

      Circle()
        .fill(Color.codexMint.opacity(0.09))
        .frame(width: 180, height: 180)
        .blur(radius: 48)
        .offset(x: 118, y: -155)

      Circle()
        .fill(Color.codexAmber.opacity(0.055))
        .frame(width: 150, height: 150)
        .blur(radius: 52)
        .offset(x: -145, y: 175)
    }
    .ignoresSafeArea()
  }
}
