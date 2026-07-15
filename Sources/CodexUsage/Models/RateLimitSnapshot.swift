import Foundation

enum RateLimitWindowKind: Equatable, Sendable {
  case fiveHour
  case weekly
}

struct RateLimitWindow: Equatable, Sendable {
  let usedPercent: Int
  let resetsAt: Date?
  let durationMinutes: Int?

  var remainingPercent: Int {
    max(0, min(100, 100 - usedPercent))
  }
}

struct RateLimitSnapshot: Equatable, Sendable {
  let fiveHour: RateLimitWindow?
  let weekly: RateLimitWindow?
  let planName: String?
  let receivedAt: Date

  static let empty = RateLimitSnapshot(
    fiveHour: nil,
    weekly: nil,
    planName: nil,
    receivedAt: .distantPast
  )

  var preferredMenuBarWindow: (kind: RateLimitWindowKind, window: RateLimitWindow)? {
    if let fiveHour {
      return (.fiveHour, fiveHour)
    }
    if let weekly {
      return (.weekly, weekly)
    }
    return nil
  }
}

enum RateLimitParser {
  static func snapshot(from payload: [String: Any], receivedAt: Date = Date()) -> RateLimitSnapshot?
  {
    let root: [String: Any]

    if let buckets = payload["rateLimitsByLimitId"] as? [String: Any],
      let codex = buckets["codex"] as? [String: Any]
    {
      root = codex
    } else if let limits = payload["rateLimits"] as? [String: Any] {
      root = limits
    } else if payload["primary"] != nil || payload["secondary"] != nil {
      root = payload
    } else {
      return nil
    }

    let primary = parseWindow(root["primary"])
    let secondary = parseWindow(root["secondary"])
    let windows = [primary, secondary].compactMap { $0 }

    let fiveHour =
      windows.first(where: { $0.durationMinutes == 300 })
      ?? primary.flatMap { $0.durationMinutes == nil ? $0 : nil }
    let weekly =
      windows.first(where: { window in
        guard let duration = window.durationMinutes else { return false }
        return duration >= 7 * 24 * 60
      }) ?? secondary.flatMap { $0.durationMinutes == nil ? $0 : nil }

    guard fiveHour != nil || weekly != nil else { return nil }

    return RateLimitSnapshot(
      fiveHour: fiveHour,
      weekly: weekly,
      planName: root["planType"] as? String,
      receivedAt: receivedAt
    )
  }

  private static func parseWindow(_ value: Any?) -> RateLimitWindow? {
    guard let object = value as? [String: Any],
      let used = int(from: object["usedPercent"])
    else {
      return nil
    }

    let resetTimestamp = int(from: object["resetsAt"])
    return RateLimitWindow(
      usedPercent: used,
      resetsAt: resetTimestamp.map { Date(timeIntervalSince1970: TimeInterval($0)) },
      durationMinutes: int(from: object["windowDurationMins"])
    )
  }

  private static func int(from value: Any?) -> Int? {
    switch value {
    case let number as NSNumber:
      return number.intValue
    case let string as String:
      return Int(string)
    default:
      return nil
    }
  }
}
