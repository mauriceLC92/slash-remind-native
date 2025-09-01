import Foundation
#if canImport(os)
import os.log
#endif

protocol RemindersAPI {
    func createReminder(text: String) async throws
}

struct HTTPRemindersAPI: RemindersAPI {
    var baseURL: URL
    var session: URLSession = .shared

    func createReminder(text: String) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("reminders"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["text": text])
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
#if canImport(os)
            os_log("bad server response", log: .network, type: .error)
#endif
            throw URLError(.badServerResponse)
        }
    }
}

struct MockRemindersAPI: RemindersAPI {
    var created: [String] = []
    mutating func createReminder(text: String) async throws {
        created.append(text)
    }
}
