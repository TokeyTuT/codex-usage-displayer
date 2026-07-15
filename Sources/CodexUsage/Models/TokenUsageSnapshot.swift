import Foundation

struct TokenUsageSnapshot: Equatable, Sendable {
  let totalTokens: Int64?
  let weekTokens: Int64?
  let receivedAt: Date

  static let empty = TokenUsageSnapshot(
    totalTokens: nil,
    weekTokens: nil,
    receivedAt: .distantPast
  )
}

enum TokenUsageParser {
  static func snapshot(
    from payload: [String: Any],
    receivedAt: Date = Date(),
    calendar: Calendar = .current
  ) -> TokenUsageSnapshot? {
    guard payload["summary"] != nil || payload.keys.contains("dailyUsageBuckets") else {
      return nil
    }

    let summary = payload["summary"] as? [String: Any]
    let totalTokens = int64(from: summary?["lifetimeTokens"]).map { max(0, $0) }

    guard let rawBuckets = payload["dailyUsageBuckets"], !(rawBuckets is NSNull) else {
      return TokenUsageSnapshot(
        totalTokens: totalTokens,
        weekTokens: nil,
        receivedAt: receivedAt
      )
    }

    guard let buckets = rawBuckets as? [[String: Any]] else { return nil }

    let today = calendar.startOfDay(for: receivedAt)
    let weekday = calendar.component(.weekday, from: today)
    let daysSinceMonday = (weekday + 5) % 7
    guard let weekStart = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today) else {
      return nil
    }

    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = calendar.timeZone
    formatter.dateFormat = "yyyy-MM-dd"

    var weekTokens: Int64 = 0

    for bucket in buckets {
      guard let startDate = bucket["startDate"] as? String,
        let date = formatter.date(from: startDate),
        let tokens = int64(from: bucket["tokens"])
      else {
        continue
      }

      let bucketDay = calendar.startOfDay(for: date)
      let safeTokens = max(0, tokens)
      if bucketDay >= weekStart, bucketDay <= today {
        weekTokens += safeTokens
      }
    }

    return TokenUsageSnapshot(
      totalTokens: totalTokens,
      weekTokens: weekTokens,
      receivedAt: receivedAt
    )
  }

  private static func int64(from value: Any?) -> Int64? {
    switch value {
    case let number as NSNumber:
      return number.int64Value
    case let string as String:
      return Int64(string)
    default:
      return nil
    }
  }
}

enum TokenCountFormatter {
  static func compact(_ value: Int64?) -> String {
    guard let value else { return "--" }
    let safeValue = max(0, value)

    if safeValue >= 100_000_000 {
      return scaled(safeValue, divisor: 100_000_000, suffix: "亿")
    }
    if safeValue >= 10_000 {
      return scaled(safeValue, divisor: 10_000, suffix: "万")
    }

    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: safeValue)) ?? "\(safeValue)"
  }

  private static func scaled(_ value: Int64, divisor: Double, suffix: String) -> String {
    let rounded = (Double(value) / divisor * 10).rounded() / 10
    let number =
      rounded == rounded.rounded()
      ? String(format: "%.0f", locale: Locale(identifier: "en_US_POSIX"), rounded)
      : String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), rounded)
    return number + suffix
  }
}
