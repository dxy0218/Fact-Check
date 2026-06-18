import Foundation
@testable import FactCheckApp
import XCTest

final class FactCheckerLiveNetworkTests: XCTestCase {
    func testLiveSearchWorksAcrossFiftyRuns() async throws {
        guard ProcessInfo.processInfo.environment["RUN_LIVE_NETWORK_TESTS"] == "1" else {
            throw XCTSkip("Set RUN_LIVE_NETWORK_TESTS=1 to run live network search tests.")
        }

        let runCount = Int(ProcessInfo.processInfo.environment["LIVE_SEARCH_RUNS"] ?? "") ?? 50
        XCTAssertGreaterThanOrEqual(runCount, 50)

        let checker = FactChecker()
        let subjects = [
            "NASA Artemis",
            "World Health Organization",
            "coffee dehydration",
            "COVID-19 vaccine",
            "climate change",
            "United Nations",
            "iPhone",
            "Olympic Games",
            "electric vehicle",
            "James Webb Space Telescope"
        ]

        var failures: [String] = []

        for index in 0..<runCount {
            let subject = subjects[index % subjects.count]
            let request = FactCheckRequest(
                claim: subject,
                context: "Live network verification run \(index + 1).",
                sourceURL: "",
                content: ""
            )

            let result = try await checker.evaluate(request)
            let hasSearchEvidence = result.evidence.contains { evidence in
                let host = evidence.source?.host?.lowercased() ?? ""
                return evidence.sourceName.hasPrefix("Wikipedia:") || host.contains("wikipedia") || host.contains("gdelt")
            }

            if result.evidence.isEmpty || !hasSearchEvidence {
                failures.append("Run \(index + 1) for '\(subject)' returned \(result.evidence.count) evidence items.")
            }
        }

        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }
}
