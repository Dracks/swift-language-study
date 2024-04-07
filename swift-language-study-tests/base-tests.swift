import XCTVapor

@testable import App

final class BaseTests: AbstractBaseTestsClass {
	func testNotFound() async throws {

		let res = try await getApp().sendRequest(
			.GET, "hello")

		XCTAssertEqual(res.status, .notFound)
		XCTAssertContains(res.body.string, "Not found")
	}

}
