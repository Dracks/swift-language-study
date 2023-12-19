import NIOSSL
import Fluent
import FluentSQLiteDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(DatabaseConfigurationFactory.sqlite(.file("db.sqlite")), as: .sqlite)

    // app.migrations.add(CreateTodo())
    app.migrations.add(SessionRecord.migration)
    app.migrations.add(CreateUser())
    app.migrations.add(CreateLanguages())
    app.migrations.add(CreateRawImports())
    app.migrations.add(CreateWords())
    app.migrations.add(CreateDeclinations())
    app.migrations.add(CreateWordDeclinations())

    app.views.use(.leaf)

    app.commands.use(CreateUserCommand(), as: "demo_user")

    

    // register routes
    try routes(app)
}

