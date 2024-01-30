import Fluent
import SwiftHtml
import Vapor

struct LanguageController: RouteCollection {
	var app: Application
	init(app: Application) {
		self.app = app
	}

	func boot(routes: RoutesBuilder) throws {
		let languagesRoute = routes.grouped("languages").grouped([
			UserIdentifiedMiddleware(), AdminMiddleware(),
		])
		languagesRoute.get(use: getAll)
		languagesRoute.post(use: create)
		languagesRoute.get(":id", use: getOne)
		languagesRoute.post(":id", use: update)
		languagesRoute.delete(":id", use: delete)
	}

	// Obté tots els idiomes
	func getAll(req: Request) async throws -> Document {
		let languages = try await Language.query(on: req.db).all()
		return Templates(req: req).listLanguages(languages: languages)
	}

	// Obté un idioma per ID
	func getOne(req: Request) async throws -> Response {
		let templates = Templates(req: req)
		let languageID = try req.parameters.require("id", as: UUID.self)
		let language = try await Language.query(on: req.db)
			.filter(\.$id == languageID)
			.first()

		if let language = language {
			return try await templates.editLanguage(language: language).encodeResponse(
				for: req)
		}
		return .init(status: .notFound, body: .init(string: templates.notFound().render()))
	}

	// Crea un nou idioma
	func create(req: Request) async throws -> Document {
		let language = try req.content.decode(Language.self)
		try await language.create(on: req.db)
		return try await self.getAll(req: req)
	}

	// Actualitza un idioma existent
	func update(req: Request) async throws -> Response {
		let languageID = try req.parameters.require("id", as: UUID.self)
		let updatedLanguage = try req.content.decode(Language.self)
		let language = try await Language.query(on: req.db)
			.filter(\.$id == languageID)
			.first()
		if let language = language {
			language.name = updatedLanguage.name
			try await language.save(on: req.db)
			return req.redirect(to: "/languages")
		}
		return notFoundResponse(req: req)
	}

	// Esborra un idioma
	func delete(req: Request) async throws -> Response {
		let languageID = try req.parameters.require("id", as: UUID.self)
		let language = try await Language.query(on: req.db)
			.filter(\.$id == languageID)
			.first()
		if let language = language {
			try await language.delete(on: req.db)
		}

		return req.redirect(to: "/languages")
	}
}
