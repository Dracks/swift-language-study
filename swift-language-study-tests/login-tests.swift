import XCTVapor

@testable import App

final class LoginTests: AbstractBaseTestsClass {

	func testLogin() async throws {
		let app = try getApp()

		let res = try app.sendRequest(
			.POST, "/login",
			beforeRequest: { req in
				try req.content.encode(["username": "j@k.com", "password": "admin"])
			})
		XCTAssertEqual(res.status, .seeOther)
		XCTAssertEqual(res.headers.contains(name: "location"), true)
		let location: [String] = res.headers["location"]
		XCTAssertEqual(location, ["/profile"])
	}

	func testAdminLayout() async throws {

		let res = try await requestWithAdmin(
			.GET, "/profile"
		)
		XCTAssertContains(
			res.body.string,
			"<summary role=\"button\">Admin</summary>"
		)
	}

	func testUserHomeScreen() async throws {
		let res = try await requestWithUser(.GET, "/")

		XCTAssertContains(res.body.string, "<h2>Welcome back demo</h2>")

	}

}
