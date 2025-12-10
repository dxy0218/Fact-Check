import Foundation

@MainActor
final class FactCheckViewModel: ObservableObject {
    @Published var claim: String = ""
    @Published var context: String = ""
    @Published var sourceURL: String = ""
    @Published var content: String = ""
    @Published private(set) var results: [FactCheckResult] = []

    private let checker = FactChecker()

    func performCheck() {
        let request = FactCheckRequest(claim: claim, context: context, sourceURL: sourceURL, content: content)
        let result = checker.evaluate(request)
        results.insert(result, at: 0)
    }
}
