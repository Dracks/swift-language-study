//
//  File.swift
//
//
//  Created by Singla Valls, Jaume on 08.01.24.
//

import Vapor

func addBaseDeutsch(app: Application) async throws {
	let deutsch = Language(name: "Deutsch")
	try await deutsch.save(on: app.db)

	let gender = DeclinationType(name: "gender", order: 0, languageID: deutsch.id!)
	try await gender.save(on: app.db)
	let genderDer = DeclinationTypeCase(typeId: gender.id!, name: "der", order: 0)
	try await genderDer.save(on: app.db)
	let genderDieFem = DeclinationTypeCase(typeId: gender.id!, name: "die", order: 1)
	try await genderDieFem.save(on: app.db)
	let genderDas = DeclinationTypeCase(typeId: gender.id!, name: "das", order: 2)
	try await genderDas.save(on: app.db)
	let genderDiePlural = DeclinationTypeCase(typeId: gender.id!, name: "die", order: 3)
	try await genderDiePlural.save(on: app.db)

	let person = DeclinationType(name: "person", order: 1, languageID: deutsch.id!)
	try await person.save(on: app.db)
	let firstPersonSingular = DeclinationTypeCase(typeId: person.id!, name: "ich", order: 0)
	try await firstPersonSingular.save(on: app.db)
	let secondPersonSingular = DeclinationTypeCase(typeId: person.id!, name: "du", order: 1)
	try await secondPersonSingular.save(on: app.db)
	let thirdPersonSingular = DeclinationTypeCase(
		typeId: person.id!, name: "er/sie/es", order: 2)
	try await thirdPersonSingular.save(on: app.db)
	let firstPersonPlural = DeclinationTypeCase(typeId: person.id!, name: "wir", order: 3)
	try await firstPersonPlural.save(on: app.db)
	let secondPersonPlural = DeclinationTypeCase(typeId: person.id!, name: "ihr", order: 4)
	try await secondPersonPlural.save(on: app.db)
	let thirdPersonPlural = DeclinationTypeCase(typeId: person.id!, name: "sie/Sie", order: 5)
	try await thirdPersonPlural.save(on: app.db)

	let tense = DeclinationType(name: "tense", order: 2, languageID: deutsch.id!)
	try await tense.save(on: app.db)
	let presentTense = DeclinationTypeCase(typeId: tense.id!, name: "present", order: 0)
	try await presentTense.save(on: app.db)
	let perfectTense = DeclinationTypeCase(typeId: tense.id!, name: "perfect", order: 1)
	try await perfectTense.save(on: app.db)
	let preteritumTense = DeclinationTypeCase(typeId: tense.id!, name: "präteritum", order: 2)
	try await perfectTense.save(on: app.db)

	let adjectiveDeclination = DeclinationType(
		name: "adjective_declination", order: 3, languageID: deutsch.id!)
	try await adjectiveDeclination.save(on: app.db)
	let nominativeCase = DeclinationTypeCase(
		typeId: adjectiveDeclination.id!, name: "nominative", order: 0)
	try await nominativeCase.save(on: app.db)
	let accusativeCase = DeclinationTypeCase(
		typeId: adjectiveDeclination.id!, name: "accusative", order: 1)
	try await accusativeCase.save(on: app.db)
	let dativeCase = DeclinationTypeCase(
		typeId: adjectiveDeclination.id!, name: "dative", order: 2)
	try await dativeCase.save(on: app.db)
	let genitiveCase = DeclinationTypeCase(
		typeId: adjectiveDeclination.id!, name: "genitive", order: 3)
	try await genitiveCase.save(on: app.db)

	try await WordTypeDeclination(
		word: .verb, declinationTypeId: try person.requireID(),
		forLanguage: try deutsch.requireID()
	).save(
		on: app.db)
	try await WordTypeDeclination(
		word: .verb, declinationTypeId: try tense.requireID(),
		forLanguage: try deutsch.requireID()
	).save(
		on: app.db)
	try await WordTypeDeclination(
		word: .noun, declinationTypeId: try gender.requireID(),
		forLanguage: try deutsch.requireID()
	).save(
		on: app.db)
	try await WordTypeDeclination(
		word: .adjective, declinationTypeId: try gender.requireID(),
		forLanguage: try deutsch.requireID()
	)
	.save(on: app.db)
	try await WordTypeDeclination(
		word: .adjective, declinationTypeId: try adjectiveDeclination.requireID(),
		forLanguage: try deutsch.requireID()
	).save(on: app.db)
	try await WordTypeDeclination(
		word: .pronoun, declinationTypeId: try person.requireID(),
		forLanguage: try deutsch.requireID()
	)
	.save(on: app.db)
	try await WordTypeDeclination(
		word: .pronoun, declinationTypeId: try adjectiveDeclination.requireID(),
		forLanguage: try deutsch.requireID()
	).save(on: app.db)
	try await WordTypeDeclination(
		word: .article, declinationTypeId: try gender.requireID(),
		forLanguage: try deutsch.requireID()
	)
	.save(on: app.db)
	try await WordTypeDeclination(
		word: .article, declinationTypeId: try adjectiveDeclination.requireID(),
		forLanguage: try deutsch.requireID()
	).save(on: app.db)
}

struct FillBaseLanguageCommand: AsyncCommand {
	struct Signature: CommandSignature {
		@Option(name: "language", short: "l")
		var language: String?

	}

	var help: String {
		"Create the base structure needed for that language"
	}

	func run(using context: CommandContext, signature: Signature) async throws {
		context.console.print("\(signature)!")
		try await addBaseDeutsch(app: context.application)
	}
}
