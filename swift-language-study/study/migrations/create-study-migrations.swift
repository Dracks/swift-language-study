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
		return database.schema("raw_imports")
			.id()
			.field("word", .string, .required)
			.field("level", .string, .required)
			.field("language_id", .uuid, .required, .references("languages", "id"))
			.create()
	}

	func revert(on database: Database) -> EventLoopFuture<Void> {
		return database.schema("raw_imports").delete()
	}
}

struct CreateWords: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		return database.schema("words")
			.id()
			.field("word", .string, .required)
			.field("type", .string, .required)
			.field("level", .string)
			.field("language_id", .uuid, .required, .references("languages", "id"))
			.field("raw_id", .uuid, .references("raw_imports", "id"))
			.create()
	}

	func revert(on database: Database) -> EventLoopFuture<Void> {
		return database.schema("words").delete()
	}
}

struct CreateDeclinationTypes: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		return database.schema("declination_types")
			.id()
			.field("language_id", .uuid, .required, .references("languages", "id"))
			.field("name", .string, .required)
			.field("order", .int, .required)
			.unique(on: "language_id", "name")
			.create()
	}

	func revert(on database: Database) -> EventLoopFuture<Void> {
		return database.schema("declination_types").delete()
	}
}

struct CreateDeclinationTypeCases: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		return database.schema("declination_type_cases")
			.id()
			.field("type_id", .uuid, .required)
			.field("name", .string, .required)
			.field("order", .int, .required)
			.create()
	}

	func revert(on database: Database) -> EventLoopFuture<Void> {
		return database.schema("declination_type_cases").delete()
	}
}

struct CreateWordDeclinationTypeCasePivot: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		return database.schema("word_declination_type_case")
			.id()
			.field(
				"word_declination_id", .uuid, .required,
				.references("word_declinations", "id", onDelete: .cascade)
			)
			.field(
				"declination_type_case_id", .uuid, .required,
				.references("declination_type_cases", "id", onDelete: .cascade)
			)
			.unique(on: "word_declination_id", "declination_type_case_id")
			.create()
	}

	func revert(on database: Database) -> EventLoopFuture<Void> {
		return database.schema("word_declination_type_case").delete()
	}
}

struct CreateWordDeclinations: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		return database.schema("word_declinations")
			.id()
			.field("text", .string, .required)
			.field("word_id", .uuid, .required, .references("words", "id"))
			.create()
	}

	func revert(on database: Database) -> EventLoopFuture<Void> {
		return database.schema("word_declinations").delete()
	}
}

struct CreateWordTypeDeclination: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		database.schema("word_type_declination")
			.field("type", .string, .required)
			.field(
				"declination_type_id", .uuid, .required,
				.references("declination_types", "id")
			)
			.field("language_id", .uuid, .required, .references("languages", "id"))
			.compositeIdentifier(over: "type", "language_id", "declination_type_id")
			.create()
	}

	func revert(on database: Database) -> EventLoopFuture<Void> {
		database.schema("word_type_declination").delete()
	}
}
