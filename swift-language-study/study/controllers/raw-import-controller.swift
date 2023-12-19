import Vapor
import Fluent

struct RawImportsController: RouteCollection {
    
    var app: Application
    init(app: Application) {
        self.app = app
    }
    
    func boot(routes: RoutesBuilder) throws {
        /*let rawImportsRoute = routes.grouped("rawImports")
        rawImportsRoute.get(use: renderForm)
        rawImportsRoute.post(use: create)
        rawImportsRoute.put(":id", use: update)*/
    }
    /*
    // Llista filtrada de paraules amb paginació (opcionalment per idioma i/o nivell)
    func listFiltered(req: Request) throws -> EventLoopFuture<View> {
        let languageID: UUID? = req.query["languageID"]
        let level: WordLevel? = req.query["level"].flatMap(WordLevel.init(rawValue:))
        
        var rawImportsQuery = RawImport.query(on: req.db)
        
        if let languageID = languageID {
            rawImportsQuery = rawImportsQuery.filter(\.$languageID == languageID)
        }
        
        if let level = level {
            rawImportsQuery = rawImportsQuery.filter(\.$level == level)
        }
        
        /*return rawImportsQuery.paginate(for: req).flatMap { paginatedRawImports in
            let context: [String: Any] = ["rawImports": paginatedRawImports]
            return try await app.view.render("filteredRawImports", context)
        }*/
    }
    
    // Renderitza el formulari per afegir RawImport
    func renderForm(req: Request) async throws -> View {
        let languages = try await Language.query(on: req.db).all()
        let context: [String: Any] = ["languages": languages]
        return try await app.view.render("rawImportForm", context)
    }
    
    // Crea un nou RawImport a partir d'un text de paraules separades per comes
    func create(req: Request) throws -> EventLoopFuture<View> {
        let data = try req.content.decode(RawImportCreationData.self)
        let words = data.word.components(separatedBy: ",")
        
        guard !words.isEmpty else {
            let context: [String: String] = ["error": "No s'han proporcionat paraules."]
            return req.view.render("rawImportForm", context)
        }
        
        guard let languageID = req.parameters.get("languageID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Falta l'idioma.")
        }
        
        // Afegeix cada paraula com a nou RawImport amb l'idioma seleccionat
        let saves = words.map { word in
            RawImport(word: word, level: .A1, languageID: languageID).create(on: req.db)
        }
        
        return saves.flatten(on: req.eventLoop).flatMapThrowing { _ async throws in
            let context: [String: String] = ["success": "Paraules afegides amb èxit!"]
            return try await app.view.render("rawImportForm", context)
        }
    }

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
    let word: String
    let languageID: String
}

struct RawImportUpdateData: Content {
    let word: String
    let languageID: String
}

