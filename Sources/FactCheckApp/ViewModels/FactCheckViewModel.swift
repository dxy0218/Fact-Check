import Foundation
import Combine

@MainActor
final class FactCheckViewModel: ObservableObject {
    @Published var claim = ""
    @Published var context = ""
    @Published var sourceURL = ""
    @Published var content = ""
    @Published private(set) var results: [FactCheckResult] = []
    @Published private(set) var isChecking = false
    @Published var errorMessage: String?

    private let checker = FactChecker()
    private let historyStore = HistoryStore()

    init() {
        results = historyStore.load()
    }

    var canSubmit: Bool {
        !isChecking && [claim, context, sourceURL, content]
            .contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
    }

    func performCheck() {
        guard canSubmit else { return }

        let request = FactCheckRequest(
            claim: claim,
            context: context,
            sourceURL: sourceURL,
            content: content
        )

        isChecking = true
        errorMessage = nil

        Task {
            do {
                let result = try await checker.evaluate(request)
                results.insert(result, at: 0)
                historyStore.save(Array(results.prefix(50)))
            } catch {
                errorMessage = error.localizedDescription
            }

            isChecking = false
        }
    }

    func fillExample() {
        claim = "喝咖啡会导致脱水吗？"
        context = "朋友群里转发的健康提醒，想确认说法是否可靠。"
        sourceURL = "https://www.bmj.com"
        content = "文章称咖啡因有利尿作用，所以喝咖啡会让身体脱水，建议完全用白水替代。"
    }

    func resetInputs() {
        claim = ""
        context = ""
        sourceURL = ""
        content = ""
        errorMessage = nil
    }

    func clearHistory() {
        results = []
        historyStore.save([])
    }
}

private struct HistoryStore {
    private let fileName = "fact-check-history.json"

    func load() -> [FactCheckResult] {
        guard let data = try? Data(contentsOf: fileURL) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([FactCheckResult].self, from: data)) ?? []
    }

    func save(_ results: [FactCheckResult]) {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(results)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            assertionFailure("Failed to save fact-check history: \(error.localizedDescription)")
        }
    }

    private var fileURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return directory.appendingPathComponent(fileName)
    }
}
