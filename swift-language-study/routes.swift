import Fluent
import Vapor

func routes(_ app: Application) throws {

    try app.register(collection: ProfileController(app: app))
    try app.register(collection: LanguageController(app: app))
    try app.register(collection: RawImportsController(app: app))
}

