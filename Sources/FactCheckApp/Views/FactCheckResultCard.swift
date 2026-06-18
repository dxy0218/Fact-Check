import SwiftUI

struct FactCheckResultCard: View {
    let result: FactCheckResult

    private var visibleEvidence: ArraySlice<FactCheckEvidence> {
        result.evidence.prefix(6)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader
            strengthBar
            evidenceList

            Divider()

            VStack(alignment: .leading, spacing: 7) {
                Text(result.analysisNote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(result.recommendation)
                    .font(.subheadline)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(result.verdict.tintColor.opacity(0.18))
        )
    }

    private var cardHeader: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: iconName(for: result.verdict))
                .font(.headline.weight(.semibold))
                .foregroundStyle(result.verdict.tintColor)
                .frame(width: 30, height: 30)
                .background(result.verdict.tintColor.opacity(0.12), in: Circle())
                .accessibilityLabel(result.verdict.label)

            VStack(alignment: .leading, spacing: 6) {
                Text(result.headline)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Text(result.verdict.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(result.verdict.tintColor)

                    Text("\(result.sourceCount) 个来源")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(result.archivedAt, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var strengthBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("参考强度")
                Spacer()
                Text("\(Int(result.overallConfidence * 100))%")
                    .monospacedDigit()
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                    Capsule()
                        .fill(result.verdict.tintColor)
                        .frame(width: max(8, proxy.size.width * result.overallConfidence))
                }
            }
            .frame(height: 6)
        }
    }

    private var evidenceList: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("来源线索")
                .font(.subheadline.weight(.semibold))

            if visibleEvidence.isEmpty {
                Text("暂未检索到可展示的公开来源。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(visibleEvidence)) { item in
                    evidenceRow(item)
                }
            }

            if result.evidence.count > visibleEvidence.count {
                Text("另有 \(result.evidence.count - visibleEvidence.count) 条来源已纳入综合判断。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func evidenceRow(_ item: FactCheckEvidence) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(item.sourceName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(item.sourceType)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(item.confidence * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Text(item.summary)
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)

            if let source = item.source {
                Link(destination: source) {
                    Label(source.host ?? source.absoluteString, systemImage: "arrow.up.right")
                        .font(.caption)
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func iconName(for verdict: FactCheckVerdict) -> String {
        switch verdict {
        case .confirmed:
            return "checkmark.seal"
        case .disputed:
            return "questionmark.diamond"
        case .unverifiable:
            return "exclamationmark.triangle"
        }
    }
}

struct FactCheckResultCard_Previews: PreviewProvider {
    static var previews: some View {
        FactCheckResultCard(
            result: FactCheckResult(
                headline: "找到相关公开线索：适量咖啡通常不会导致明显脱水",
                verdict: .confirmed,
                evidence: [
                    FactCheckEvidence(
                        sourceName: "BMJ",
                        sourceType: "原始链接",
                        summary: "来源链接可访问，页面标题：Coffee and hydration research",
                        source: URL(string: "https://www.bmj.com"),
                        verdict: .confirmed,
                        confidence: 0.72
                    )
                ],
                recommendation: "已有多个公开来源可交叉参考。引用前仍建议打开原始链接，确认发布时间、上下文和后续更正。",
                sourceCount: 1,
                overallConfidence: 0.72,
                archivedAt: Date(),
                analysisNote: "已结合补充上下文，本次整理了 1 条百科、新闻索引或原始链接线索。"
            )
        )
        .padding()
    }
}
