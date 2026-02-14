//
//  FriendsStories
//

import Foundation

struct NetworkClientImpl: NetworkClient {
    private let baseURL: URL
    private let decoder: JSONDecoder

    init(baseURL: URL, decoder: JSONDecoder) {
        self.baseURL = baseURL
        self.decoder = decoder
    }

    func fetch<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)
        if !endpoint.queryItems.isEmpty {
            components?.queryItems = endpoint.queryItems
        }

        guard let finalURL = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = endpoint.method

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let urlResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        switch urlResponse.statusCode {
        case 200...299:
            let decoded = try decoder.decode(E.Response.self, from: data)
            return decoded
        case 300...399:
            throw URLError(.badServerResponse)
        case 400...499:
            throw URLError(.badServerResponse)
        case 500...599:
            throw URLError(.badServerResponse)
        default:
            throw URLError(.badServerResponse)
        }
    }
}
