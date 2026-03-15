import Foundation

enum AdsConfiguration {
    static let testInterstitialUnitID = "ca-app-pub-3940256099942544/4411468910"

    static var interstitialUnitID: String {
        resolvedInfoValue(for: "BrowserInterstitialAdUnitId") ?? testInterstitialUnitID
    }

    private static func resolvedInfoValue(for key: String) -> String? {
        let rawValue = (Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !rawValue.isEmpty, !rawValue.hasPrefix("$(") else {
            return nil
        }

        return rawValue
    }
}
