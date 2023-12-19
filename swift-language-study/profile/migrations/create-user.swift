import Fluent

struct CreateUser: AsyncMigration {

    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("email", .string, .required)
            .field("password_hash", .string, .required)
            .field("name", .string)
            .create()
    }

    func revert(on database: FluentKit.Database) async throws {
        try await database.schema("users").delete()
    }
}

