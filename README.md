# Fact-Check

一个面向 iOS 16+ 的 SwiftUI 事实核查应用示例。它可以录入待核查陈述、上下文、来源链接和正文片段，并生成可信度、证据摘要、来源列表和后续行动建议。

> 说明：当前版本是本地演示应用，使用内置知识库和 20+ 信源模板模拟交叉核查流程，不会真正联网抓取新闻或网页。

## 功能

- **快速输入**：支持陈述、正文片段、补充上下文和来源链接。
- **20+ 信源交叉比对**：模拟官方媒体、国际媒体、社交平台、专家渠道和公开数据库的综合判断。
- **结果卡片**：展示「基本属实 / 存在疑点 / 无法核实」、综合可信度、证据摘要和可点击来源链接。
- **历史记录**：每次核查结果会插入顶部，便于比较最近多条结论。
- **示例填充**：内置示例内容，方便首次运行时快速体验。

## 运行

1. 使用 macOS + Xcode 15 或更新版本打开仓库根目录的 `Package.swift`。
2. 选择 `FactCheckApp` 可执行目标。
3. 选择 iOS 16+ 模拟器或真机运行。
4. 在主界面输入陈述、正文或来源链接，点击「立即核查」查看结果。

## 项目结构

```text
Sources/FactCheckApp
├── FactCheckApp.swift
├── Models
│   └── FactCheckModels.swift
├── Services
│   └── FactChecker.swift
├── ViewModels
│   └── FactCheckViewModel.swift
└── Views
    ├── ContentView.swift
    └── FactCheckResultCard.swift
```

## 后续可扩展方向

- 接入真实网页抓取和搜索 API。
- 增加来源可信度配置和引用导出。
- 用本地持久化保存历史记录。
- 增加分享扩展，从 Safari 或聊天软件直接提交待核查内容。
