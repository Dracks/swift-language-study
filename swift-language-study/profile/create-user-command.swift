import Vapor

struct CreateUserCommand: Command {
	struct Signature: CommandSignature {
		@Option(name: "username", short: "u")
		var user: String?

		@Option(name: "password", short: "p")
		var password: String?

		@Flag(name: "admin")
		var isAdmin: Bool
	}

	var help: String {
		"Creates a user in the database"
	}

	func run(using context: CommandContext, signature: Signature) throws {
		let username = signature.user ?? "demo"
		let password = signature.password ?? "demo"
		context.console.print("\(signature)!")
		let user = User(email: username, name: username, isAdmin: signature.isAdmin)
		try user.setPassword(pwd: password)
		try user.save(on: context.application.db).wait()
	}
}
