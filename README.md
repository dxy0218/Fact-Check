# Fact-Check

[![iOS Build](https://github.com/dxy0218/Fact-Check/actions/workflows/ios-build.yml/badge.svg)](https://github.com/dxy0218/Fact-Check/actions/workflows/ios-build.yml)

一个面向 iOS 16+ 的 SwiftUI 事实核查应用。它可以录入待核查陈述、上下文、来源链接和正文片段，实时检索公开来源，并生成可信度、证据线索、来源列表和后续行动建议。

## 功能

- **实时联网核查**：调用 Wikipedia 搜索、GDELT 新闻索引，并尝试读取用户提供的原始链接。
- **证据线索聚合**：把百科、新闻索引和原始网页标题整理为可点击来源。
- **可信度判断**：根据来源数量、关键词匹配度和争议信号给出“较可信 / 存在疑点 / 证据不足”。
- **历史记录**：最近 50 条核查结果保存到本地 Documents 目录，重新打开应用后仍可查看。
- **iOS 16 兼容**：界面使用 SwiftUI 和 iOS 16 可用组件，避免依赖 iOS 17 API。

## 运行

1. 使用 macOS + Xcode 15 或更新版本打开仓库根目录的 `Package.swift`。
2. 选择 `FactCheck` scheme。
3. 选择 iOS 16+ 模拟器或真机运行。
4. 在主界面输入陈述、正文或来源链接，点击“开始核查”查看结果。

应用不需要 API Key。联网检索依赖设备可访问以下 HTTPS 服务：

- `https://zh.wikipedia.org`
- `https://api.gdeltproject.org`
- 用户输入的来源链接

## 配置

- `.editorconfig` 统一 UTF-8、LF 换行和 Swift/YAML 缩进。
- `.gitattributes` 固定文本文件换行规范，避免跨平台提交产生噪音。
- GitHub Actions 会在 `main` 推送和 PR 上运行 iOS 构建与稳定性测试。
- Dependabot 每周检查 GitHub Actions 版本更新。

## 测试

`FactCheckAppTests` 使用本地 mock 响应覆盖核心核查流程，不依赖公网稳定性。当前包含 400 次循环核查、结果 Codable 往返和空输入错误校验。

## 项目结构

```text
.
├── .github
│   ├── dependabot.yml
│   └── workflows
│       └── ios-build.yml
├── Package.swift
├── Sources/FactCheckApp
│   ├── FactCheckApp.swift
│   ├── Models
│   │   └── FactCheckModels.swift
│   ├── Services
│   │   └── FactChecker.swift
│   ├── ViewModels
│   │   └── FactCheckViewModel.swift
│   └── Views
│       ├── ContentView.swift
│       └── FactCheckResultCard.swift
└── Tests/FactCheckAppTests
    └── FactCheckerStabilityTests.swift
```

## 后续可扩展方向

- 接入更专业的搜索、网页正文提取或事实核查 API。
- 增加来源可信度配置和引用导出。
- 增加分享扩展，从 Safari 或聊天软件直接提交待核查内容。
- 给结果增加更细的证据分类，例如“直接证据 / 背景资料 / 反驳线索”。
