import XCTest
@testable import PlustagMonitor
final class UsageTests: XCTestCase {
    func testMultipleBucketsAndUnknownValues() throws {
        let data = Data(#"{"rateLimits":{"primary":{"usedPercent":99}},"rateLimitsByLimitId":{"codex":{"primary":{"usedPercent":25,"windowDurationMins":300,"resetsAt":1800000000}},"other":{"secondary":null}}}"#.utf8)
        let response = try JSONDecoder().decode(UsageResponse.self, from: data)
        XCTAssertEqual(response.buckets.count, 2)
        XCTAssertEqual(response.buckets.first?.1.primary?.remaining, 75)
        XCTAssertNil(response.buckets.last?.1.primary)
    }
    func testLegacyAndClamping() throws {
        let response = try JSONDecoder().decode(UsageResponse.self, from: Data(#"{"rateLimits":{"primary":{"usedPercent":110}}}"#.utf8))
        XCTAssertEqual(response.buckets.first?.1.primary?.remaining, 0)
        XCTAssertTrue(try JSONDecoder().decode(UsageResponse.self, from: Data("{}".utf8)).buckets.isEmpty)
    }
    func testLocalCodexConnection() throws {
        guard ProcessInfo.processInfo.environment["PLUSTAG_CHECK_LIVE"] == "1" else { throw XCTSkip("Lectura real opcional") }
        let response = try CodexProvider().fetch()
        XCTAssertFalse(response.buckets.isEmpty)
    }
}
