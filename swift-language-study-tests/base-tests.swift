import XCTVapor

@testable import App

final class BaseTests: XCTestCase {
	func testNotFound() async throws {
		let app = Application(.testing)
		defer { app.shutdown() }
		try await configure(app)

		try app.test(
			.GET, "hello",
			afterResponse: { res in
				XCTAssertEqual(res.status, .notFound)
				XCTAssertContains(res.body.string, "Not found")
			})
	}

	func testLogin() async throws {
		let app = Application(.testing)
		defer { app.shutdown() }
		try await configure(app)
		try await createUsers(app: app)

		try app.test(
			.POST, "/login",
			beforeRequest: { req in
				try req.content.encode(["username": "j@k.com", "password": "admin"])
			},
			afterResponse: { res in
				XCTAssertEqual(res.status, .seeOther)
				XCTAssertEqual(res.headers.contains(name: "location"), true)
				let location: [String] = res.headers["location"]
				XCTAssertEqual(location, ["/profile"])
			})
	}

	func testAdminLayout() async throws {
		let app = Application(.testing)
		defer { app.shutdown() }
		try await configure(app)
		try await createUsers(app: app)
		let cookie = try await loginWithUser(app: app, user: "j@k.com", password: "admin")

		try app.test(
			.GET, "/profile", headers: ["cookie": cookie],
			afterResponse: { res in
				XCTAssertContains(
					res.body.string,
					"<summary role=\"button\">Admin</summary>"
				)
			})
	}

}
