import Fluent
import XCTVapor

@testable import App

final class DeclinationTests: AbstractBaseTestsClass {

	func testDropDeclinationCase() async throws {
		guard let app = app else {
			throw TestError()
		}
		let dasCase = try await DeclinationTypeCase.query(on: app.db).filter(
			\.$name == "das"
		).first()
		guard let dasCase = dasCase else {
			throw TestError()
		}

		let res = try await requestWithAdmin(
			.DELETE, "/declinations-form/case/\(dasCase.id?.uuidString ?? "")",
			beforeRequest: { req in
				try req.content.encode(["dec-type-id": dasCase.$type.id.uuidString])
			})
		let currentCases = try await DeclinationTypeCase.query(on: app.db).filter(
			\.$type.$id == dasCase.$type.id
		).sort(\.$order, .ascending).all()
		XCTAssertEqual(currentCases.count, 3)
		XCTAssertEqual(currentCases[2].order, 2)
		XCTAssertEqual(currentCases[2].name, "die")
		for decCase in currentCases {
			XCTAssertContains(
				res.body.string,
				"delete=\"/declinations-form/case/\(decCase.id?.uuidString ?? "")")
		}
	}

	func testMoveUpDeclinationCase() async throws {
		guard let app = app else {
			throw TestError()
		}
		let dasCase = try await DeclinationTypeCase.query(on: app.db).filter(
			\.$name == "das"
		).first()
		guard let dasCase = dasCase else {
			throw TestError()
		}

		let res = try await requestWithAdmin(
			.PUT, "/declinations-form/case/\(dasCase.id?.uuidString ?? "")/-1",
			beforeRequest: { req in
				try req.content.encode(["dec-type-id": dasCase.$type.id.uuidString])
			})
		let currentCases = try await DeclinationTypeCase.query(on: app.db).filter(
			\.$type.$id == dasCase.$type.id
		).sort(\.$order, .ascending).all()
		XCTAssertEqual(currentCases.count, 4)
		XCTAssertEqual(currentCases[1].order, 1)
		XCTAssertEqual(currentCases[1].name, "das")
		XCTAssertEqual(currentCases[2].order, 2)
		XCTAssertEqual(currentCases[2].name, "die")
		for decCase in currentCases {
			XCTAssertContains(
				res.body.string,
				"put=\"/declinations-form/case/\(decCase.id?.uuidString ?? "")/-1\""
			)
		}
	}

	func testMoveDownDeclinationCase() async throws {
		guard let app = app else {
			throw TestError()
		}
		let dasCase = try await DeclinationTypeCase.query(on: app.db).filter(
			\.$name == "das"
		).first()
		guard let dasCase = dasCase else {
			throw TestError()
		}

		let res = try await requestWithAdmin(
			.PUT, "/declinations-form/case/\(dasCase.id?.uuidString ?? "")/1",
			beforeRequest: { req in
				try req.content.encode(["dec-type-id": dasCase.$type.id.uuidString])
			})
		let currentCases = try await DeclinationTypeCase.query(on: app.db).filter(
			\.$type.$id == dasCase.$type.id
		).sort(\.$order, .ascending).all()
		XCTAssertEqual(currentCases.count, 4)
		XCTAssertEqual(currentCases[3].order, 3)
		XCTAssertEqual(currentCases[3].name, "das")
		XCTAssertEqual(currentCases[2].order, 2)
		XCTAssertEqual(currentCases[2].name, "die")
		for decCase in currentCases {
			XCTAssertContains(
				res.body.string,
				"put=\"/declinations-form/case/\(decCase.id?.uuidString ?? "")/1\"")
		}
		// XCTAssertEqual(res.body.string, "")
	}
}
