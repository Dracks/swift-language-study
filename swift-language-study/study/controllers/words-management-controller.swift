import Fluent
import SQLKit
import SwiftHtml
import Vapor

struct WordsManagementController: RouteCollection {
	struct NewFormData: Content {
		var word: String
		var wordLevel: WordLevel?
		var wordType: WordType
		var languageId: UUID
		var rawWordId: UUID?
	}

	struct EditFormData: Content {
		var wordId: UUID
		var word: String
		var wordLevel: WordLevel?
		var wordType: WordType
		var rawWordId: UUID?
	}

	struct EditDeclinationData: Content {
        var tabIndex: Int
		var declinationId: UUID?
		var declination: String
		var declinationTypeIds: [UUID]
		var wordId: UUID
	}

	func boot(routes: RoutesBuilder) throws {
		let wordsRoutes = routes.grouped("words-management").grouped([
			UserIdentifiedMiddleware(), AdminMiddleware(),
		])
		wordsRoutes.get("list", use: listWords)
		wordsRoutes.get("new-word", use: newWord)
		wordsRoutes.post("new-word", use: newWordPost)
		wordsRoutes.get("edit-word", ":wordId", use: editWord)
		wordsRoutes.post("edit-word", use: editWordPost)
		wordsRoutes.post("edit-declination", use: editDeclination)
		wordsRoutes.get("get-form", use: newWordForm)
		wordsRoutes.grouped("select-raw-import").get(
			"random",
			":languageId", use: selectRawImportForm)
	}

	func listWords(req: Request) async throws -> Document {
		// let languages = try await Language.query(on: req.db).all()
		let languageID: UUID? = req.query["languageID"]
		let level: WordLevel? = req.query["level"].flatMap(WordLevel.init(rawValue:))
		let type: WordType? = req.query["type"].flatMap(WordType.init(rawValue:))

		var wordsQuery = Word.query(on: req.db).with(\.$language)

		if let languageID = languageID {
			wordsQuery = wordsQuery.filter(\.$language.$id == languageID)
		}

		if let level = level {
			wordsQuery = wordsQuery.filter(\.$level == level)
		}

		if let type = type {
			wordsQuery = wordsQuery.filter(\.$type == type)
		}

		let rawsList = try await wordsQuery.paginate(for: req)
		return WordsManagementTemplates(req: req).listWords(words: rawsList)
	}

	func newWord(req: Request) async throws -> Document {
		let languages = try await Language.query(on: req.db).all()
		return WordsManagementTemplates(req: req).createWordForm(languages: languages)
	}

	func newWordForm(req: Request) async throws -> Document {
		let languageIdStr: String = try req.query.get(at: "languageId")
		let templates = WordsManagementTemplates(req: req)
		guard let languageId = UUID(uuidString: languageIdStr) else {
			return templates.notFound()
		}
		guard
			let language = try await Language.query(on: req.db).filter(
				\.$id == languageId
			).first()
		else {
			return templates.notFound()
		}

		return templates.getWordForm(language: language)
	}

	func newWordPost(req: Request) async throws -> Document {
		let formData = try req.content.decode(NewFormData.self)
		let templates = WordsManagementTemplates(req: req)
		let newWord = Word(
			word: formData.word, type: formData.wordType, level: formData.wordLevel,
			rawID: formData.rawWordId, languageID: formData.languageId)

		try await newWord.save(on: req.db)

		try await newWord.$declinations.load(on: req.db)

		let wordTypeDeclinations = try await WordTypeDeclination.getInfo(
			on: req.db, forType: newWord.type, andLanguage: formData.languageId)

		let declinations = try wordTypeDeclinations.map { wordTypeDec in
			try wordTypeDec.requireID().declinationType
		}

		return templates.partialEditWord(word: newWord, withDeclinations: declinations)
	}

	func editWord(req: Request) async throws -> Document {
		let templates = WordsManagementTemplates(req: req)
		let wordId = try req.parameters.require("wordId", as: UUID.self)
		let word = try await Word.query(on: req.db)
			.filter(\.$id == wordId)
			.with(\.$declinations) { dec in
				dec.with(\.$declinationCase)
			}
			.with(\.$language).first()
		guard let word = word else {
			return templates.notFound()
		}

		let wordTypeDeclinations = try await WordTypeDeclination.getInfo(
			on: req.db, forType: word.type, andLanguage: word.$language.id)

		let declinations = try wordTypeDeclinations.map { wordTypeDec in
			try wordTypeDec.requireID().declinationType
		}

		return templates.editWordForm(word: word, withDeclinations: declinations)
	}

	func editWordPost(req: Request) async throws -> Document {
		let templates = WordsManagementTemplates(req: req)
		let formData = try req.content.decode(EditFormData.self)
		let word = try await Word.query(on: req.db)
			.filter(\.$id == formData.wordId)
			.with(\.$declinations) { dec in
				dec.with(\.$declinationCase)
			}
			.with(\.$language).first()

		guard let word = word else {
			return templates.notFound()
		}

		let wordTypeDeclinations = try await WordTypeDeclination.getInfo(
			on: req.db, forType: word.type, andLanguage: word.$language.id)

		let declinations = try wordTypeDeclinations.map { wordTypeDec in
			try wordTypeDec.requireID().declinationType
		}

		return templates.partialEditWord(word: word, withDeclinations: declinations)
	}
 
	func editDeclination(req: Request) async throws -> Document {
        do {
            let formData = try req.content.decode(EditDeclinationData.self)
            let templates = WordsManagementTemplates(req: req)
            
            // Todo validate the IDs
            let declinationTypeCases = try await DeclinationTypeCase.query(on: req.db).filter(
                \.$id ~~ formData.declinationTypeIds
            ).all()
            
            let word: Word? = try await Word.query(on: req.db).filter(\.$id == formData.wordId).first()
            guard let word = word else {
                return templates.notFound()
            }
            
            if let decId = formData.declinationId {
                let declination = try await WordDeclination.query(on: req.db).filter(
                    \.$id == decId
                ).first()
                guard let dec = declination else {
                    return templates.notFound()
                }
                
                if formData.declination.isEmpty {
                    try await dec.delete(on: req.db)
                } else {
                    dec.text = formData.declination
                    try await dec.save(on: req.db)
                }
                
            } else if !formData.declination.isEmpty {
                let dec = WordDeclination(
                    text: formData.declination, wordID: formData.wordId)
                try await dec.save(on: req.db)
                try await dec.$declinationCase.attach(declinationTypeCases, on: req.db)
            }
            
            try await word.$declinations.load(on: req.db)
            for dec in word.declinations {
                try await dec.$declinationCase.load(on: req.db)
            }
            
            return templates.partialEditDeclinationForm(word: word,
                                                        withDeclinations: declinationTypeCases, tabIndex: formData.tabIndex)
        } catch {
            print(error)
            throw error
        }
	}

	func selectRawImportForm(req: Request) async throws -> Document {
		let languageId = try req.parameters.require("languageId", as: UUID.self)
		guard
			let language = try await Language.query(on: req.db).filter(
				\.$id == languageId
			).first()
		else {
			return Templates(req: req).notFound()
		}
		let data = try await (req.db as! any SQLDatabase).select()
			.column(SQLColumn(SQLLiteral.all, table: SQLIdentifier(RawImport.schema)))
			.from(RawImport.schema)
			.join(
				Word.schema, method: SQLJoinMethod.left,
				on:
					SQLColumn("id", table: RawImport.schema), .equal,
				SQLColumn("raw_id", table: Word.schema)
			)
			.where(
				SQLColumn("language_id", table: RawImport.schema), .equal,
				SQLBind(languageId)
			)
			.where(SQLColumn("raw_id", table: Word.schema), .is, SQLLiteral.null)
			.orderBy(SQLFunction("random"))
			.limit(1)
			.first(decoding: RawImport.self)
		if let data = data {
			return WordsManagementTemplates(req: req).selectRawImportForm(
				word: data, forLanguage: language)
		}
		return WordsManagementTemplates(req: req).emptyRawImportForm(language: language)
	}
}
