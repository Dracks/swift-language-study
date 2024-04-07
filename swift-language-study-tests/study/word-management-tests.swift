import Fluent
import SwiftHtml
import XCTVapor

@testable import App

class WordsManagementTests: AbstractBaseTestsClass {

	func testListWords() async throws {
		let deutsch = try await getDeutsch()
		let app = try getApp()
		try await createSampleWords(app: app, language: try deutsch.requireID())

		let res = try await requestWithAdmin(.GET, "/words-management/list")

		XCTAssertContains(res.body.string, "<td>Haus</td>")
	}

	func testNewWordForm() async throws {
		// let app = try getApp()

		let deutsch = try await getDeutsch()

		let res = try await requestWithAdmin(
			.GET, "/words-management/get-form?languageId=\(try deutsch.requireID())")

		let body = res.body.string
		XCTAssertContains(
			body,
			"<form id=\"wordForm\" hx-post=\"/words-management/new-word\" hx-include=\".extra-fields\">"
		)
		XCTAssertContains(body, "<select name=\"wordLevel\" id=\"wordLevel\" tabindex=\"6\">")
		XCTAssertContains(body, "<select name=\"wordType\" id=\"wordType\" required tabindex=\"7\">")
		XCTAssertContains(body, "<div id=\"declinations-table\"></div>")

	}

	func testSelectRawWithNoImported() async throws {
		let app = try getApp()

		let deutsch = try await getDeutsch()
		let catalan = Language(name: "Catalan")
		try await catalan.save(on: app.db)
		try await RawImport(
			word: "some word", level: .A2, languageID: try catalan.requireID()
		).save(on: app.db)

		let res = try await requestWithAdmin(
			.GET,
			"/words-management/select-raw-import/random/\(try deutsch.requireID())")

		XCTAssertFalse(res.body.string.contains("name=\"rawWordId\""))
		// I dropped the field, need to rething this test
		//XCTAssertContains(
		//	res.body.string, renderTag(Input().name("rawWordId").type(.hidden)))
	}

	func testSelectRawWithOneImported() async throws {
		let app = try getApp()

		let deutsch = try await getDeutsch()

		let rawImport = RawImport(
			word: "some word", level: .A2, languageID: try deutsch.requireID())
		try await rawImport.save(on: app.db)

		let rawImportAttached = RawImport(
			word: "some word", level: .A2, languageID: try deutsch.requireID())
		try await rawImportAttached.save(on: app.db)

		let wordAttached = Word(
			word: "Hello", type: .noun, level: .A2,
			rawID: try rawImportAttached.requireID(),
			languageID: try deutsch.requireID())
		try await wordAttached.save(on: app.db)

		let res = try await requestWithAdmin(
			.GET,
			"/words-management/select-raw-import/random/\(try deutsch.requireID())")

		XCTAssertContains(
			res.body.string,
			renderTag(
				Input().name("rawWordId").type(.hidden).value(
					try rawImport.requireID().uuidString
				).class("extra-fields"))

		)
	}

	func testCreatingNewNoun() async throws {
		let app = try getApp()
		let deutsch = try await getDeutsch()

		let rawImport = RawImport(
			word: "some word", level: .A2, languageID: try deutsch.requireID())
		try await rawImport.save(on: app.db)

		let response = try await requestWithAdmin(.POST, "words-management/new-word") {
			req in
			try req.content.encode([
				"word": "My new word",
				"wordLevel": WordLevel.A2.rawValue,
				"wordType": WordType.noun.rawValue,
				"languageId": try deutsch.requireID().uuidString,
				"rawWordId": try rawImport.requireID().uuidString,
			])
		}

		let gender = try await DeclinationType.query(on: app.db)
			.filter(\.$language.$id == deutsch.id!)
			.filter(\.$name == "gender")
			.with(\.$cases)
			.first()!

		let words = try await Word.query(on: app.db).all()
		XCTAssertEqual(words.count, 1)
		let newWord = words.first!
		XCTAssertEqual(newWord.word, "My new word")
		XCTAssertEqual(newWord.level, .A2)
		XCTAssertEqual(newWord.type, .noun)
		XCTAssertEqual(newWord.$language.id, try deutsch.requireID())
		XCTAssertEqual(newWord.$raw.id, try rawImport.requireID())

		let bodyStr = response.body.string
		XCTAssertContains(
			response.body.string,
			"<input name=\"wordId\" value=\"\(try newWord.requireID().uuidString)\" type=\"hidden\">"
		)
		// something is loose in translation
		XCTAssertContains(response.body.string, "<option value=\"A2\" selected>A2</option>")
		XCTAssertContains(
			response.body.string, "<option value=\"noun\" selected>Noun</option>")

		for genderCase in gender.cases {
			XCTAssertContains(
				bodyStr,
				"<input type=\"hidden\" name=\"declinationTypeIds[]\" value=\"\(try genderCase.requireID())\">"
			)
		}
	}

	func testCreateNewDeclination() async throws {
		let app = try getApp()
		let deutsch = try await getDeutsch()

		let word = Word(
			word: "kaufen", type: .verb, level: .A1, languageID: try deutsch.requireID()
		)
		try await word.save(on: app.db)

		let you = try await DeclinationTypeCase.query(on: app.db).filter(\.$name == "du")
			.first()!
		let present = try await DeclinationTypeCase.query(on: app.db).filter(
			\.$name == "present"
		).first()!

		let response = try await requestWithAdmin(
			.POST, "words-management/edit-declination"
		) { req in
			let formData = WordsManagementController.EditDeclinationData(
				tabIndex: -1,
				declination: "kaufst",
				declinationTypeIds: [
					try you.requireID(),
					try present.requireID(),
				], wordId: try word.requireID())
			try req.content.encode(formData)
		}

		let newDec = try await WordDeclination.query(on: app.db).first()
		XCTAssertEqual(newDec?.text, "kaufst")
		XCTAssertContains(
			response.body.string,
			"<input type=\"hidden\" name=\"declinationId\" value=\"\(try newDec?.requireID().uuidString ?? "")\">"
		)
		// XCTAssertEqual(response.body.string, "")
	}

	func testEditDeclination() async throws {
		let app = try getApp()
		let deutsch = try await getDeutsch()

		let word = Word(
			word: "kaufen", type: .verb, level: .A1, languageID: try deutsch.requireID()
		)
		try await word.save(on: app.db)

		let wordDeclination = WordDeclination(text: "kaufe-", wordID: try word.requireID())
		try await wordDeclination.save(on: app.db)
		let declinationId = try wordDeclination.requireID()

		let i = try await DeclinationTypeCase.query(on: app.db).filter(\.$name == "ich")
			.first()!
		let present = try await DeclinationTypeCase.query(on: app.db).filter(
			\.$name == "present"
		).first()!

		let response = try await requestWithAdmin(
			.POST, "words-management/edit-declination"
		) { req in
			let formData = WordsManagementController.EditDeclinationData(
				tabIndex: 0,
				declinationId: declinationId,
				declination: "kaufe",
				declinationTypeIds: [
					try i.requireID(),
					try present.requireID(),
				], wordId: try word.requireID())
			try req.content.encode(formData)
		}

		let newDec = try await WordDeclination.query(on: app.db).first()
		XCTAssertEqual(newDec?.text, "kaufe")
		XCTAssertContains(
			response.body.string,
			"<input type=\"hidden\" name=\"declinationId\" value=\"\(declinationId.uuidString)\">"
		)
		XCTAssertContains(
			response.body.string,
			"<input name=\"declination\" value=\"kaufe\" tabindex=\"0\">")
	}

	func testDeleteDeclination() async throws {
		let app = try getApp()
		let deutsch = try await getDeutsch()

		let word = Word(
			word: "kaufen", type: .verb, level: .A1, languageID: try deutsch.requireID()
		)
		try await word.save(on: app.db)

		let wordDeclination = WordDeclination(text: "kaufe", wordID: try word.requireID())
		try await wordDeclination.save(on: app.db)
		let declinationId = try wordDeclination.requireID()

		let i = try await DeclinationTypeCase.query(on: app.db).filter(\.$name == "ich")
			.first()!
		let present = try await DeclinationTypeCase.query(on: app.db).filter(
			\.$name == "present"
		).first()!

		let response = try await requestWithAdmin(
			.POST, "words-management/edit-declination"
		) { req in
			let formData = WordsManagementController.EditDeclinationData(
				tabIndex: 3,
				declinationId: declinationId,
				declination: "",
				declinationTypeIds: [
					try i.requireID(),
					try present.requireID(),
				], wordId: try word.requireID())
			try req.content.encode(formData)
		}

		let count = try await WordDeclination.query(on: app.db).filter(
			\.$id == declinationId
		).count()
		XCTAssertEqual(count, 0)
		XCTAssertContains(
			response.body.string,
			"<input name=\"declination\" value=\"\" tabindex=\"3\">")
	}
}
