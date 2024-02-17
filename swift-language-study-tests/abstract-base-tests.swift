import Fluent
import SwiftHtml
import XCTVapor

@testable import App

class AbstractBaseTestsClass: XCTestCase {
	var app: Application?

	func getApp() throws -> Application {
		guard let app = app else {
			throw TestError()
		}
		return app
	}

	override func setUp() async throws {
		let app = Application(.testing)
		try await configure(app)
		try await createUsers(app: app)
		self.app = app
		try await addBaseDeutsch(app: app)
	}

	override func tearDown() async throws {
		app?.shutdown()
	}

	func requestWithAdmin(
		_ method: HTTPMethod,
		_ path: String,
		headers inmutableHeader: HTTPHeaders = [:],
		body: ByteBuffer? = nil,
		file: StaticString = #file,
		line: UInt = #line,
		beforeRequest: (inout XCTHTTPRequest) async throws -> Void = { _ in }
	) async throws -> XCTHTTPResponse {
		guard let app = app else {
			throw TestError()
		}
		let cookie = try await loginWithUser(app: app, user: "j@k.com", password: "admin")
		var headers = inmutableHeader
		headers.add(name: "cookie", value: cookie)
		return try await app.sendRequest(
			method, path, headers: headers, body: body, file: file, line: line,
			beforeRequest: beforeRequest)
	}
    
    func requestWithUser(_ method: HTTPMethod,
                         _ path: String,
                         headers inmutableHeader: HTTPHeaders = [:],
                         body: ByteBuffer? = nil,
                         file: StaticString = #file,
                         line: UInt = #line,
                         beforeRequest: (inout XCTHTTPRequest) async throws -> Void = { _ in }) async throws -> XCTHTTPResponse {
        guard let app = app else {
            throw TestError()
        }
        let cookie = try await loginWithUser(app: app, user: "d@k.com", password: "demo")
        var headers = inmutableHeader
        headers.add(name: "cookie", value: cookie)
        return try await app.sendRequest(
            method, path, headers: headers, body: body, file: file, line: line,
            beforeRequest: beforeRequest)
        
    }

	func renderTag(_ tag: Tag) -> String {
		return Document { tag }.render()
	}
    
    func getDeutsch() async throws -> Language {
        let deutsch = try await Language.query(on: app!.db).filter(\.$name == "Deutsch")
            .first()
        guard let deutsch = deutsch else {
            throw TestError()
        }
        return deutsch
    }
}
