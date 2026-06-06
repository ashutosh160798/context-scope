import XCTest
@testable import ContextScopeStorage

final class ContextScopeStorageTests: XCTestCase {
    func testDatabaseInitWithURL() {
        let url = URL(fileURLWithPath: "/tmp/test.db")
        let db = Database(url: url)
        // Verify the Database actor is created without crashing
        XCTAssertNotNil(db)
    }
}
