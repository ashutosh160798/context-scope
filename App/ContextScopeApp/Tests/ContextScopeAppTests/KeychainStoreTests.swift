import XCTest
@testable import ContextScopeApp

final class KeychainStoreTests: XCTestCase {
    // Use a unique service per test to isolate Keychain state across runs
    private var store: KeychainStore!

    override func setUp() {
        super.setUp()
        // Unique service name prevents leftover items from interfering
        store = KeychainStore(
            service: "com.contextscope.tests.\(name.replacingOccurrences(of: " ", with: "_"))",
            account: "testKey"
        )
        store.delete()  // ensure clean slate
    }

    override func tearDown() {
        store.delete()
        super.tearDown()
    }

    func testReadReturnsNilWhenAbsent() {
        XCTAssertNil(store.read())
    }

    func testWriteAndReadRoundtrip() {
        XCTAssertTrue(store.write("sk-test-12345"))
        XCTAssertEqual(store.read(), "sk-test-12345")
    }

    func testOverwriteUpdatesValue() {
        store.write("first-value")
        XCTAssertTrue(store.write("second-value"))
        XCTAssertEqual(store.read(), "second-value")
    }

    func testDeleteRemovesValue() {
        store.write("to-be-deleted")
        store.delete()
        XCTAssertNil(store.read())
    }
}
