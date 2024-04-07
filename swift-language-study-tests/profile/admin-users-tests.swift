import XCTVapor

@testable import App

final class AdminUsersTests: AbstractBaseTestsClass {
	func testListUsers() async throws {
		let res = try await requestWithAdmin(.GET, "/users")

		let bodyStr = res.body.string
		XCTAssertContains(
			bodyStr,
			"""
			            <td>demo</td>
			            <td>d@k.com</td>
			            <td>user</td>
			"""
		)
		XCTAssertContains(
			bodyStr,
			"""
			            <td>admin</td>
			            <td>j@k.com</td>
			            <td>admin</td>
			"""
		)
	}

	func testNewUserSave() async throws {
        let app = try getApp()
        
		let creationRes = try await requestWithAdmin(.POST, "/users/new") { req in
			try req.content.encode([
				"name": "Test user",
				"email": "user@test.com",
				"password": "Abc12345",
				"userType": "user"
			])
		}

        XCTAssertEqual(creationRes.status, .seeOther)
        
        let cookie = try await loginWithUser(app: app, user: "user@test.com", password: "Abc12345")
        
        XCTAssertContains(cookie, "vapor-session=")
        
        let res = try await app.sendRequest(.GET, "/profile", headers: ["cookie": cookie])
        
        let bodyStr = res.body.string
        XCTAssertContains(bodyStr, "user@test.com")
	}
}
