import Fluent
import XCTVapor

@testable import App

final class ExercisesTests: AbstractBaseTestsClass {
	override func setUp() async throws {
		try await super.setUp()
		let deutsch = try await getDeutsch()
		let app = try getApp()
		try await createSampleWords(app: app, language: try deutsch.requireID())
	}
	func testRandomWordFilterByLevel() async throws {
		let deutsch = try await getDeutsch()

		let query = ExercisesController.RandomWordQuery(
			language: try deutsch.requireID(), level: .B1)

		let res = try await requestWithUser(.POST, "/exercises/random-words") { req in
			try req.content.encode(query)
		}

		XCTAssertContains(res.body.string, "<h3>Schwäche</h3>")
	}

	func testRandomWordFilterByLevelAndType() async throws {
		let deutsch = try await getDeutsch()

		let query = ExercisesController.RandomWordQuery(
			language: try deutsch.requireID(), level: .A1, type: .verb)

		let res = try await requestWithUser(.POST, "/exercises/random-words") { req in
			try req.content.encode(query)
		}

		XCTAssertContains(res.body.string, "<h3>sein</h3>")
	}

	func testRandomWordFilterWithEmptySelects() async throws {
		let deutsch = try await getDeutsch()

		let res = try await requestWithUser(.POST, "/exercises/random-words") { req in
			try req.content.encode([
				"language": try deutsch.requireID().uuidString,
				"level": "",
				"type": "",
			])
		}

		XCTAssertContains(
			res.body.string, "<input type=\"hidden\" name=\"type\" value=\"\">")
		XCTAssertContains(
			res.body.string, "<input type=\"hidden\" name=\"level\" value=\"\">")
	}

}
