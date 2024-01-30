import XCTVapor

@testable import App

class TestError: Error {

}

func createUsers(app: Application) async throws {
	let admin = User(email: "j@k.com", name: "admin", isAdmin: true)
	try admin.setPassword(pwd: "admin")
	try await admin.save(on: app.db)

	let demo = User(email: "d@k.com", name: "demo")
	try demo.setPassword(pwd: "demo")
	try await demo.save(on: app.db)
}

func loginWithUser(app: Application, user: String, password: String) async throws -> String {
	let res = try app.sendRequest(.POST, "/login") { req in
		try req.content.encode(["username": "j@k.com", "password": "admin"])
	}
	XCTAssertEqual(res.headers.contains(name: "set-cookie"), true)
	let cookiesList: [String] = res.headers["set-cookie"]
	let cookie: String = cookiesList[0]
	XCTAssertContains(cookie, "vapor-session=")

	return cookie

}
