import Foundation
import SwiftUI

enum FactCheckVerdict: String, CaseIterable, Identifiable, Codable, Hashable {
    case confirmed
    case disputed
    case unverifiable

    var id: String { rawValue }

    var label: String {
        switch self {
        case .confirmed:
            return "较可信"
        case .disputed:
            return "存在疑点"
        case .unverifiable:
            return "证据不足"
        }
    }

    var shortLabel: String {
        switch self {
        case .confirmed:
            return "可信"
        case .disputed:
            return "存疑"
        case .unverifiable:
            return "待补证"
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

struct FactCheckEvidence: Identifiable, Codable, Hashable {
    var id = UUID()
    var sourceName: String
    var sourceType: String
    var summary: String
    var source: URL?
    var verdict: FactCheckVerdict
    var confidence: Double
}

struct FactCheckResult: Identifiable, Codable, Hashable {
    var id = UUID()
    var headline: String
    var verdict: FactCheckVerdict
    var evidence: [FactCheckEvidence]
    var recommendation: String
    var sourceCount: Int
    var overallConfidence: Double
    var archivedAt: Date
    var analysisNote: String
}

struct FactCheckRequest: Codable, Hashable {
    var claim: String
    var context: String
    var sourceURL: String
    var content: String
}
