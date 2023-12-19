import Vapor
import Fluent
import SwiftHtml

struct LanguageController: RouteCollection {
    var app: Application
    init(app: Application) {
        self.app = app
    }
    
    func boot(routes: RoutesBuilder) throws {
        let languagesRoute = routes.grouped("languages")
        languagesRoute.get(use: getAll)
        languagesRoute.post(use: create)
        /*languagesRoute.get(":id", use: getOne)
        languagesRoute.put(":id", use: update)*/
        languagesRoute.delete(":id", use: delete)
    }

    // Obté tots els idiomes
    func getAll(req: Request) async throws -> Document {
        let languages = try await Language.query(on: req.db).all()
        return Templates.listLanguages(languages: languages)
    }

    // Obté un idioma per ID
    func getOne(req: Request) throws -> EventLoopFuture<Language> {
        let languageID = try req.parameters.require("id", as: UUID.self)
        return Language.find(languageID, on: req.db)
            .unwrap(or: Abort(.notFound))
    }

    // Crea un nou idioma
    func create(req: Request) throws -> EventLoopFuture<Language> {
        let language = try req.content.decode(Language.self)
        return language.create(on: req.db).map { language }
    }

    // Actualitza un idioma existent
    func update(req: Request) throws -> EventLoopFuture<Language> {
        let languageID = try req.parameters.require("id", as: UUID.self)
        let updatedLanguage = try req.content.decode(Language.self)
        return Language.find(languageID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { language in
                language.name = updatedLanguage.name
                return language.update(on: req.db).transform(to: language)
            }
    }

    // Esborra un idioma
    func delete(req: Request) async throws -> Response {
        let languageID = try  req.parameters.require("id", as: UUID.self)
        let language = try await Language.query(on: req.db)
            .filter(\.$id == languageID)
            .first()
        if let language = language {
           try await language.delete(on: req.db)
        }
        
        return req.redirect(to: "/languages")
    }
}
