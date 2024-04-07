import XCTVapor

@testable import App

final class ProfileTests: AbstractBaseTestsClass {
	func testEditShowErrors() async throws {
		let res = try await requestWithUser(.POST, "/profile/edit") { req in
			try req.content.encode([
				"name": "",
				"email": "this is not an e-mail",
				"password": "1",
				"password2": "3",
			])
		}

		let bodyStr = res.body.string
		XCTAssertContains(
			bodyStr, "<div class=\"error\">Password 2 must be equal to Password 1</div>"
		)
	}

	func testEditShowPasswordTooSmall() async throws {
		let res = try await requestWithUser(.POST, "/profile/edit") { req in
			try req.content.encode([
				"name": "",
				"email": "this is not an e-mail",
				"password": "1",
				"password2": "1",
			])
		}

		let bodyStr = res.body.string
		XCTAssertContains(
			bodyStr,
			"<div class=\"error\">Password doesn't comply the following errors: It should have 8 characters minimum, It should contain lower case letters, It should contain upper case letters</div>"
		)
		XCTAssertContains(
			bodyStr,
			"<div class=\"error\">Email is mandatory and must be a valid e-mail")
	}

	func testEditAndIsSaved() async throws {
		let app = try getApp()
		let _ = try await requestWithUser(.POST, "/profile/edit") { req in
			try req.content.encode([
				"name": "My New Name",
				"email": "new@email.com",
				"password": "Aabc1234",
				"password2": "Aabc1234",
			])
		}
		// let req =  try await requestWithUser(.GET, "/profile/edit")

		let cookie = try await loginWithUser(
			app: app, user: "new@email.com", password: "Aabc1234")
		XCTAssertContains(cookie, "vapor-session=")

		let headers: HTTPHeaders = ["cookie": cookie]
		let res = try await app.sendRequest(
			.GET, "/profile/edit", headers: headers)

		let bodyStr = res.body.string
		XCTAssertEqual(res.status, HTTPStatus.ok)
		XCTAssertContains(
			bodyStr,
			"<input type=\"text\" name=\"name\" value=\"My New Name\">"
		)
		XCTAssertContains(
			bodyStr,
			"<input type=\"email\" name=\"email\" value=\"new@email.com\" required>"
		)
	}
}
