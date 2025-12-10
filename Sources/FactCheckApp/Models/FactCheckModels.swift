import Foundation
import SwiftUI

enum FactCheckVerdict: String, CaseIterable, Identifiable, Codable {
    case confirmed
    case disputed
    case unverifiable

    var id: String { rawValue }

    var label: String {
        switch self {
        case .confirmed:
            return "已证实"
        case .disputed:
            return "存疑"
        case .unverifiable:
            return "无法核实"
        }
    }

    var tintColor: Color {
        switch self {
        case .confirmed:
            return Color.green
        case .disputed:
            return Color.orange
        case .unverifiable:
            return Color.gray
        }
    }
}

struct FactCheckEvidence: Identifiable, Codable, Hashable {
    let id = UUID()
    let summary: String
    let source: URL?
    let verdict: FactCheckVerdict
    let confidence: Double
}

struct FactCheckResult: Identifiable, Codable, Hashable {
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

struct FactCheckRequest: Codable, Hashable {
    var claim: String
    var context: String
    var sourceURL: String
    var content: String
}
