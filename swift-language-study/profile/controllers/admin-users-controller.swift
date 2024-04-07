import Fluent
import SwiftHtml
import Vapor

struct AdminUsersController: RouteCollection {
	struct UserSave: Content {
		var name: String
		var email: String
		var password: String
		var userType: String

	}
	var userService = UserService()

	func boot(routes: Vapor.RoutesBuilder) throws {
		let adminRoutes = routes.grouped("users").grouped(
			UserIdentifiedMiddleware(), AdminMiddleware())

		adminRoutes.get(use: listUsers)
		adminRoutes.get("new", use: newUser)
		adminRoutes.post("new", use: saveUser)
		adminRoutes.get("edit", ":userId", use: editUser)
		adminRoutes.post("edit", ":userId", use: saveUser)
	}

	func listUsers(req: Request) async throws -> Document {
		let usersQuery = User.query(on: req.db)

		let usersPage = try await usersQuery.paginate(for: req)
		return ProfileTemplates(req: req).listProfiles(usersPage)
	}

	func newUser(req: Request) async throws -> Document {
		return ProfileTemplates(req: req).editAdminProfile(user: nil)
	}

	func editUser(req: Request) async throws -> Document {
		let templates = ProfileTemplates(req: req)
		let userId = try req.parameters.require("userId", as: UUID.self)

		let user = try await User.query(on: req.db).filter(\.$id == userId).first()

		guard let user = user else {
			return templates.notFound()
		}

		let userView = UserView(fromUser: user)

		return templates.editAdminProfile(user: userView)
	}

	func saveUser(req: Request) async throws -> Response {
		let templates = ProfileTemplates(req: req)
		let userIdStr = req.parameters.get("userId")
		let data = try req.content.decode(UserSave.self)
		var errors: [String: String] = [:]
		var isNewUser = true
		let isAdmin = data.userType == "admin"
		var userId: UUID? = nil

		if let userIdStr = userIdStr {
			userId = UUID(uuidString: userIdStr)
			isNewUser = false
		}

		if !data.password.isEmpty || isNewUser {
			let pwdErrors = userService.checkPassword(data.password)
			if pwdErrors.count > 0 {
				let errorsString: String = pwdErrors.joined(separator: ", ")
				errors["password"] =
					"Password doesn't comply the following errors: \(errorsString)"
			}
		}

		if userService.checkEmail(data.email).count > 0 {}

		if errors.count > 0 {
			let userView = UserView(
				id: userId, email: data.email, password: data.password,
				name: data.name, isAdmin: data.userType == "admin")
			return try await templates.editAdminProfile(user: userView, errors: errors)
				.encodeResponse(for: req)
		}

		if let userId = userId {
			let user = try await User.query(on: req.db).filter(\.$id == userId).first()
			guard let user = user else {
				return try await templates.notFound().encodeResponse(for: req)
			}
			user.email = data.email
			user.name = data.name
			user.isAdmin = isAdmin
			if !data.password.isEmpty {
				try user.setPassword(pwd: data.password)
			}
			try await user.save(on: req.db)
			let userView = UserView(fromUser: user)
			return try await templates.editAdminProfile(user: userView, errors: errors)
				.encodeResponse(for: req)
		} else {
			let user = User(email: data.email, name: data.name, isAdmin: isAdmin)
			try user.setPassword(pwd: data.password)
			try await user.save(on: req.db)
			return req.redirect(to: "/users/edit/\(try user.requireID())")
		}

	}
}
