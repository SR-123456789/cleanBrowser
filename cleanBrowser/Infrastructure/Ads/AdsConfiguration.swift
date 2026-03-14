import Foundation

enum AdsConfiguration {
    static let testBannerUnitID = "ca-app-pub-3940256099942544/2934735716"

    static var footerBannerUnitID: String {
        resolvedInfoValue(for: "BrowserFootAdBarId") ?? testBannerUnitID
    }

    // Interstitial
    // Test
    static let interstitialUnitID = "ca-app-pub-3940256099942544/4411468910"

    // Production
    // static let interstitialUnitID = "ca-app-pub-7782777506427620/2605291341"

    private static func resolvedInfoValue(for key: String) -> String? {
        let rawValue = (Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !rawValue.isEmpty, !rawValue.hasPrefix("$(") else {
            return nil
        }

        return rawValue
    }
}
