import Vapor

struct CreateUserCommand: Command {
    struct Signature: CommandSignature { 
        @Option(name: "username", short: "u")
        var user: String?

        @Option(name: "password", short: "p")
        var password: String?
    }

    var help: String {
        "Says hello"
    }

    func run(using context: CommandContext, signature: Signature) throws {
        let username = signature.user ?? "demo"
        let password = signature.password ?? "demo"
        context.console.print("\(signature)!")
        let user = User( email: username,  name: username)
        try user.setPassword(pwd: password)
        try user.save(on: context.application.db).wait()
    }
}