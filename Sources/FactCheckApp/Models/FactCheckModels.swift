import Foundation
import SwiftUI

enum FactCheckVerdict: String, CaseIterable, Identifiable, Hashable {
    case confirmed
    case disputed
    case unverifiable

    var id: String { rawValue }

    var label: String {
        switch self {
        case .confirmed:
            return "基本属实"
        case .disputed:
            return "存在疑点"
        case .unverifiable:
            return "无法核实"
        }
    }

    var shortLabel: String {
        switch self {
        case .confirmed:
            return "属实"
        case .disputed:
            return "存疑"
        case .unverifiable:
            return "待核实"
        }
    }

    var tintColor: Color {
        switch self {
        case .confirmed:
            return .green
        case .disputed:
            return .orange
        case .unverifiable:
            return .gray
        }
    }
}

struct FactCheckEvidence: Identifiable, Hashable {
    let id = UUID()
    let sourceName: String
    let sourceType: String
    let summary: String
    let source: URL?
    let verdict: FactCheckVerdict
    let confidence: Double
}

struct FactCheckResult: Identifiable, Hashable {
    let id = UUID()
    let headline: String
    let verdict: FactCheckVerdict
    let evidence: [FactCheckEvidence]
    let recommendation: String
    let sourceCount: Int
    let overallConfidence: Double
    let archivedAt: Date
    let analysisNote: String
}

struct FactCheckRequest: Hashable {
    var claim: String
    var context: String
    var sourceURL: String
    var content: String
}
