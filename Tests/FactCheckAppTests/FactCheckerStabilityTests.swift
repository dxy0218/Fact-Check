import Foundation
@testable import FactCheckApp
import XCTest

final class FactCheckerStabilityTests: XCTestCase {
    func testEvaluatorStaysStableAcrossFourHundredRuns() async throws {
        let checker = FactChecker(dataLoader: Self.mockedDataLoader)
        let request = FactCheckRequest(
            claim: "喝咖啡会导致脱水吗？",
            context: "朋友群里转发的健康提醒。",
            sourceURL: "https://example.com/coffee",
            content: "文章称咖啡因有利尿作用，所以喝咖啡会让身体脱水。"
        )

        for index in 0..<400 {
            let result = try await checker.evaluate(request)

            XCTAssertFalse(result.headline.isEmpty, "Run \(index) produced an empty headline")
            XCTAssertEqual(result.verdict, .confirmed, "Run \(index) produced an unexpected verdict")
            XCTAssertEqual(result.sourceCount, result.evidence.count, "Run \(index) source count drifted")
            XCTAssertGreaterThanOrEqual(result.sourceCount, 3, "Run \(index) lost evidence")
            XCTAssertGreaterThan(result.overallConfidence, 0.5, "Run \(index) confidence dropped")
            XCTAssertLessThanOrEqual(result.overallConfidence, 0.96, "Run \(index) confidence exceeded clamp")

            let encoded = try JSONEncoder.iso8601.encode(result)
            let decoded = try JSONDecoder.iso8601.decode(FactCheckResult.self, from: encoded)
            XCTAssertEqual(decoded.verdict, result.verdict, "Run \(index) failed Codable round trip")
            XCTAssertEqual(decoded.evidence.count, result.evidence.count, "Run \(index) changed evidence during Codable round trip")
        }
    }

    func testEmptyInputReturnsReadableError() async {
        let checker = FactChecker(dataLoader: Self.mockedDataLoader)
        let request = FactCheckRequest(claim: " ", context: "", sourceURL: "", content: "\n")

        do {
            _ = try await checker.evaluate(request)
            XCTFail("Expected empty input to throw")
        } catch let error as FactCheckError {
            XCTAssertEqual(error.errorDescription, "请输入需要核查的陈述、正文片段或来源链接。")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private static func mockedDataLoader(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let host = request.url?.host ?? ""
        let body: String

        if host.contains("wikipedia") {
            body = """
            {
              "query": {
                "search": [
                  {
                    "pageid": 100,
                    "title": "咖啡",
                    "snippet": "喝咖啡会导致脱水吗：适量饮用通常不会导致明显脱水。"
                  },
                  {
                    "pageid": 101,
                    "title": "咖啡因",
                    "snippet": "喝咖啡会导致脱水吗：咖啡因有轻微利尿作用，但日常摄入的液体会抵消影响。"
                  }
                ]
              }
            }
            """
        } else if host.contains("gdeltproject") {
            body = """
            {
              "articles": [
                {
                  "title": "喝咖啡会导致脱水吗：研究称适量咖啡不会导致脱水",
                  "url": "https://news.example.com/coffee-hydration",
                  "domain": "news.example.com"
                },
                {
                  "title": "喝咖啡会导致脱水吗：咖啡与补水关系的健康报道",
                  "url": "https://health.example.com/coffee",
                  "domain": "health.example.com"
                }
              ]
            }
            """
        } else {
            body = """
            <!doctype html>
            <html>
              <head><title>Coffee and hydration research</title></head>
              <body>Moderate coffee intake is not associated with dehydration.</body>
            </html>
            """
        }

        let data = Data(body.utf8)
        let response = HTTPURLResponse(
            url: request.url ?? URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json; charset=utf-8"]
        )!

        return (data, response)
    }
}

private extension JSONEncoder {
    static var iso8601: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var iso8601: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
