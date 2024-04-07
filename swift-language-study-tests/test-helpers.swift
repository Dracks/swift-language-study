import Fluent
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
		try req.content.encode(["username": user, "password": password])
	}
	XCTAssertEqual(res.headers.contains(name: "set-cookie"), true)
	let cookiesList: [String] = res.headers["set-cookie"]
	let cookie: String = cookiesList[0]
	XCTAssertContains(cookie, "vapor-session=")

	return cookie
}

private func genericWordSampleCreation(
	languageId: UUID, word: String, rawWord: UUID? = nil, level: WordLevel? = nil,
	type: WordType, declinations: [String: [String]], on db: Database
) async throws {

	let word = Word(
		word: word, type: type, level: level, rawID: rawWord, languageID: languageId)
	try await word.save(on: db)
	for (declinatedWord, decNames) in declinations {
		let declinationTypeCases = try await DeclinationTypeCase.query(on: db).filter(
			\.$name ~~ decNames
		).all()
		let dec = WordDeclination(text: declinatedWord, wordID: try word.requireID())
		try await dec.save(on: db)
		try await dec.$declinationCase.attach(declinationTypeCases, on: db)
	}
}

func createSampleWords(app: Application, language: UUID) async throws {

	let rawHause = RawImport(word: "das Haus", level: .A1, languageID: language)

	try await genericWordSampleCreation(
		languageId: language, word: "Haus", rawWord: rawHause.id, level: .A1, type: .noun,
		declinations: [
			"Haus": ["das"]
		], on: app.db)

	try await genericWordSampleCreation(
		languageId: language, word: "sein", level: .A1, type: .verb,
		declinations: [
			"bin": ["ich", "present"],
			"bist": ["du", "present"],
			"ist": ["er/sie/es", "present"],
		], on: app.db)

	try await genericWordSampleCreation(
		languageId: language, word: "Schwäche", level: .B1, type: .noun, declinations: [:],
		on: app.db)

}
