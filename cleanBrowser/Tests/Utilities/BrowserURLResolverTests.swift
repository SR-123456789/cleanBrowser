import XCTest
@testable import cleanBrowser

final class BrowserURLResolverTests: XCTestCase {
    func test_resolve_returnsNilForEmptyInput() {
        XCTAssertNil(BrowserURLResolver.resolve("   "))
    }

    func test_resolve_keepsHTTPAndHTTPSURLs() {
        XCTAssertEqual(
            BrowserURLResolver.resolve("https://example.com/path")?.absoluteString,
            "https://example.com/path"
        )
        XCTAssertEqual(
            BrowserURLResolver.resolve("http://example.com")?.absoluteString,
            "http://example.com"
        )
    }

    func test_resolve_prefixesBareDomainWithHTTPS() {
        XCTAssertEqual(
            BrowserURLResolver.resolve("example.com")?.absoluteString,
            "https://example.com"
        )
    }

    func test_resolve_convertsSearchQueryToGoogleSearchURL() {
        XCTAssertEqual(
            BrowserURLResolver.resolve("swift ui testing")?.absoluteString,
            "https://www.google.com/search?q=swift%20ui%20testing"
        )
    }

    func test_displayText_returnsHostWhenURLIsValid() {
        XCTAssertEqual(
            BrowserURLResolver.displayText(for: "https://www.example.com/articles?id=1"),
            "www.example.com"
        )
    }

    func test_displayText_returnsRawValueWhenURLIsInvalid() {
        XCTAssertEqual(
            BrowserURLResolver.displayText(for: "not a valid url"),
            "not a valid url"
        )
    }
}
