import Foundation

final class CodexRateLimitClient: @unchecked Sendable {
  enum ClientError: LocalizedError {
    case executableNotFound
    case failedToLaunch(String)
    case server(String)
    case disconnected

    var errorDescription: String? {
      switch self {
      case .executableNotFound:
        return "没有找到 Codex。请先安装并登录 Codex，或设置 CODEX_PATH。"
      case .failedToLaunch(let message):
        return "无法启动 Codex 服务：\(message)"
      case .server(let message):
        return "Codex 返回错误：\(message)"
      case .disconnected:
        return "Codex 服务已断开，稍后会自动重连。"
      }
    }
  }

  var onSnapshot: (@Sendable (RateLimitSnapshot) -> Void)?
  var onError: (@Sendable (Error) -> Void)?

  private let queue = DispatchQueue(label: "com.codexusage.app-server")
  private var process: Process?
  private var input: FileHandle?
  private var outputBuffer = Data()
  private var initialized = false
  private var requestID = 2
  private var stderrTail = ""

  func connect() {
    queue.async { [weak self] in
      self?.startIfNeeded()
    }
  }

  func refresh() {
    queue.async { [weak self] in
      guard let self else { return }
      if self.process?.isRunning != true {
        self.startIfNeeded()
        return
      }
      guard self.initialized else { return }
      self.sendRateLimitRequest()
    }
  }

  func disconnect() {
    queue.sync { [weak self] in
      guard let self else { return }
      self.process?.terminationHandler = nil
      if self.process?.isRunning == true {
        self.process?.terminate()
      }
      self.clearProcess()
    }
  }

  private func startIfNeeded() {
    guard process?.isRunning != true else { return }
    guard let executableURL = Self.findCodexExecutable() else {
      onError?(ClientError.executableNotFound)
      return
    }

    clearProcess()

    let process = Process()
    let stdout = Pipe()
    let stdin = Pipe()
    let stderr = Pipe()

    process.executableURL = executableURL
    process.arguments = ["app-server", "--stdio"]
    process.standardOutput = stdout
    process.standardInput = stdin
    process.standardError = stderr

    stdout.fileHandleForReading.readabilityHandler = { [weak self] handle in
      let data = handle.availableData
      guard !data.isEmpty else { return }
      self?.queue.async { [weak self] in
        self?.consume(data)
      }
    }

    stderr.fileHandleForReading.readabilityHandler = { [weak self] handle in
      let data = handle.availableData
      guard !data.isEmpty else { return }
      self?.queue.async { [weak self] in
        guard let self, let text = String(data: data, encoding: .utf8) else { return }
        self.stderrTail = String((self.stderrTail + text).suffix(800))
      }
    }

    process.terminationHandler = { [weak self] _ in
      self?.queue.async { [weak self] in
        guard let self else { return }
        let wasConnected = self.initialized
        self.clearProcess()
        if wasConnected {
          self.onError?(ClientError.disconnected)
        }
      }
    }

    do {
      try process.run()
      self.process = process
      self.input = stdin.fileHandleForWriting
      send([
        "method": "initialize",
        "id": 1,
        "params": [
          "clientInfo": [
            "name": "codex_usage_menubar",
            "title": "Codex Usage",
            "version": "1.0.0",
          ]
        ],
      ])
    } catch {
      clearProcess()
      onError?(ClientError.failedToLaunch(error.localizedDescription))
    }
  }

  private func consume(_ data: Data) {
    outputBuffer.append(data)

    while let newlineIndex = outputBuffer.firstIndex(of: 0x0A) {
      let line = outputBuffer[..<newlineIndex]
      outputBuffer.removeSubrange(...newlineIndex)
      guard !line.isEmpty else { continue }

      do {
        let value = try JSONSerialization.jsonObject(with: Data(line))
        guard let message = value as? [String: Any] else { continue }
        handle(message)
      } catch {
        // app-server 输出按 JSONL 分隔。单条解析失败不应中断后续更新。
      }
    }
  }

  private func handle(_ message: [String: Any]) {
    if let errorObject = message["error"] as? [String: Any] {
      let detail = errorObject["message"] as? String ?? "未知错误"
      onError?(ClientError.server(detail))
      return
    }

    if (message["id"] as? NSNumber)?.intValue == 1 {
      initialized = true
      send(["method": "initialized", "params": [:]])
      sendRateLimitRequest()
      return
    }

    if let result = message["result"] as? [String: Any],
      let snapshot = RateLimitParser.snapshot(from: result)
    {
      onSnapshot?(snapshot)
      return
    }

    if message["method"] as? String == "account/rateLimits/updated",
      let params = message["params"] as? [String: Any],
      let snapshot = RateLimitParser.snapshot(from: params)
    {
      onSnapshot?(snapshot)
    }
  }

  private func sendRateLimitRequest() {
    requestID += 1
    send([
      "method": "account/rateLimits/read",
      "id": requestID,
      "params": NSNull(),
    ])
  }

  private func send(_ message: [String: Any]) {
    guard JSONSerialization.isValidJSONObject(message),
      var data = try? JSONSerialization.data(withJSONObject: message)
    else { return }
    data.append(0x0A)

    do {
      try input?.write(contentsOf: data)
    } catch {
      onError?(ClientError.server(error.localizedDescription))
    }
  }

  private func clearProcess() {
    if let stdout = process?.standardOutput as? Pipe {
      stdout.fileHandleForReading.readabilityHandler = nil
    }
    if let stderr = process?.standardError as? Pipe {
      stderr.fileHandleForReading.readabilityHandler = nil
    }
    try? input?.close()
    process = nil
    input = nil
    initialized = false
    outputBuffer.removeAll(keepingCapacity: true)
  }

  private static func findCodexExecutable() -> URL? {
    let environment = ProcessInfo.processInfo.environment
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    let candidates = [
      environment["CODEX_PATH"],
      "/Applications/ChatGPT.app/Contents/Resources/codex",
      "/Applications/Codex.app/Contents/Resources/codex",
      "/opt/homebrew/bin/codex",
      "/usr/local/bin/codex",
      "\(home)/.local/bin/codex",
      "\(home)/.npm-global/bin/codex",
    ].compactMap { $0 }

    return
      candidates
      .map(URL.init(fileURLWithPath:))
      .first(where: { FileManager.default.isExecutableFile(atPath: $0.path) })
  }
}
