import Fluent

struct CreateLanguages: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("languages")
            .id()
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("languages").delete()
    }
}

struct CreateRawImports: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("rawImports")
            .id()
            .field("word", .string, .required)
            .field("level", .string, .required)
            .field("language_id", .uuid, .required, .references("languages", "id"))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("rawImports").delete()
    }
}

struct CreateWords: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("words")
            .id()
            .field("word", .string, .required)
            .field("level", .string, .required)
            .field("language_id", .uuid, .required, .references("languages", "id"))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("words").delete()
    }
}

struct CreateDeclinations: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("declinations")
            .id()
            .field("type", .string, .required)
            .field("person", .string, .required)
            .field("case", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("declinations").delete()
    }
}

struct CreateWordDeclinations: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("wordDeclinations")
            .id()
            .field("text", .string, .required)
            .field("word_id", .uuid, .required, .references("words", "id"))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("wordDeclinations").delete()
    }
}

