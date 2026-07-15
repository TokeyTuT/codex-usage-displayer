import SwiftUI

struct UsageGaugeCard: View {
  let eyebrow: String
  let title: String
  let symbol: String
  let window: RateLimitWindow?

  private var remaining: Int { window?.remainingPercent ?? 0 }

  private var accent: Color {
    switch remaining {
    case 50...: return .codexMint
    case 20...: return .codexAmber
    default: return .codexCoral
    }
  }

  var body: some View {
    HStack(spacing: 16) {
      gauge

      VStack(alignment: .leading, spacing: 7) {
        HStack(spacing: 6) {
          Image(systemName: symbol)
            .font(.system(size: 10, weight: .semibold))
          Text(eyebrow)
        }
        .font(.system(size: 10, weight: .semibold, design: .rounded))
        .tracking(0.8)
        .foregroundStyle(.secondary)

        Text(title)
          .font(.system(size: 16, weight: .semibold, design: .rounded))

        if let reset = window?.resetsAt {
          Text("重置于 \(reset.formatted(date: .abbreviated, time: .shortened))")
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
        } else {
          Text("当前账户未返回此窗口")
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(.tertiary)
        }
      }

      Spacer(minLength: 0)
    }
    .padding(15)
    .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
    .codexGlass(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
  }

  private var gauge: some View {
    ZStack {
      Circle()
        .stroke(.primary.opacity(0.075), lineWidth: 7)

      Circle()
        .trim(from: 0, to: CGFloat(remaining) / 100)
        .stroke(
          AngularGradient(
            colors: [accent.opacity(0.55), accent],
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
          ),
          style: StrokeStyle(lineWidth: 7, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
        .animation(.spring(response: 0.65, dampingFraction: 0.82), value: remaining)

      VStack(spacing: -1) {
        Text(window == nil ? "--" : "\(remaining)")
          .font(.system(size: 22, weight: .bold, design: .rounded))
          .contentTransition(.numericText())
        Text("%")
          .font(.system(size: 9, weight: .bold, design: .rounded))
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: 70, height: 70)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(title)剩余 \(remaining) 百分比")
  }
}
