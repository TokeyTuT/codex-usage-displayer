import SwiftUI

struct TokenUsageCard: View {
  let snapshot: TokenUsageSnapshot
  let errorMessage: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 7) {
        Image(systemName: "number")
          .font(.system(size: 10, weight: .bold))
        Text("TOKEN ACTIVITY")
          .tracking(0.8)

        Spacer()

        Text("每 30 秒更新")
          .foregroundStyle(.tertiary)
      }
      .font(.system(size: 10, weight: .semibold, design: .rounded))
      .foregroundStyle(.secondary)
      .help("数据由 Codex 账户统计提供，服务端可能有短暂同步延迟")

      HStack(spacing: 14) {
        metric(
          title: "累计消耗",
          caption: "全部记录",
          value: snapshot.totalTokens,
          accent: .codexMint
        )

        Divider()
          .frame(height: 48)

        metric(
          title: "本周消耗",
          caption: "周一至今",
          value: snapshot.weekTokens,
          accent: .codexAmber
        )
      }

      if let errorMessage {
        Label(errorMessage, systemImage: "exclamationmark.circle")
          .font(.system(size: 10, weight: .medium, design: .rounded))
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }
    }
    .padding(15)
    .frame(maxWidth: .infinity, alignment: .leading)
    .codexGlass(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
  }

  private func metric(
    title: String,
    caption: String,
    value: Int64?,
    accent: Color
  ) -> some View {
    HStack(alignment: .top, spacing: 9) {
      Capsule()
        .fill(accent)
        .frame(width: 3, height: 38)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.system(size: 11, weight: .semibold, design: .rounded))
          .foregroundStyle(.secondary)

        Text(TokenCountFormatter.compact(value))
          .font(.system(size: 18, weight: .bold, design: .rounded))
          .monospacedDigit()
          .lineLimit(1)
          .minimumScaleFactor(0.72)
          .contentTransition(.numericText())

        Text(caption)
          .font(.system(size: 9.5, weight: .medium, design: .rounded))
          .foregroundStyle(.tertiary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(title) \(TokenCountFormatter.compact(value)) token")
    .help(value.map { "\($0.formatted()) tokens" } ?? "正在读取 Codex token 统计")
  }
}
