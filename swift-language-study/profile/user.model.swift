import Vapor
import Fluent

final class User: Model, Content {

    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    @Field(key: "name")
    var name: String?

    init() {}

    init(id: UUID? = nil, email: String="", passwordHash: String = "", name: String? = nil) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.name = name
    }

    func setPassword(pwd: String)throws{
        self.passwordHash = try Bcrypt.hash(pwd)
    }

    func verifyPassword(pwd: String) -> Bool{
        do {
            return try Bcrypt.verify(pwd, created: self.passwordHash)
        } catch {
            return false
        }
    }
}

extension User: SessionAuthenticatable {
    typealias SessionID = UUID
    var sessionID: SessionID {
        self.id!
    }
}

