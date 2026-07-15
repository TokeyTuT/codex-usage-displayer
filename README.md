# Codex Pulse

一个原生 macOS 菜单栏应用，实时显示 Codex 的五小时与每周剩余用量。

## 功能

- 菜单栏组合透明背景的黑白 `>_`、动态沙漏和右侧百分比：上仓表示剩余量，下仓表示已消耗量
- 点开面板可关闭或恢复百分比数字；选择会自动保存，关闭后菜单栏图标同步收窄
- 优先显示五小时剩余量；没有五小时窗口时自动显示每周剩余量
- 每 30 秒自动刷新，也可以手动刷新
- 显示每个额度窗口的重置时间
- 直接复用本机 Codex / ChatGPT 登录态，不读取或保存 API Key
- macOS 26 使用原生 Liquid Glass；macOS 14–15 自动回退到系统材质
- 可选“登录时启动”

## 环境要求

- macOS 14 或更高版本
- 已安装并登录 Codex（Codex CLI 或 ChatGPT macOS App）
- Xcode 16 或更高版本；Liquid Glass 的编译和完整效果需要 Xcode 26

## 构建与运行

开发时直接运行：

```bash
swift run CodexUsage
```

运行测试：

```bash
swift test
```

生成可双击运行的 `.app`：

```bash
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open "dist/Codex Pulse.app"
```

如需安装到“应用程序”：

```bash
cp -R "dist/Codex Pulse.app" /Applications/
```

如果 Codex 位于自定义路径，启动前设置 `CODEX_PATH`：

```bash
CODEX_PATH=/path/to/codex swift run CodexUsage
```

## 数据来源

应用启动本机 `codex app-server`，完成 JSON-RPC 初始化后读取
`account/rateLimits/read`。它优先使用 `codex` 对应的额度桶，并按窗口时长识别
五小时（300 分钟）与每周（10080 分钟）用量。

Codex 会根据账号与当前额度策略决定返回哪些窗口。应用不会用一个窗口伪造另一个窗口；
若当前账号暂未返回某个窗口，会在对应位置明确标记，后续刷新拿到该窗口后自动显示。
