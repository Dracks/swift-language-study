import Fluent
import FluentSQLiteDriver
import FluentPostgresDriver
import NIOSSL
import Vapor

func configureDb(_ app: Application) async throws {
	switch Environment.get("DB_TYPE") {
	case "POSTGRES":
        let dbUrl = Environment.get("DB_URL")
        guard let dbUrl = dbUrl else {
            throw GenericError(msg: "DB_URL must be defined for DB_TYPE postgress")
        }
        app.databases.use(try DatabaseConfigurationFactory.postgres(url: dbUrl), as: .psql)
	default:
		let dbName = Environment.get("DB_NAME") ?? "db.sqlite"
		if dbName != "memory" {
			app.databases.use(
				DatabaseConfigurationFactory.sqlite(.file(dbName)), as: .sqlite)
		} else {
			app.databases.use(DatabaseConfigurationFactory.sqlite(.memory), as: .sqlite)
		}
	}
}

// configures your application
public func configure(_ app: Application) async throws {
	// uncomment to serve files from /Public folder
	app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

	try await configureDb(app)

	app.migrations.add(SessionRecord.migration)
	app.migrations.add(CreateUser())
	app.migrations.add(CreateLanguages())
	app.migrations.add(CreateRawImports())
	app.migrations.add(CreateWords())
	app.migrations.add(CreateDeclinationTypes())
	app.migrations.add(CreateDeclinationTypeCases())
	app.migrations.add(CreateWordDeclinations())
	app.migrations.add(CreateWordDeclinationTypeCasePivot())
	app.migrations.add(CreateWordTypeDeclination())

	if app.environment == .testing {
		try await app.autoMigrate()
	}

	app.sessions.use(.fluent)

	app.commands.use(CreateUserCommand(), as: "demo_user")
	app.asyncCommands.use(FillBaseLanguageCommand(), as: "fill_base_language")

	// register routes
	try routes(app)
}
