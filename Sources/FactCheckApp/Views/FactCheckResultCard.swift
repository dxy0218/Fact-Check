import SwiftUI

struct FactCheckResultCard: View {
    let result: FactCheckResult

    private var visibleEvidence: ArraySlice<FactCheckEvidence> {
        result.evidence.prefix(8)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardHeader
            confidenceBar
            evidenceList

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(result.analysisNote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(result.recommendation)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(result.verdict.tintColor.opacity(0.18))
        )
    }

    private var cardHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName(for: result.verdict))
                .font(.title3.weight(.bold))
                .foregroundStyle(result.verdict.tintColor)
                .frame(width: 34, height: 34)
                .background(result.verdict.tintColor.opacity(0.12), in: Circle())
                .accessibilityLabel(result.verdict.label)

            VStack(alignment: .leading, spacing: 6) {
                Text(result.headline)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Text(result.verdict.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(result.verdict.tintColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(result.verdict.tintColor.opacity(0.12), in: Capsule())

                    Text("来源 \(result.sourceCount) 条")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(result.archivedAt, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var confidenceBar: some View {
        ProgressView(value: result.overallConfidence) {
            HStack {
                Text("综合可信度")
                Spacer()
                Text("\(Int(result.overallConfidence * 100))%")
            }
            .font(.caption.weight(.medium))
        }
        .tint(result.verdict.tintColor)
        .progressViewStyle(.linear)
    }

    private var evidenceList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("证据线索")
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
                Text("另有 \(result.evidence.count - visibleEvidence.count) 条来源已纳入综合评分。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func evidenceRow(_ item: FactCheckEvidence) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(item.sourceName)
                    .font(.subheadline.weight(.semibold))
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
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if let source = item.source {
                Link(source.host ?? source.absoluteString, destination: source)
                    .font(.caption)
            }
        }
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func iconName(for verdict: FactCheckVerdict) -> String {
        switch verdict {
        case .confirmed:
            return "checkmark.seal.fill"
        case .disputed:
            return "questionmark.diamond.fill"
        case .unverifiable:
            return "exclamationmark.triangle.fill"
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
                        summary: "用户提供的链接可访问，页面标题：Coffee and hydration research",
                        source: URL(string: "https://www.bmj.com"),
                        verdict: .confirmed,
                        confidence: 0.72
                    )
                ],
                recommendation: "多个公开来源存在相关线索。转发或引用前，建议点开原始链接确认发布日期、上下文和是否存在后续更正。",
                sourceCount: 1,
                overallConfidence: 0.72,
                archivedAt: Date(),
                analysisNote: "已结合补充上下文，本次实时查询整合 1 条百科、新闻索引或原始链接线索。"
            )
        )
        .padding()
    }
}
