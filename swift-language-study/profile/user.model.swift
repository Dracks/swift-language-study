import Fluent
import Vapor

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

	@Field(key: "is_admin")
	var isAdmin: Bool

	init() {}

	init(
		id: UUID? = nil, email: String = "", passwordHash: String = "", name: String? = nil,
		isAdmin: Bool = false
	) {
		self.id = id
		self.email = email
		self.passwordHash = passwordHash
		self.name = name
		self.isAdmin = isAdmin
	}

	func setPassword(pwd: String) throws {
		self.passwordHash = try Bcrypt.hash(pwd)
	}

	func verifyPassword(pwd: String) -> Bool {
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
