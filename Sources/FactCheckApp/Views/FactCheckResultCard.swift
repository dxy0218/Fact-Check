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

                    Text("信源 \(result.sourceCount) 条")
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
            Text("证据摘要")
                .font(.subheadline.weight(.semibold))

            ForEach(Array(visibleEvidence)) { item in
                evidenceRow(item)
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
                headline: "月球表面与永久阴影区存在水冰证据",
                verdict: .confirmed,
                evidence: [
                    FactCheckEvidence(
                        sourceName: "NASA",
                        sourceType: "航天机构",
                        summary: "红外观测和撞击实验均支持月球部分区域存在水相关信号。",
                        source: URL(string: "https://www.nasa.gov"),
                        verdict: .confirmed,
                        confidence: 0.92
                    )
                ],
                recommendation: "可以引用 NASA、CNSA 等航天机构的公开资料，但应区分水冰、水分子和可开采水资源。",
                sourceCount: 22,
                overallConfidence: 0.84,
                archivedAt: Date(),
                analysisNote: "整合 22 条公开信源，按交叉一致性给出结果。"
            )
        )
        .padding()
    }
}
