import SwiftUI

struct FactCheckResultCard: View {
    let result: FactCheckResult

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(result.headline)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Label(result.verdict.label, systemImage: iconName(for: result.verdict))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(tintColor)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text("信源 \(result.sourceCount) 条")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(result.archivedAt, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    verdictIcon
                }
            }

            ProgressView(value: result.overallConfidence) {
                Text("综合可信度 \(Int(result.overallConfidence * 100))%")
                    .font(.caption.weight(.medium))
            }
            .tint(tintColor)
            .progressViewStyle(.linear)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(result.evidence) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(tintColor.opacity(0.2))
                                .frame(width: 12, height: 12)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                if let source = item.source {
                                    Text(source.absoluteString)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                        ProgressView(value: item.confidence) {
                            Text("可信度")
                                .font(.caption)
                        }
                        .tint(tintColor)
                        .progressViewStyle(.linear)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            Divider()
            Text(result.analysisNote)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(result.recommendation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(tintColor.opacity(0.15))
        )
    }

    private var tintColor: Color {
        result.verdict.tintColor
    }

    private var verdictIcon: some View {
        Image(systemName: iconName(for: result.verdict))
            .foregroundStyle(tintColor)
            .font(.title3.weight(.bold))
            .accessibilityLabel(result.verdict.label)
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
                headline: "月球地表存在水冰",
                verdict: .confirmed,
                evidence: [
                    FactCheckEvidence(
                        summary: "NASA 使用红外光谱在月球南极发现水冰信号。",
                        source: URL(string: "https://www.nasa.gov"),
                        verdict: .confirmed,
                        confidence: 0.92
                    )
                ],
                recommendation: "来源可靠，可放心引用相关报道。",
                sourceCount: 22,
                overallConfidence: 0.84,
                archivedAt: Date(),
                analysisNote: "整合 22 条公开信源，按交叉一致性给出结论。"
            )
        )
        .padding()
    }
}
