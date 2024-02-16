import Fluent
import Vapor

// Enumeration for WordType
enum WordType: String, Codable {
	case article
	case noun
	case adjective
	case verb
	case pronoun
}

// Enumeration for WordLevel
enum WordLevel: String, Codable, CaseIterable {
	case A1
	case A2
	case B1
	case B2
	case C1
	case C2
	case D1
	case D2
}

// Language model
final class Language: Model {
	static let schema = "languages"

	@ID(key: .id)
	var id: UUID?

	@Field(key: "name")
	var name: String

	init() {}

	init(id: UUID? = nil, name: String) {
		self.id = id
		self.name = name
	}
}

// RawImport model
final class RawImport: Model {
	static let schema = "raw_imports"

	@ID(key: .id)
	var id: UUID?

	@Field(key: "word")
	var word: String

	@Enum(key: "level")
	var level: WordLevel

	@Parent(key: "language_id")
	var language: Language

	init() {}

	init(id: UUID? = nil, word: String, level: WordLevel, languageID: UUID) {
		self.id = id
		self.word = word
		self.level = level
		self.$language.id = languageID
	}
}

// Word model
final class Word: Model {
	static let schema = "words"

	@ID(key: .id)
	var id: UUID?

	@Field(key: "word")
	var word: String

	@Enum(key: "type")
	var type: WordType

	@OptionalEnum(key: "level")
	var level: WordLevel?

	@Parent(key: "language_id")
	var language: Language

	@OptionalParent(key: "raw_id")
	var raw: RawImport?

	@Children(for: \.$word)
	var declinations: [WordDeclination]

	init() {}

	init(
		id: UUID? = nil, word: String, type: WordType, level: WordLevel? = nil,
		rawID: UUID? = nil,
		languageID: UUID
	) {
		self.id = id
		self.word = word
		self.level = level
		self.type = type
		if let rawID = rawID {
			self.$raw.id = rawID
		}
		self.$language.id = languageID
	}

	func selectDeclination(match declinations: [DeclinationTypeCase]) -> WordDeclination? {

		let decIds = Set(declinations.map { $0.id })

		return self.declinations.filter { dec in
			let decCaseIds = Set(dec.declinationCase.map { $0.id })
			return decCaseIds.isSubset(of: decIds)
		}.first
	}
}

final class DeclinationType: Model {
	static let schema = "declination_types"

	@ID(key: .id)
	var id: UUID?

	// Todo: change the db name
	@Field(key: "name")
	var name: String

	@Parent(key: "language_id")
	var language: Language

	@Children(for: \.$type)
	var cases: [DeclinationTypeCase]

	@Field(key: "order")
	var order: Int

	init() {}

	init(id: UUID? = nil, name: String, order: Int, languageID: UUID) {
		self.id = id
		self.name = name
		self.order = order
		self.$language.id = languageID
	}
}

final class DeclinationTypeCase: Model {
	static let schema = "declination_type_cases"

	@ID(key: .id)
	var id: UUID?

	@Parent(key: "type_id")
	var type: DeclinationType

	@Field(key: "name")
	var name: String

	@Field(key: "order")
	var order: Int

	init() {}

	init(id: UUID? = nil, typeId: UUID, name: String, order: Int) {
		self.id = id
		self.$type.id = typeId
		self.name = name
		self.order = order
	}
}

final class WordTypeDeclination: Model {
	static let schema = "word_type_declination"

	final class IDValue: Fields, Hashable {
		@Enum(key: "type")
		var word: WordType

		@Parent(key: "language_id")
		var language: Language

		@Parent(key: "declination_type_id")
		var declinationType: DeclinationType

		init() {}

		init(word: WordType, declinationTypeId: UUID, forLanguage languageId: UUID) {
			self.word = word
			self.$declinationType.id = declinationTypeId
			self.$language.id = languageId
		}

		static func == (lhs: IDValue, rhs: IDValue) -> Bool {
			lhs.$declinationType.id == rhs.$declinationType.id && lhs.word == rhs.word
				&& lhs.$language.id == rhs.$language.id
		}
		func hash(into hasher: inout Hasher) {
			hasher.combine(self.$declinationType.id)
			hasher.combine(self.$language.id)
			hasher.combine(self.word)
		}
	}

	@CompositeID var id: IDValue?

	init() {}

	init(word: WordType, declinationTypeId: UUID, forLanguage languageId: UUID) {
		self.id = .init(
			word: word, declinationTypeId: declinationTypeId, forLanguage: languageId)
	}

	static func getInfo(
		on db: Database, forType wordType: WordType, andLanguage languageId: UUID
	) async throws -> [WordTypeDeclination] {
		let wordTypeDeclinations = try await WordTypeDeclination.query(on: db)
			.filter(\.$id.$word == wordType)
			.filter(\.$id.$language.$id == languageId)
			.with(\.$id.$declinationType) { decisionType in
				decisionType.with(\.$cases)
			}
			.all()
		return try wordTypeDeclinations.sorted { word1, word2 throws in
			let order1 = try word1.requireID().declinationType.order
			let order2 = try word2.requireID().declinationType.order
			return order1 < order2
		}
	}

}

final class WordDeclinationTypeCasePivot: Model {
	static let schema = "word_declination_type_case"

	@ID(key: .id)
	var id: UUID?

	@Parent(key: "word_declination_id")
	var wordDeclination: WordDeclination

	@Parent(key: "declination_type_case_id")
	var declinationTypeCase: DeclinationTypeCase

	init() {}

	init(wordDeclinationID: UUID, declinationTypeCaseID: UUID) {
		self.$wordDeclination.id = wordDeclinationID
		self.$declinationTypeCase.id = declinationTypeCaseID
	}
}

// WordDeclination model
final class WordDeclination: Model {
	static let schema = "word_declinations"

	@ID(key: .id)
	var id: UUID?

	@Field(key: "text")
	var text: String

	@Parent(key: "word_id")
	var word: Word

	@Siblings(
		through: WordDeclinationTypeCasePivot.self, from: \.$wordDeclination,
		to: \.$declinationTypeCase
	)
	var declinationCase: [DeclinationTypeCase]

	init() {}

	init(id: UUID? = nil, text: String, wordID: UUID) {
		self.id = id
		self.text = text
		self.$word.id = wordID
	}
}
