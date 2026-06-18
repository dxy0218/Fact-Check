import Foundation

enum FactCheckError: LocalizedError {
    case emptyRequest

    var errorDescription: String? {
        switch self {
        case .emptyRequest:
            return "请输入需要核查的陈述、正文片段或来源链接。"
        }
    }
}

struct FactChecker {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func evaluate(_ request: FactCheckRequest) async throws -> FactCheckResult {
        let subject = primarySubject(from: request)
        guard !subject.isEmpty else {
            throw FactCheckError.emptyRequest
        }

        async let wikipediaEvidence = searchWikipedia(for: subject)
        async let gdeltEvidence = searchGDELT(for: subject)
        async let providedSourceEvidence = inspectProvidedSource(request.sourceURL)

        let evidence = await (wikipediaEvidence + gdeltEvidence + providedSourceEvidence)
            .sorted { $0.confidence > $1.confidence }

        let verdict = verdict(for: evidence, subject: subject)
        let confidence = overallConfidence(for: evidence, verdict: verdict)

        return FactCheckResult(
            headline: headline(for: subject, evidence: evidence),
            verdict: verdict,
            evidence: evidence,
            recommendation: recommendation(for: verdict, evidenceCount: evidence.count),
            sourceCount: evidence.count,
            overallConfidence: confidence,
            archivedAt: Date(),
            analysisNote: analysisNote(for: request, evidenceCount: evidence.count, confidence: confidence)
        )
    }

    private func primarySubject(from request: FactCheckRequest) -> String {
        [request.claim, request.content, request.context, request.sourceURL]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
    }

    private func searchWikipedia(for subject: String) async -> [FactCheckEvidence] {
        var components = URLComponents(string: "https://zh.wikipedia.org/w/api.php")
        components?.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "list", value: "search"),
            URLQueryItem(name: "srsearch", value: subject),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "srlimit", value: "8"),
            URLQueryItem(name: "utf8", value: "1")
        ]

        guard let url = components?.url else { return [] }
        var request = URLRequest(url: url)
        request.timeoutInterval = 12

        do {
            let (data, _) = try await session.data(for: request)
            let response = try JSONDecoder().decode(WikipediaSearchResponse.self, from: data)

            return response.query.search.map { item in
                let summary = stripHTML(item.snippet)
                let confidence = confidence(forTitle: item.title, summary: summary, subject: subject, base: 0.62)

                return FactCheckEvidence(
                    sourceName: "Wikipedia：\(item.title)",
                    sourceType: "百科资料",
                    summary: summary.isEmpty ? "找到相关百科条目，可作为背景线索继续核对原始出处。" : summary,
                    source: URL(string: "https://zh.wikipedia.org/?curid=\(item.pageid)"),
                    verdict: evidenceVerdict(from: item.title + summary, confidence: confidence),
                    confidence: confidence
                )
            }
        } catch {
            return []
        }
    }

    private func searchGDELT(for subject: String) async -> [FactCheckEvidence] {
        var components = URLComponents(string: "https://api.gdeltproject.org/api/v2/doc/doc")
        components?.queryItems = [
            URLQueryItem(name: "query", value: subject),
            URLQueryItem(name: "mode", value: "artlist"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "maxrecords", value: "12"),
            URLQueryItem(name: "sort", value: "hybridrel")
        ]

        guard let url = components?.url else { return [] }
        var request = URLRequest(url: url)
        request.timeoutInterval = 12

        do {
            let (data, _) = try await session.data(for: request)
            let response = try JSONDecoder().decode(GDELTResponse.self, from: data)

            return response.articles.prefix(12).map { article in
                let title = article.title.trimmingCharacters(in: .whitespacesAndNewlines)
                let domain = article.domain ?? URL(string: article.url)?.host ?? "新闻来源"
                let confidence = confidence(forTitle: title, summary: domain, subject: subject, base: 0.58)

                return FactCheckEvidence(
                    sourceName: domain,
                    sourceType: "新闻检索",
                    summary: title.isEmpty ? "新闻索引中找到相关报道线索。" : title,
                    source: URL(string: article.url),
                    verdict: evidenceVerdict(from: title, confidence: confidence),
                    confidence: confidence
                )
            }
        } catch {
            return []
        }
    }

    private func inspectProvidedSource(_ sourceURL: String) async -> [FactCheckEvidence] {
        let trimmed = sourceURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else {
            return []
        }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 12
            request.setValue("FactCheckApp/1.0", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await session.data(for: request)
            let title = extractTitle(from: data) ?? url.host ?? url.absoluteString
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            let summary = statusCode.map { "用户提供的链接可访问，HTTP 状态码 \($0)。页面标题：\(title)" } ?? "用户提供的链接可访问。页面标题：\(title)"
            let confidence = statusCode.map { (200..<400).contains($0) ? 0.66 : 0.38 } ?? 0.56

            return [
                FactCheckEvidence(
                    sourceName: url.host ?? "用户提供来源",
                    sourceType: "原始链接",
                    summary: summary,
                    source: url,
                    verdict: evidenceVerdict(from: title, confidence: confidence),
                    confidence: confidence
                )
            ]
        } catch {
            return [
                FactCheckEvidence(
                    sourceName: url.host ?? "用户提供来源",
                    sourceType: "原始链接",
                    summary: "无法直接读取该链接：\(error.localizedDescription)",
                    source: url,
                    verdict: .unverifiable,
                    confidence: 0.25
                )
            ]
        }
    }

    private func confidence(forTitle title: String, summary: String, subject: String, base: Double) -> Double {
        let haystack = (title + " " + summary).lowercased()
        let tokens = meaningfulTokens(in: subject)
        let matches = tokens.filter { haystack.contains($0.lowercased()) }.count
        let ratio = tokens.isEmpty ? 0 : Double(matches) / Double(tokens.count)
        let penalty = containsUncertaintySignal(haystack) ? -0.12 : 0

        return clamped(base + ratio * 0.22 + penalty)
    }

    private func meaningfulTokens(in text: String) -> [String] {
        var tokens = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 2 }

        let chineseCharacters = Array(text).filter { character in
            character.unicodeScalars.contains { scalar in
                (0x4E00...0x9FFF).contains(Int(scalar.value))
            }
        }

        if chineseCharacters.count >= 2 {
            tokens.append(contentsOf: chineseCharacters.indices.dropLast().map { index in
                String(chineseCharacters[index]) + String(chineseCharacters[index + 1])
            })
        }

        return Array(Set(tokens))
    }

    private func evidenceVerdict(from text: String, confidence: Double) -> FactCheckVerdict {
        let lowercased = text.lowercased()
        if containsUncertaintySignal(lowercased) {
            return .disputed
        }

        switch confidence {
        case 0.68...:
            return .confirmed
        case ..<0.45:
            return .unverifiable
        default:
            return .unverifiable
        }
    }

    private func verdict(for evidence: [FactCheckEvidence], subject: String) -> FactCheckVerdict {
        guard !evidence.isEmpty else { return .unverifiable }

        let disputedCount = evidence.filter { $0.verdict == .disputed }.count
        let confirmedCount = evidence.filter { $0.verdict == .confirmed }.count
        let average = evidence.map(\.confidence).reduce(0, +) / Double(evidence.count)

        if disputedCount >= max(2, confirmedCount) {
            return .disputed
        }

        if confirmedCount >= 3 && average >= 0.62 {
            return .confirmed
        }

        return .unverifiable
    }

    private func overallConfidence(for evidence: [FactCheckEvidence], verdict: FactCheckVerdict) -> Double {
        guard !evidence.isEmpty else { return 0 }
        let average = evidence.map(\.confidence).reduce(0, +) / Double(evidence.count)

        switch verdict {
        case .confirmed:
            return clamped(average)
        case .disputed:
            return clamped(1 - average)
        case .unverifiable:
            return clamped(min(average, 0.55))
        }
    }

    private func headline(for subject: String, evidence: [FactCheckEvidence]) -> String {
        if let firstConfirmed = evidence.first(where: { $0.verdict == .confirmed }) {
            return "找到相关公开线索：\(firstConfirmed.summary.prefix(36))"
        }

        return "核查：\(subject.prefix(42))"
    }

    private func recommendation(for verdict: FactCheckVerdict, evidenceCount: Int) -> String {
        switch verdict {
        case .confirmed:
            return "多个公开来源存在相关线索。转发或引用前，建议点开原始链接确认发布日期、上下文和是否存在后续更正。"
        case .disputed:
            return "检索结果中出现辟谣、争议或否认信号。建议暂缓转发，并优先查找官方原文、权威媒体更正和事实核查机构说明。"
        case .unverifiable:
            if evidenceCount == 0 {
                return "暂未从在线来源取得足够证据。请补充更具体的关键词、原始链接、发布时间、地点或人物后再试。"
            }
            return "已有线索不足以给出确定结论。建议继续补充原始来源，并对比报道时间线和出处可信度。"
        }
    }

    private func analysisNote(for request: FactCheckRequest, evidenceCount: Int, confidence: Double) -> String {
        let contextState = request.context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "未提供额外上下文" : "已结合补充上下文"
        return "\(contextState)，本次实时查询整合 \(evidenceCount) 条百科、新闻索引或原始链接线索，综合可信度约 \(Int(confidence * 100))%。"
    }

    private func containsUncertaintySignal(_ text: String) -> Bool {
        ["谣言", "不实", "辟谣", "造假", "争议", "否认", "false", "fake", "hoax", "misleading"]
            .contains { text.contains($0) }
    }

    private func stripHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#039;", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractTitle(from data: Data) -> String? {
        let sample = Data(data.prefix(120_000))
        guard let html = String(data: sample, encoding: .utf8) ?? String(data: sample, encoding: .ascii) else {
            return nil
        }

        guard let range = html.range(of: #"<title[^>]*>(.*?)</title>"#, options: [.regularExpression, .caseInsensitive]) else {
            return nil
        }

        return stripHTML(String(html[range]))
            .replacingOccurrences(of: "<title>", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "</title>", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func clamped(_ value: Double) -> Double {
        min(0.96, max(0.08, value))
    }
}

private struct WikipediaSearchResponse: Decodable {
    let query: Query

    struct Query: Decodable {
        let search: [Item]
    }

    struct Item: Decodable {
        let pageid: Int
        let title: String
        let snippet: String
    }
}

private struct GDELTResponse: Decodable {
    let articles: [Article]

    struct Article: Decodable {
        let title: String
        let url: String
        let domain: String?
    }
}
