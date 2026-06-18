import Foundation
import Combine

@MainActor
final class FactCheckViewModel: ObservableObject {
    @Published var claim = ""
    @Published var context = ""
    @Published var sourceURL = ""
    @Published var content = ""
    @Published private(set) var results: [FactCheckResult] = []

    private let checker = FactChecker()

    var canSubmit: Bool {
        [claim, context, sourceURL, content]
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
        let result = checker.evaluate(request)
        results.insert(result, at: 0)
    }

    func fillExample() {
        claim = "网传喝咖啡会导致脱水"
        context = "朋友群里转发的健康提醒，想确认是否可靠。"
        sourceURL = "https://www.bmj.com"
        content = "文章称咖啡因有利尿作用，所以喝咖啡会让身体脱水，建议完全用白水代替。"
    }

    func resetInputs() {
        claim = ""
        context = ""
        sourceURL = ""
        content = ""
    }
}
