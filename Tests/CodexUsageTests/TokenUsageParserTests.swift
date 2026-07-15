import Foundation
import Testing

@testable import CodexUsage

struct TokenUsageParserTests {
  @Test("解析累计 token 并统计周一至今的 token")
  func parsesLifetimeAndAggregatesCurrentWeek() throws {
    let calendar = testCalendar()
    let now = try #require(date("2026-07-15 13:30:00", calendar: calendar))
    let payload: [String: Any] = [
      "summary": ["lifetimeTokens": 9_999],
      "dailyUsageBuckets": [
        ["startDate": "2026-07-12", "tokens": 800],
        ["startDate": "2026-07-13", "tokens": 100],
        ["startDate": "2026-07-14", "tokens": 200],
        ["startDate": "2026-07-15", "tokens": 300],
      ],
    ]

    let snapshot = try #require(
      TokenUsageParser.snapshot(from: payload, receivedAt: now, calendar: calendar)
    )

    #expect(snapshot.totalTokens == 9_999)
    #expect(snapshot.weekTokens == 600)
  }

  @Test("本周分桶不完整时仍累计已有数据")
  func aggregatesAvailableWeeklyBuckets() throws {
    let calendar = testCalendar()
    let now = try #require(date("2026-07-15 08:00:00", calendar: calendar))
    let payload: [String: Any] = [
      "summary": ["lifetimeTokens": "98877631"],
      "dailyUsageBuckets": [
        ["startDate": "2026-07-13", "tokens": 12_000],
        ["startDate": "2026-07-14", "tokens": "3456"],
      ],
    ]

    let snapshot = try #require(
      TokenUsageParser.snapshot(from: payload, receivedAt: now, calendar: calendar)
    )

    #expect(snapshot.totalTokens == 98_877_631)
    #expect(snapshot.weekTokens == 15_456)
  }

  @Test("账户未返回按日数据时保留加载占位")
  func handlesUnavailableBuckets() throws {
    let payload: [String: Any] = [
      "summary": ["lifetimeTokens": 1],
      "dailyUsageBuckets": NSNull(),
    ]

    let snapshot = try #require(TokenUsageParser.snapshot(from: payload))
    #expect(snapshot.totalTokens == 1)
    #expect(snapshot.weekTokens == nil)
  }

  @Test("大数 token 使用紧凑单位")
  func formatsLargeTokenCounts() {
    #expect(TokenCountFormatter.compact(nil) == "--")
    #expect(TokenCountFormatter.compact(9_999) == "9,999")
    #expect(TokenCountFormatter.compact(98_877_631) == "9887.8万")
    #expect(TokenCountFormatter.compact(1_250_000_000) == "12.5亿")
  }

  private func testCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    return calendar
  }

  private func date(_ value: String, calendar: Calendar) -> Date? {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = calendar.timeZone
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter.date(from: value)
  }
}
