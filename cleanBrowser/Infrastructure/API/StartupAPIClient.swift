import Foundation

struct StartupResponse: Decodable, Equatable {
    let update: StartupUpdateResponse
    let ads: [StartupAdVisibilityResponse]
}

struct StartupUpdateResponse: Decodable, Equatable {
    let mustUpdate: Bool
    let shouldUpdate: Bool
    let repeatUpdatePrompt: Bool
    let updateLink: String
    let message: String
}

struct StartupAdVisibilityResponse: Decodable, Equatable {
    let adID: String
    let isShow: Bool
}

protocol StartupLoading {
    func fetchStartup(appVersion: String) async throws -> StartupResponse
}

protocol URLSessionDataLoading {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionDataLoading {}

final class StartupAPIClient: StartupLoading {
    private enum InfoKeys {
        static let baseURL = "StartupAPIBaseURL"
        static let apiKey = "PublicAPIKey"
    }

    private let session: any URLSessionDataLoading
    private let configuration: Configuration?
    private let decoder: JSONDecoder

    init(
        session: any URLSessionDataLoading = URLSession.shared,
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.configuration = Configuration(bundle: bundle)
        self.decoder = decoder
    }

    func fetchStartup(appVersion: String) async throws -> StartupResponse {
        guard let configuration else {
            throw StartupAPIClientError.missingConfiguration
        }

        var components = URLComponents(url: configuration.baseURL, resolvingAgainstBaseURL: false)
        let basePath = components?.path ?? ""
        components?.path = normalizedPath(
            basePath: basePath,
            appending: "/api/v1/public/startup"
        )
        components?.queryItems = [
            URLQueryItem(name: "appVersion", value: appVersion)
        ]

        guard let url = components?.url else {
            throw StartupAPIClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        request.setValue(configuration.apiKey, forHTTPHeaderField: "X-API-Key")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StartupAPIClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw StartupAPIClientError.httpError(statusCode: httpResponse.statusCode)
        }

        return try decoder.decode(StartupResponse.self, from: data)
    }

    private func normalizedPath(basePath: String, appending path: String) -> String {
        let trimmedBasePath = basePath == "/" ? "" : basePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if trimmedBasePath.isEmpty {
            return path
        }

        return "/" + trimmedBasePath + path
    }

    private struct Configuration {
        let baseURL: URL
        let apiKey: String

        init?(bundle: Bundle) {
            guard
                let baseURLString = bundle.cleanBrowserResolvedInfoValue(for: InfoKeys.baseURL),
                let apiKey = bundle.cleanBrowserResolvedInfoValue(for: InfoKeys.apiKey),
                let baseURL = URL(string: baseURLString)
            else {
                return nil
            }

            self.baseURL = baseURL
            self.apiKey = apiKey
        }
    }
}

enum StartupAPIClientError: Error, Equatable {
    case missingConfiguration
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
}

private extension Bundle {
    func cleanBrowserResolvedInfoValue(for key: String) -> String? {
        let rawValue = (object(forInfoDictionaryKey: key) as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !rawValue.isEmpty, !rawValue.hasPrefix("$(") else {
            return nil
        }

        return rawValue
    }
}
