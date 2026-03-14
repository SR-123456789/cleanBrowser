import Foundation

enum BrowserURLResolver {
    static let defaultHomePage = "https://www.google.com"

    static func resolve(_ rawInput: String) -> URL? {
        let input = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return nil }

        let finalString: String
        if input.hasPrefix("http://") || input.hasPrefix("https://") {
            finalString = input
        } else if input.contains(".") && !input.contains(" ") {
            finalString = "https://\(input)"
        } else {
            let encodedQuery = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            finalString = "https://www.google.com/search?q=\(encodedQuery)"
        }

        return URL(string: finalString)
    }

    static func displayText(for rawURL: String) -> String {
        guard let components = URLComponents(string: rawURL) else { return rawURL }
        return components.host ?? rawURL
    }
}
