import Fluent
import SwiftHtml
import Vapor

struct RawImportsController: RouteCollection {

	var app: Application
	init(app: Application) {
		self.app = app
	}

	func boot(routes: RoutesBuilder) throws {
		let rawImportsRoute = routes.grouped("raw-imports").grouped([
			UserIdentifiedMiddleware(), AdminMiddleware(),
		])
		rawImportsRoute.get(use: listFiltered)

		rawImportsRoute.get("import", use: renderForm)
		rawImportsRoute.post("import", use: create)
		/*rawImportsRoute.put(":id", use: update)*/
	}

	// Llista filtrada de paraules amb paginació (opcionalment per idioma i/o nivell)
	func listFiltered(req: Request) async throws -> Document {
		let languageID: UUID? = req.query["languageID"]
		let level: WordLevel? = req.query["level"].flatMap(WordLevel.init(rawValue:))

		var rawImportsQuery = RawImport.query(on: req.db).with(\.$language)

		if let languageID = languageID {
			rawImportsQuery = rawImportsQuery.filter(\.$language.$id == languageID)
		}

		if let level = level {
			rawImportsQuery = rawImportsQuery.filter(\.$level == level)
		}

		let rawsList = try await rawImportsQuery.paginate(for: req)
		return RawImportTemplates(req: req).listRawWords(rawsList, filterLevel: level)
	}

	// Renderitza el formulari per afegir RawImport
	func renderForm(req: Request) async throws -> Document {
		let languages = try await Language.query(on: req.db).all()
		return RawImportTemplates(req: req).inputRawForm(languages: languages)
	}

	// Crea un nou RawImport a partir d'un text de paraules separades per comes
	func create(req: Request) async throws -> Document {
		let data = try req.content.decode(RawImportCreationData.self)
		let words = data.words.components(separatedBy: ",")
		let languages = try await Language.query(on: req.db).all()

		guard !words.isEmpty, let languageID = data.languageID else {
			var errors: [String] = []
			if words.isEmpty {
				errors.append("No words provided")
			}
			if data.languageID == nil {
				errors.append("Please select a language")
			}

			return RawImportTemplates(req: req).inputRawForm(
				languages: languages, language: data.languageID,
				level: data.wordLevel, words: data.words,
				errors: errors)

		}

		// Afegeix cada paraula com a nou RawImport amb l'idioma seleccionat
		let saves = words.map { word in
			RawImport(word: word, level: data.wordLevel, languageID: languageID).create(
				on: req.db)
		}
		let results = EventLoopFuture.whenAllSucceed(saves, on: req.eventLoop)
		print("\(results)")

		return RawImportTemplates(req: req).inputRawForm(
			languages: languages, language: languageID, level: data.wordLevel)
	}
	/*

    // Actualitza un RawImport existent
    func update(req: Request) throws -> EventLoopFuture<View> {
        let id = try req.parameters.require("id", as: UUID.self)
        let data = try req.content.decode(RawImportUpdateData.self)

        return RawImport.find(id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { rawImport in
                rawImport.word = data.word
                return rawImport.update(on: req.db).flatMapThrowing { _ in
                    let context: [String: String] = ["success": "RawImport actualitzat amb èxit!"]
                    return app.view.render("rawImportForm", context)
                }
            }
    }*/
}

// Estructures de dades per a les sol·licituds
struct RawImportCreationData: Content {
	let words: String
	let wordLevel: WordLevel
	let languageID: UUID?
}

struct RawImportUpdateData: Content {
	let word: String
	let wordLevel: WordLevel
	let languageID: String
}
