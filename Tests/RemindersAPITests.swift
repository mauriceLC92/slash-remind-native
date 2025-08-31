import XCTest
@testable import SlashRemind

final class RemindersAPITests: XCTestCase {
    func testCreateReminderPostsPayload() async throws {
        class MockURLProtocol: URLProtocol {
            static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
            override class func canInit(with request: URLRequest) -> Bool { true }
            override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
            override func startLoading() {
                guard let handler = MockURLProtocol.handler else { return }
                do {
                    let (response, data) = try handler(request)
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                } catch {
                    client?.urlProtocol(self, didFailWithError: error)
                }
            }
            override func stopLoading() {}
        }

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            let body = try JSONSerialization.jsonObject(with: request.httpBody!) as? [String: String]
            XCTAssertEqual(body?["text"], "hello")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let api = HTTPRemindersAPI(baseURL: URL(string: "https://example.com")!, session: session)
        try await api.createReminder(text: "hello")
    }
}
