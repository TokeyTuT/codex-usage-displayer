import Foundation
import Testing

@testable import CodexUsage

struct RateLimitParserTests {
  @Test("解析五小时与每周窗口，并把已用量换算为剩余量")
  func parsesBothWindows() throws {
    let payload: [String: Any] = [
      "rateLimits": [
        "planType": "plus",
        "primary": [
          "usedPercent": 27,
          "windowDurationMins": 300,
          "resetsAt": 1_800_000_000,
        ],
        "secondary": [
          "usedPercent": 64,
          "windowDurationMins": 10_080,
          "resetsAt": 1_800_100_000,
        ],
      ]
    ]

    let snapshot = try #require(RateLimitParser.snapshot(from: payload))
    #expect(snapshot.fiveHour?.remainingPercent == 73)
    #expect(snapshot.weekly?.remainingPercent == 36)
    #expect(snapshot.planName == "plus")
  }

  @Test("优先使用 codex 多桶数据")
  func prefersCodexBucket() throws {
    let payload: [String: Any] = [
      "rateLimits": ["primary": ["usedPercent": 99]],
      "rateLimitsByLimitId": [
        "codex": [
          "primary": ["usedPercent": 10, "windowDurationMins": 300],
          "secondary": ["usedPercent": 20, "windowDurationMins": 10_080],
        ]
      ],
    ]

    let snapshot = try #require(RateLimitParser.snapshot(from: payload))
    #expect(snapshot.fiveHour?.remainingPercent == 90)
    #expect(snapshot.weekly?.remainingPercent == 80)
  }

  @Test("滚动通知可直接解析 rate limit snapshot")
  func parsesRollingNotification() throws {
    let payload: [String: Any] = [
      "rateLimits": [
        "primary": ["usedPercent": 5, "windowDurationMins": 300],
        "secondary": ["usedPercent": 15, "windowDurationMins": 10_080],
      ]
    ]

    let snapshot = try #require(RateLimitParser.snapshot(from: payload))
    #expect(snapshot.fiveHour?.remainingPercent == 95)
    #expect(snapshot.weekly?.remainingPercent == 85)
  }

  @Test("只有每周窗口时不伪造五小时数据")
  func doesNotDuplicateWeeklyWindow() throws {
    let payload: [String: Any] = [
      "rateLimits": [
        "planType": "plus",
        "primary": [
          "usedPercent": 6,
          "windowDurationMins": 10_080,
          "resetsAt": 1_800_000_000,
        ],
      ]
    ]

    let snapshot = try #require(RateLimitParser.snapshot(from: payload))
    #expect(snapshot.fiveHour == nil)
    #expect(snapshot.weekly?.remainingPercent == 94)
  }

  @Test("菜单栏优先选择五小时窗口")
  func menuBarPrefersFiveHourWindow() throws {
    let fiveHour = RateLimitWindow(usedPercent: 72, resetsAt: nil, durationMinutes: 300)
    let weekly = RateLimitWindow(usedPercent: 9, resetsAt: nil, durationMinutes: 10_080)
    let snapshot = RateLimitSnapshot(
      fiveHour: fiveHour,
      weekly: weekly,
      planName: "plus",
      receivedAt: .now
    )

    let preferred = try #require(snapshot.preferredMenuBarWindow)
    #expect(preferred.kind == .fiveHour)
    #expect(preferred.window.remainingPercent == 28)
  }

  @Test("没有五小时窗口时菜单栏回退到每周窗口")
  func menuBarFallsBackToWeeklyWindow() throws {
    let weekly = RateLimitWindow(usedPercent: 6, resetsAt: nil, durationMinutes: 10_080)
    let snapshot = RateLimitSnapshot(
      fiveHour: nil,
      weekly: weekly,
      planName: "plus",
      receivedAt: .now
    )

    let preferred = try #require(snapshot.preferredMenuBarWindow)
    #expect(preferred.kind == .weekly)
    #expect(preferred.window.remainingPercent == 94)
  }
}
